import io
import csv
import logging
import os
import uuid
from contextlib import asynccontextmanager
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path
from typing import Annotated, Literal

import bcrypt
import cloudinary
import cloudinary.uploader
import jwt
from fastapi import Depends, FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.staticfiles import StaticFiles
from fastapi.responses import Response
from PIL import Image, ImageOps, UnidentifiedImageError
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from sqlalchemy import func, or_, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .database import Base, Notification, Report, ReportStatusHistory, SessionLocal, User, engine, get_db, utc_now

STATUSES = ("Pending", "In Progress", "Completed", "Rejected")
CATEGORIES = ("Organic Waste", "Plastic Waste", "Paper Waste")
JWT_SECRET = os.getenv("JWT_SECRET", "development-only-change-this-secret")
JWT_ALGORITHM = "HS256"
MAX_IMAGE_BYTES = 8 * 1024 * 1024
UPLOAD_DIR = Path(__file__).resolve().parent.parent / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)
bearer = HTTPBearer(auto_error=False)
logger = logging.getLogger(__name__)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password: str, password_hash: str) -> bool:
    if len(password.encode("utf-8")) > 72:
        return False
    return bcrypt.checkpw(password.encode(), password_hash.encode())


def token_for(user: User) -> str:
    payload = {"sub": str(user.id), "exp": datetime.now(timezone.utc) + timedelta(hours=24)}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Authentication required")
    try:
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = int(payload["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired token") from None
    user = db.get(User, user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Account unavailable")
    return user


def admin_user(user: Annotated[User, Depends(current_user)]) -> User:
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return user


class RegisterIn(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=72)

    @field_validator("password")
    @classmethod
    def password_bytes(cls, value: str) -> str:
        if len(value.encode("utf-8")) > 72:
            raise ValueError("Password must be at most 72 UTF-8 bytes")
        return value

    @field_validator("name")
    @classmethod
    def nonblank_name(cls, value: str) -> str:
        value = value.strip()
        if len(value) < 2:
            raise ValueError("Name must contain at least 2 characters")
        return value


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(max_length=72)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    email: EmailStr
    role: str
    is_active: bool


class AuthOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class UserCreate(RegisterIn):
    role: Literal["user", "admin"] = "user"


class UserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    role: Literal["user", "admin"] | None = None
    is_active: bool | None = None

    @field_validator("name")
    @classmethod
    def nonblank_name(cls, value: str | None) -> str | None:
        return RegisterIn.nonblank_name(value) if value is not None else None


class ProfileUpdate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    current_password: str | None = Field(default=None, max_length=72)
    new_password: str | None = Field(default=None, min_length=8, max_length=72)

    @field_validator('name')
    @classmethod
    def valid_name(cls, value: str) -> str:
        return RegisterIn.nonblank_name(value)

    @field_validator('new_password')
    @classmethod
    def valid_password(cls, value: str | None) -> str | None:
        return RegisterIn.password_bytes(value) if value is not None else None


class ReportOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    owner_name: str
    description: str
    latitude: float
    longitude: float
    image_url: str
    completion_image_url: str | None
    status: str
    ai_category: str | None
    ai_confidence: float | None
    corrected_category: str | None
    category_note: str | None
    category_reviewer_id: int | None
    category_reviewed_at: datetime | None
    created_at: datetime
    updated_at: datetime


class ReportList(BaseModel):
    items: list[ReportOut]
    total: int
    page: int
    page_size: int


class ReportUpdate(BaseModel):
    description: str | None = Field(default=None, min_length=10, max_length=2000)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)

    @field_validator("description")
    @classmethod
    def nonblank_description(cls, value: str | None) -> str | None:
        if value is not None:
            value = value.strip()
            if len(value) < 10:
                raise ValueError("Description must contain at least 10 characters")
        return value


class StatusUpdate(BaseModel):
    status: Literal["Pending", "In Progress", "Completed", "Rejected"]
    expected_status: Literal["Pending", "In Progress", "Completed", "Rejected"]
    note: str = Field(min_length=3, max_length=1000)
    is_correction: bool = False

    @field_validator("note")
    @classmethod
    def nonblank_note(cls, value: str) -> str:
        value = value.strip()
        if len(value) < 3:
            raise ValueError("Catatan minimal 3 karakter")
        return value


class StatusHistoryOut(BaseModel):
    id: int
    old_status: str
    new_status: str
    note: str | None
    is_correction: bool
    changed_at: datetime
    admin_name: str


class NotificationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    report_id: int
    message: str
    is_read: bool
    created_at: datetime


class PredictionOut(BaseModel):
    category: str
    confidence: float


class CategoryReview(BaseModel):
    category: Literal["Organic Waste", "Plastic Waste", "Paper Waste"]
    note: str = Field(min_length=3, max_length=1000)

    @field_validator("note")
    @classmethod
    def trim_note(cls, value: str) -> str:
        value = value.strip()
        if len(value) < 3:
            raise ValueError("Catatan minimal 3 karakter")
        return value


def read_image(data: bytes) -> None:
    if not data or len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=422, detail="Image must be 1 byte to 8 MB")
    try:
        with Image.open(io.BytesIO(data)) as image:
            if image.width * image.height > 20_000_000:
                raise ValueError("Image dimensions exceed the supported limit")
            image.verify()
        with Image.open(io.BytesIO(data)) as image:
            if image.format not in {"JPEG", "PNG", "WEBP"}:
                raise ValueError("Unsupported image format")
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError):
        raise HTTPException(status_code=422, detail="Use a valid JPEG, PNG, or WEBP image") from None


async def image_bytes(file: UploadFile) -> bytes:
    data = await file.read(MAX_IMAGE_BYTES + 1)
    read_image(data)
    return data


def store_image(data: bytes) -> tuple[str, str | None]:
    normalized = io.BytesIO()
    with Image.open(io.BytesIO(data)) as image:
        ImageOps.exif_transpose(image).convert("RGB").save(normalized, format="JPEG", quality=85)
    encoded = normalized.getvalue()
    if os.getenv("CLOUDINARY_URL"):
        cloudinary.config(secure=True)
        try:
            uploaded = cloudinary.uploader.upload(encoded, folder="campah")
            return uploaded["secure_url"], uploaded["public_id"]
        except Exception as exc:
            raise HTTPException(status_code=502, detail="Image storage unavailable") from exc
    filename = f"{uuid.uuid4().hex}.jpg"
    (UPLOAD_DIR / filename).write_bytes(encoded)
    return f"/uploads/{filename}", None


def predict_image(data: bytes) -> PredictionOut:
    from .predictor import predict

    result = predict(data)
    if result is None:
        raise HTTPException(status_code=503, detail="ML model is not available")
    return PredictionOut(category=result[0], confidence=result[1])


def visible_report(db: Session, report_id: int, user: User) -> Report:
    report = db.get(Report, report_id)
    if not report or report.deleted_at or (user.role != "admin" and report.user_id != user.id):
        raise HTTPException(status_code=404, detail="Report not found")
    return report


def save_user(db: Session, user: User) -> User:
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Email already registered") from None
    db.refresh(user)
    return user


@asynccontextmanager
async def lifespan(app: FastAPI):
    if os.getenv("APP_ENV") == "production":
        if len(JWT_SECRET) < 32 or JWT_SECRET == "development-only-change-this-secret":
            raise RuntimeError("Set a strong JWT_SECRET for production")
        if not os.getenv("CLOUDINARY_URL") or not os.getenv("DATABASE_URL"):
            raise RuntimeError("Production requires DATABASE_URL and CLOUDINARY_URL")
    else:
        Base.metadata.create_all(bind=engine)
    email = os.getenv("ADMIN_EMAIL", "").strip().lower()
    password = os.getenv("ADMIN_PASSWORD", "")
    if email and password:
        with SessionLocal() as db:
            if not db.scalar(select(User).where(User.email == email)):
                db.add(User(name="Administrator", email=email, password_hash=hash_password(password), role="admin"))
                db.commit()
    yield


app = FastAPI(title="CamPah API", version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")],
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/auth/register", response_model=AuthOut, status_code=201)
def register(payload: RegisterIn, db: Annotated[Session, Depends(get_db)]):
    email = payload.email.lower()
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(status_code=409, detail="Email already registered")
    user = User(name=payload.name.strip(), email=email, password_hash=hash_password(payload.password), role="user")
    save_user(db, user)
    return AuthOut(access_token=token_for(user), user=UserOut.model_validate(user))


@app.post("/auth/login", response_model=AuthOut)
def login(payload: LoginIn, db: Annotated[Session, Depends(get_db)]):
    user = db.scalar(select(User).where(User.email == payload.email.lower()))
    if not user or not user.is_active or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return AuthOut(access_token=token_for(user), user=UserOut.model_validate(user))


@app.get("/auth/me", response_model=UserOut)
def me(user: Annotated[User, Depends(current_user)]):
    return user


@app.patch("/auth/me", response_model=UserOut)
def update_profile(payload: ProfileUpdate, db: Annotated[Session, Depends(get_db)], user: Annotated[User, Depends(current_user)]):
    if payload.new_password is not None:
        if not payload.current_password or not verify_password(payload.current_password, user.password_hash):
            raise HTTPException(status_code=422, detail="Kata sandi saat ini tidak sesuai.")
        user.password_hash = hash_password(payload.new_password)
    user.name = payload.name
    db.commit()
    db.refresh(user)
    return user


@app.get("/reports", response_model=ReportList)
def list_reports(
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(current_user)],
    q: str = "",
    report_status: str | None = Query(default=None, alias="status"),
    category: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=100),
):
    if report_status and report_status not in STATUSES:
        raise HTTPException(status_code=422, detail="Invalid report status")
    if category and category not in CATEGORIES:
        raise HTTPException(status_code=422, detail="Invalid category")
    if date_from and date_to and date_from > date_to:
        raise HTTPException(status_code=422, detail="Invalid date range")
    conditions = [Report.deleted_at.is_(None)]
    if user.role != "admin":
        conditions.append(Report.user_id == user.id)
    if report_status:
        conditions.append(Report.status == report_status)
    if category:
        conditions.append(func.coalesce(Report.corrected_category, Report.ai_category) == category)
    if date_from:
        conditions.append(Report.created_at >= datetime.combine(date_from, time.min, tzinfo=timezone.utc))
    if date_to:
        conditions.append(Report.created_at <= datetime.combine(date_to, time.max, tzinfo=timezone.utc))
    if q.strip():
        conditions.append(or_(Report.description.ilike(f"%{q.strip()}%"), Report.ai_category.ilike(f"%{q.strip()}%")))
    total = db.scalar(select(func.count(Report.id)).where(*conditions)) or 0
    items = db.scalars(
        select(Report).where(*conditions).order_by(Report.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    ).all()
    return ReportList(items=items, total=total, page=page, page_size=page_size)


@app.get('/reports-export')
def export_reports(db: Annotated[Session, Depends(get_db)], admin: Annotated[User, Depends(admin_user)],
                   status: str | None = None, category: str | None = None, q: str = '',
                   date_from: date | None = None, date_to: date | None = None):
    if status and status not in STATUSES or category and category not in CATEGORIES or date_from and date_to and date_from > date_to:
        raise HTTPException(status_code=422, detail='Filter tidak valid')
    conditions = [Report.deleted_at.is_(None)]
    if status: conditions.append(Report.status == status)
    if category: conditions.append(func.coalesce(Report.corrected_category, Report.ai_category) == category)
    if date_from: conditions.append(Report.created_at >= datetime.combine(date_from, time.min, tzinfo=timezone.utc))
    if date_to: conditions.append(Report.created_at <= datetime.combine(date_to, time.max, tzinfo=timezone.utc))
    if q.strip(): conditions.append(or_(Report.description.ilike(f"%{q.strip()}%"), Report.ai_category.ilike(f"%{q.strip()}%")))
    reports = db.scalars(select(Report).where(*conditions).order_by(Report.created_at.desc()).limit(10000)).all()
    output = io.StringIO(newline='')
    writer = csv.writer(output)
    writer.writerow(['id', 'pelapor', 'deskripsi', 'latitude', 'longitude', 'status', 'kategori_ai', 'kategori_tinjauan', 'dibuat'])
    def safe(value):
        value = str(value or '')
        return "'" + value if value.lstrip().startswith(('=', '+', '-', '@', '\t', '\r')) else value
    for report in reports:
        writer.writerow([report.id, safe(report.owner_name), safe(report.description), report.latitude, report.longitude, report.status, report.ai_category or '', report.corrected_category or '', report.created_at.isoformat()])
    return Response(content='\ufeff' + output.getvalue(), media_type='text/csv; charset=utf-8', headers={'Content-Disposition': 'attachment; filename="campah-laporan.csv"'})


@app.post("/reports", response_model=ReportOut, status_code=201)
async def create_report(
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(current_user)],
    description: str = Form(min_length=10, max_length=2000),
    latitude: float = Form(ge=-90, le=90),
    longitude: float = Form(ge=-180, le=180),
    image: UploadFile = File(),
):
    description = description.strip()
    if len(description) < 10:
        raise HTTPException(status_code=422, detail="Description must contain at least 10 characters")
    data = await image_bytes(image)
    image_url, public_id = await run_in_threadpool(store_image, data)
    report = Report(user_id=user.id, description=description, latitude=latitude, longitude=longitude,
                    image_url=image_url, image_public_id=public_id, status="Pending")
    db.add(report)
    db.commit()
    db.refresh(report)
    try:
        prediction = await run_in_threadpool(predict_image, data)
        report.ai_category = prediction.category
        report.ai_confidence = prediction.confidence
        db.commit()
        db.refresh(report)
    except Exception:
        # Inference is optional for report creation. The report remains available.
        db.rollback()
        logger.warning("Prediction unavailable for report %s", report.id, exc_info=True)
    return report


@app.get("/reports/{report_id}", response_model=ReportOut)
def get_report(report_id: int, db: Annotated[Session, Depends(get_db)], user: Annotated[User, Depends(current_user)]):
    return visible_report(db, report_id, user)


@app.patch("/reports/{report_id}", response_model=ReportOut)
def update_report(report_id: int, payload: ReportUpdate, db: Annotated[Session, Depends(get_db)],
                  user: Annotated[User, Depends(current_user)]):
    report = visible_report(db, report_id, user)
    if user.role != "admin" and report.status != "Pending":
        raise HTTPException(status_code=403, detail="Only pending reports can be edited")
    changes = payload.model_dump(exclude_unset=True, exclude_none=True)
    for key, value in changes.items():
        setattr(report, key, value)
    db.commit()
    db.refresh(report)
    return report


@app.delete("/reports/{report_id}", status_code=204)
def delete_report(report_id: int, db: Annotated[Session, Depends(get_db)], user: Annotated[User, Depends(current_user)]):
    report = visible_report(db, report_id, user)
    if user.role != "admin" and report.status != "Pending":
        raise HTTPException(status_code=403, detail="Only pending reports can be deleted")
    report.deleted_at = utc_now()
    db.commit()


@app.patch("/reports/{report_id}/status", response_model=ReportOut)
def change_status(report_id: int, payload: StatusUpdate, db: Annotated[Session, Depends(get_db)],
                  admin: Annotated[User, Depends(admin_user)]):
    report = visible_report(db, report_id, admin)
    if report.status != payload.expected_status:
        raise HTTPException(status_code=409, detail="Status laporan telah berubah. Muat ulang laporan.")
    if report.status == payload.status:
        raise HTTPException(status_code=409, detail="Status laporan tidak berubah.")
    allowed = {"Pending": {"In Progress", "Rejected"}, "In Progress": {"Completed", "Rejected"}}
    if not payload.is_correction and payload.status not in allowed.get(report.status, set()):
        raise HTTPException(status_code=422, detail="Gunakan tindakan koreksi untuk perubahan status ini.")
    old_status = report.status
    result = db.execute(update(Report).where(Report.id == report.id, Report.status == old_status,
                                             Report.deleted_at.is_(None)).values(status=payload.status, updated_at=utc_now()))
    if result.rowcount != 1:
        db.rollback()
        raise HTTPException(status_code=409, detail="Status laporan telah berubah. Muat ulang laporan.")
    db.add(ReportStatusHistory(report_id=report.id, admin_id=admin.id, old_status=old_status,
                               new_status=payload.status, note=payload.note, is_correction=payload.is_correction))
    db.add(Notification(user_id=report.user_id, report_id=report.id,
                        message=f"Laporan #{report.id}: {old_status} → {payload.status}. {payload.note}"))
    db.commit()
    db.refresh(report)
    return report


@app.get("/reports/{report_id}/history", response_model=list[StatusHistoryOut])
def report_history(report_id: int, db: Annotated[Session, Depends(get_db)], user: Annotated[User, Depends(current_user)]):
    visible_report(db, report_id, user)
    rows = db.execute(select(ReportStatusHistory, User.name).join(User, User.id == ReportStatusHistory.admin_id)
                      .where(ReportStatusHistory.report_id == report_id)
                      .order_by(ReportStatusHistory.changed_at, ReportStatusHistory.id)).all()
    return [StatusHistoryOut(id=item.id, old_status=item.old_status, new_status=item.new_status,
                             note=item.note, is_correction=item.is_correction,
                             changed_at=item.changed_at if item.changed_at.tzinfo else item.changed_at.replace(tzinfo=timezone.utc),
                             admin_name=name) for item, name in rows]


@app.post("/reports/{report_id}/completion-photo", response_model=ReportOut)
async def completion_photo(report_id: int, db: Annotated[Session, Depends(get_db)],
                           admin: Annotated[User, Depends(admin_user)], image: UploadFile = File()):
    report = visible_report(db, report_id, admin)
    if report.status != "Completed":
        raise HTTPException(status_code=422, detail="Bukti hanya dapat ditambahkan pada laporan yang selesai.")
    if report.completion_image_url:
        raise HTTPException(status_code=409, detail="Bukti penyelesaian sudah ada.")
    data = await image_bytes(image)
    url, _ = await run_in_threadpool(store_image, data)
    result = db.execute(update(Report).where(Report.id == report_id, Report.status == "Completed",
                                             Report.completion_image_url.is_(None), Report.deleted_at.is_(None))
                        .values(completion_image_url=url, updated_at=utc_now()))
    if result.rowcount != 1:
        db.rollback()
        raise HTTPException(status_code=409, detail="Laporan telah berubah. Muat ulang.")
    db.add(Notification(user_id=report.user_id, report_id=report.id, message=f"Bukti penyelesaian laporan #{report.id} telah ditambahkan."))
    db.commit()
    db.refresh(report)
    return report


@app.patch("/reports/{report_id}/category-review", response_model=ReportOut)
def review_category(report_id: int, payload: CategoryReview, db: Annotated[Session, Depends(get_db)],
                    admin: Annotated[User, Depends(admin_user)]):
    report = visible_report(db, report_id, admin)
    report.corrected_category = payload.category
    report.category_note = payload.note
    report.category_reviewer_id = admin.id
    report.category_reviewed_at = utc_now()
    db.commit()
    db.refresh(report)
    return report


@app.get("/notifications", response_model=list[NotificationOut])
def list_notifications(db: Annotated[Session, Depends(get_db)], user: Annotated[User, Depends(current_user)]):
    return db.scalars(select(Notification).join(Report, Report.id == Notification.report_id)
                      .where(Notification.user_id == user.id, Report.deleted_at.is_(None))
                      .order_by(Notification.created_at.desc(), Notification.id.desc()).limit(100)).all()


@app.patch("/notifications/{notification_id}/read", response_model=NotificationOut)
def read_notification(notification_id: int, db: Annotated[Session, Depends(get_db)], user: Annotated[User, Depends(current_user)]):
    item = db.get(Notification, notification_id)
    if not item or item.user_id != user.id:
        raise HTTPException(status_code=404, detail="Notification not found")
    item.is_read = True
    db.commit()
    db.refresh(item)
    return item


@app.get("/dashboard")
def dashboard(db: Annotated[Session, Depends(get_db)], user: Annotated[User, Depends(current_user)]):
    conditions = [Report.deleted_at.is_(None)]
    if user.role != "admin":
        conditions.append(Report.user_id == user.id)
    status_rows = db.execute(select(Report.status, func.count(Report.id)).where(*conditions).group_by(Report.status)).all()
    category_rows = db.execute(select(Report.ai_category, func.count(Report.id)).where(*conditions, Report.ai_category.is_not(None)).group_by(Report.ai_category)).all()
    by_status = {name: 0 for name in STATUSES}
    by_status.update(dict(status_rows))
    by_category = {name: 0 for name in CATEGORIES}
    by_category.update(dict(category_rows))
    result = {"total": sum(by_status.values()), "by_status": by_status, "by_category": by_category}
    if user.role == 'admin':
        result['attention'] = {
            'pending': by_status['Pending'],
            'overdue_in_progress': db.scalar(select(func.count(Report.id)).where(Report.deleted_at.is_(None), Report.status == 'In Progress', Report.updated_at < utc_now() - timedelta(days=3))) or 0,
        }
    return result


@app.get("/users", response_model=list[UserOut])
def list_users(db: Annotated[Session, Depends(get_db)], admin: Annotated[User, Depends(admin_user)]):
    return db.scalars(select(User).order_by(User.created_at.desc())).all()


@app.post("/users", response_model=UserOut, status_code=201)
def create_user(payload: UserCreate, db: Annotated[Session, Depends(get_db)], admin: Annotated[User, Depends(admin_user)]):
    email = payload.email.lower()
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(status_code=409, detail="Email already registered")
    user = User(name=payload.name.strip(), email=email, password_hash=hash_password(payload.password), role=payload.role)
    return save_user(db, user)


@app.patch("/users/{user_id}", response_model=UserOut)
def update_user(user_id: int, payload: UserUpdate, db: Annotated[Session, Depends(get_db)],
                admin: Annotated[User, Depends(admin_user)]):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    changes = payload.model_dump(exclude_unset=True, exclude_none=True)
    if admin.id == user.id and (changes.get("is_active") is False or changes.get("role") == "user"):
        raise HTTPException(status_code=422, detail="Cannot remove your own admin access")
    for key, value in changes.items():
        setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user


@app.post("/predict", response_model=PredictionOut)
async def predict_endpoint(image: Annotated[UploadFile, File()], user: Annotated[User, Depends(current_user)]):
    return await run_in_threadpool(predict_image, await image_bytes(image))

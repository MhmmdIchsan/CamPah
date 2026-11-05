import os
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, create_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, sessionmaker


def utc_now():
    return datetime.now(timezone.utc)


DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./smart_waste.db")
if DATABASE_URL.startswith(("postgres://", "postgresql://")):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+psycopg://", 1).replace("postgresql://", "postgresql+psycopg://", 1)
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
    pool_pre_ping=True,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(10), default="user")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    reports: Mapped[list["Report"]] = relationship(back_populates="owner", foreign_keys="Report.user_id")


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    description: Mapped[str] = mapped_column(Text)
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)
    image_url: Mapped[str] = mapped_column(Text)
    image_public_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    completion_image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="Pending", index=True)
    ai_category: Mapped[str | None] = mapped_column(String(32), nullable=True)
    ai_confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
    corrected_category: Mapped[str | None] = mapped_column(String(32), nullable=True)
    category_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    category_reviewer_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    category_reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    assigned_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    assigned_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    owner: Mapped[User] = relationship(back_populates="reports", foreign_keys=[user_id])

    @property
    def owner_name(self) -> str:
        return self.owner.name


class ReportStatusHistory(Base):
    __tablename__ = "report_status_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    report_id: Mapped[int] = mapped_column(ForeignKey("reports.id"), index=True)
    admin_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    old_status: Mapped[str] = mapped_column(String(20))
    new_status: Mapped[str] = mapped_column(String(20))
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_correction: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    changed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    report_id: Mapped[int] = mapped_column(ForeignKey("reports.id"))
    message: Mapped[str] = mapped_column(Text)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


def get_db():
    with SessionLocal() as db:
        yield db

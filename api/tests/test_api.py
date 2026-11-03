import io
import os
import sys
from pathlib import Path

os.environ["DATABASE_URL"] = "sqlite://"
os.environ["JWT_SECRET"] = "test-secret-that-is-not-used-in-production"
os.environ.pop("ADMIN_EMAIL", None)
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pytest
from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import main
from app.database import Base, ReportStatusHistory, User, get_db

REAL_PREDICT_IMAGE = main.predict_image


@pytest.fixture
def system(monkeypatch, tmp_path):
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    sessions = sessionmaker(bind=engine, expire_on_commit=False)
    Base.metadata.create_all(engine)
    monkeypatch.setattr(main, "engine", engine)
    monkeypatch.setattr(main, "SessionLocal", sessions)
    monkeypatch.setattr(main, "UPLOAD_DIR", tmp_path)
    monkeypatch.delenv("CLOUDINARY_URL", raising=False)
    monkeypatch.setattr(main, "predict_image", lambda _: main.PredictionOut(category="Plastic Waste", confidence=0.91))
    def database():
        with sessions() as db:
            yield db
    main.app.dependency_overrides[get_db] = database
    with TestClient(main.app) as client:
        yield client, sessions
    main.app.dependency_overrides.clear()
    engine.dispose()


def signup(client, email="alice@example.com"):
    response = client.post("/auth/register", json={"name": "Alice", "email": email, "password": "StrongPassword123"})
    assert response.status_code == 201, response.text
    return response.json()


def auth(account):
    return {"Authorization": f"Bearer {account['access_token']}"}


def photo():
    buffer = io.BytesIO()
    Image.new("RGB", (24, 24), "green").save(buffer, "JPEG")
    return ("report.jpg", buffer.getvalue(), "image/jpeg")


def create_report(client, account):
    return client.post("/reports", headers=auth(account), data={"description": "Plastic waste near the river", "latitude": -5.55, "longitude": 95.32}, files={"image": photo()})


def admin_account(client, sessions):
    account = signup(client, "admin@example.com")
    with sessions() as db:
        user = db.get(User, account["user"]["id"])
        user.role = "admin"
        db.commit()
    return account


def test_authentication_and_registration_role(system):
    client, _ = system
    account = signup(client)
    assert account["user"]["role"] == "user"
    assert client.get("/reports").status_code == 401
    assert client.post("/auth/login", json={"email": "alice@example.com", "password": "wrong"}).status_code == 401
    assert client.post("/auth/login", json={"email": "alice@example.com", "password": "StrongPassword123"}).status_code == 200
    assert client.post("/auth/register", json={"name": "Other", "email": "ALICE@example.com", "password": "StrongPassword123", "role": "admin"}).status_code == 409
    assert client.get("/users", headers=auth(account)).status_code == 403


def test_profile_update_requires_current_password(system):
    client, _ = system
    account = signup(client)
    url = '/auth/me'
    assert client.patch(url, headers=auth(account), json={'name': 'New name', 'current_password': 'wrong', 'new_password': 'NewPassword123'}).status_code == 422
    assert client.patch(url, headers=auth(account), json={'name': 'New name', 'current_password': 'StrongPassword123', 'new_password': 'NewPassword123'}).json()['name'] == 'New name'
    assert client.post('/auth/login', json={'email': 'alice@example.com', 'password': 'StrongPassword123'}).status_code == 401
    assert client.post('/auth/login', json={'email': 'alice@example.com', 'password': 'NewPassword123'}).status_code == 200


def test_report_access_status_and_dashboard(system):
    client, sessions = system
    alice = signup(client)
    bob = signup(client, "bob@example.com")
    admin = admin_account(client, sessions)
    response = create_report(client, alice)
    assert response.status_code == 201, response.text
    report = response.json()
    report_id = report["id"]
    assert report["status"] == "Pending"
    assert report["ai_category"] == "Plastic Waste"
    for method in ["get", "patch", "delete"]:
        kwargs = {"json": {"description": "Changed by other user"}} if method == "patch" else {}
        assert getattr(client, method)(f"/reports/{report_id}", headers=auth(bob), **kwargs).status_code == 404
    assert client.get("/reports", headers=auth(bob)).json()["total"] == 0
    assert client.patch(f"/reports/{report_id}/status", headers=auth(alice), json={"status": "Completed", "expected_status": "Pending", "note": "Sudah selesai"}).status_code == 403
    assert client.get(f"/reports/{report_id}/history", headers=auth(bob)).status_code == 404
    assert client.patch(f"/reports/{report_id}", headers=auth(alice), json={"description": "Edited report description"}).status_code == 200
    assert client.patch(f"/reports/{report_id}/status", headers=auth(admin), json={"status": "Completed", "expected_status": "Pending", "note": "Selesai"}).status_code == 422
    assert client.patch(f"/reports/{report_id}/status", headers=auth(admin), json={"status": "In Progress", "expected_status": "Pending", "note": "  "}).status_code == 422
    old_status = "Pending"
    for report_status in ["In Progress", "Completed", "Rejected", "Pending"]:
        response = client.patch(f"/reports/{report_id}/status", headers=auth(admin), json={"status": report_status, "expected_status": old_status, "note": "Catatan tindak lanjut", "is_correction": old_status in ("Completed", "Rejected")})
        assert response.status_code == 200
        assert client.patch(f"/reports/{report_id}/status", headers=auth(admin), json={"status": report_status, "expected_status": old_status, "note": "Catatan ganda"}).status_code == 409
        old_status = report_status
        assert client.get("/dashboard", headers=auth(admin)).json()["by_status"][report_status] == 1
        if report_status != "Pending":
            assert client.delete(f"/reports/{report_id}", headers=auth(alice)).status_code == 403
            assert client.patch(f"/reports/{report_id}", headers=auth(alice), json={"description": "A different description"}).status_code == 403
    with sessions() as db:
        assert len(db.scalars(select(ReportStatusHistory)).all()) == 4
    history = client.get(f"/reports/{report_id}/history", headers=auth(alice)).json()
    assert len(history) == 4
    assert history[0]["note"] == "Catatan tindak lanjut"
    assert history[2]["is_correction"] is True
    notices = client.get('/notifications', headers=auth(alice)).json()
    assert len(notices) == 4 and not notices[0]['is_read']
    notice_id = notices[0]['id']
    assert client.patch(f'/notifications/{notice_id}/read', headers=auth(bob)).status_code == 404
    assert client.patch(f'/notifications/{notice_id}/read', headers=auth(alice)).json()['is_read'] is True
    assert client.get("/reports?q=Edited&status=Pending", headers=auth(alice)).json()["total"] == 1
    assert client.get("/reports?q=Missing", headers=auth(alice)).json()["total"] == 0
    assert client.delete(f"/reports/{report_id}", headers=auth(alice)).status_code == 204
    assert client.get("/reports", headers=auth(admin)).json()["total"] == 0
    assert client.get("/dashboard", headers=auth(alice)).json()["total"] == 0


def test_invalid_upload_and_model_unavailable(system, monkeypatch):
    client, _ = system
    account = signup(client)
    invalid = client.post("/reports", headers=auth(account), data={"description": "Invalid image report", "latitude": 0, "longitude": 0}, files={"image": ("fake.jpg", b"not an image", "image/jpeg")})
    assert invalid.status_code == 422
    invalid_location = client.post("/reports", headers=auth(account), data={"description": "Invalid location report", "latitude": 91, "longitude": 0}, files={"image": photo()})
    assert invalid_location.status_code == 422
    def unavailable(_):
        raise main.HTTPException(status_code=503, detail="ML model unavailable")
    monkeypatch.setattr(main, "predict_image", unavailable)
    response = create_report(client, account)
    assert response.status_code == 201
    assert response.json()["ai_category"] is None
    assert client.post("/predict", headers=auth(account), files={"image": photo()}).status_code == 503


def test_rejection_requires_public_reason_and_correction_is_audited(system):
    client, sessions = system
    account = signup(client)
    admin = admin_account(client, sessions)
    report_id = create_report(client, account).json()['id']
    url = f'/reports/{report_id}/status'
    assert client.patch(url, headers=auth(admin), json={'status': 'Rejected', 'expected_status': 'Pending', 'note': ''}).status_code == 422
    assert client.patch(url, headers=auth(admin), json={'status': 'Rejected', 'expected_status': 'Pending', 'note': 'Lokasi belum jelas'}).status_code == 200
    assert client.patch(url, headers=auth(admin), json={'status': 'Pending', 'expected_status': 'Rejected', 'note': 'Lokasi sudah diperiksa'}).status_code == 422
    assert client.patch(url, headers=auth(admin), json={'status': 'Pending', 'expected_status': 'Rejected', 'note': 'Lokasi sudah diperiksa', 'is_correction': True}).status_code == 200
    history = client.get(f'/reports/{report_id}/history', headers=auth(account)).json()
    assert [(row['new_status'], row['note'], row['is_correction']) for row in history] == [('Rejected', 'Lokasi belum jelas', False), ('Pending', 'Lokasi sudah diperiksa', True)]


def test_completion_evidence_permissions_and_visibility(system):
    client, sessions = system
    owner = signup(client)
    other = signup(client, 'other@example.com')
    admin = admin_account(client, sessions)
    report_id = create_report(client, owner).json()['id']
    url = f'/reports/{report_id}/completion-photo'
    assert client.post(url, headers=auth(owner), files={'image': photo()}).status_code == 403
    assert client.post(url, headers=auth(admin), files={'image': photo()}).status_code == 422
    for before, after in [('Pending', 'In Progress'), ('In Progress', 'Completed')]:
        assert client.patch(f'/reports/{report_id}/status', headers=auth(admin), json={'status': after, 'expected_status': before, 'note': 'Sudah ditindaklanjuti'}).status_code == 200
    result = client.post(url, headers=auth(admin), files={'image': photo()})
    assert result.status_code == 200 and result.json()['completion_image_url'].startswith('/uploads/')
    assert client.post(url, headers=auth(admin), files={'image': photo()}).status_code == 409
    assert client.get(f'/reports/{report_id}', headers=auth(owner)).json()['completion_image_url'] == result.json()['completion_image_url']
    assert client.get(f'/reports/{report_id}', headers=auth(other)).status_code == 404
    assert 'Bukti penyelesaian' in client.get('/notifications', headers=auth(owner)).json()[0]['message']


def test_category_review_preserves_prediction_and_requires_admin(system):
    client, sessions = system
    owner = signup(client)
    admin = admin_account(client, sessions)
    report_id = create_report(client, owner).json()['id']
    url = f'/reports/{report_id}/category-review'
    payload = {'category': 'Paper Waste', 'note': 'Terlihat kertas pada foto'}
    assert client.patch(url, headers=auth(owner), json=payload).status_code == 403
    assert client.patch(url, headers=auth(admin), json={'category': 'Metal', 'note': 'Logam'}).status_code == 422
    result = client.patch(url, headers=auth(admin), json=payload)
    assert result.status_code == 200
    assert result.json()['ai_category'] == 'Plastic Waste'
    assert result.json()['ai_confidence'] == .91
    assert result.json()['corrected_category'] == 'Paper Waste'
    assert result.json()['category_reviewer_id'] == admin['user']['id']
    assert client.get(f'/reports/{report_id}', headers=auth(owner)).json()['category_note'] == payload['note']


def test_admin_user_management_and_disabled_tokens(system):
    client, sessions = system
    admin = admin_account(client, sessions)
    user = signup(client)
    response = client.post("/users", headers=auth(admin), json={"name": "New User", "email": "new@example.com", "password": "StrongPassword123", "role": "user"})
    assert response.status_code == 201
    assert len(client.get("/users", headers=auth(admin)).json()) == 3
    assert client.patch(f"/users/{admin['user']['id']}", headers=auth(admin), json={"is_active": False}).status_code == 422
    assert client.patch(f"/users/{user['user']['id']}", headers=auth(admin), json={"is_active": False}).status_code == 200
    assert client.get("/dashboard", headers=auth(user)).status_code == 401


def test_whitespace_and_unicode_password_validation(system):
    client, sessions = system
    invalid = client.post("/auth/register", json={"name": "   ", "email": "empty@example.com", "password": "StrongPassword123"})
    assert invalid.status_code == 422
    invalid = client.post("/auth/register", json={"name": "Unicode", "email": "unicode@example.com", "password": "界" * 25})
    assert invalid.status_code == 422
    account = signup(client)
    assert client.post("/auth/login", json={"email": "alice@example.com", "password": "界" * 25}).status_code == 401
    invalid = client.post("/reports", headers=auth(account), data={"description": " " * 20, "latitude": 0, "longitude": 0}, files={"image": photo()})
    assert invalid.status_code == 422
    report_id = create_report(client, account).json()["id"]
    assert client.patch(f"/reports/{report_id}", headers=auth(account), json={"description": " " * 20}).status_code == 422
    admin = admin_account(client, sessions)
    assert client.patch(f"/users/{account['user']['id']}", headers=auth(admin), json={"name": "   "}).status_code == 422


def test_pagination_invalid_status_and_prediction(system):
    client, _ = system
    account = signup(client)
    for _ in range(2):
        assert create_report(client, account).status_code == 201
    page = client.get("/reports?page=2&page_size=1", headers=auth(account)).json()
    assert page["total"] == 2
    assert len(page["items"]) == 1
    assert client.get("/reports?status=Unknown", headers=auth(account)).status_code == 422
    assert client.get("/reports?page=0", headers=auth(account)).status_code == 422
    prediction = client.post("/predict", headers=auth(account), files={"image": photo()})
    assert prediction.status_code == 200
    assert prediction.json() == {"category": "Plastic Waste", "confidence": 0.91}


def test_report_filters_and_safe_admin_export(system):
    client, sessions = system
    owner = signup(client)
    admin = admin_account(client, sessions)
    report = create_report(client, owner).json()
    assert client.patch(f"/reports/{report['id']}", headers=auth(owner), json={'description': '=SUM(1,2) suspicious entry'}).status_code == 200
    assert client.get('/reports?category=Plastic%20Waste', headers=auth(admin)).json()['total'] == 1
    assert client.get('/reports?category=Paper%20Waste', headers=auth(admin)).json()['total'] == 0
    assert client.get('/reports?date_from=2026-02-02&date_to=2026-01-01', headers=auth(admin)).status_code == 422
    assert client.get('/reports-export', headers=auth(owner)).status_code == 403
    exported = client.get('/reports-export?category=Plastic%20Waste', headers=auth(admin))
    assert exported.status_code == 200
    assert "'=SUM(1,2) suspicious entry" in exported.text


def test_real_model_prediction_and_report(system, monkeypatch):
    torch = pytest.importorskip("torch")
    model_path = Path(__file__).resolve().parents[2] / "ml" / "artifacts" / "best_model.pt"
    assert model_path.exists(), "The trained checkpoint must be included with the source"
    from app.predictor import load_model
    torch.set_num_threads(2)
    monkeypatch.setenv("MODEL_PATH", str(model_path))
    load_model.cache_clear()
    monkeypatch.setattr(main, "predict_image", REAL_PREDICT_IMAGE)
    client, _ = system
    account = signup(client)
    example = model_path.parent.parent / "examples" / "organic.jpg"
    image = ("organic.jpg", example.read_bytes(), "image/jpeg")
    prediction = client.post("/predict", headers=auth(account), files={"image": image})
    assert prediction.status_code == 200, prediction.text
    result = prediction.json()
    assert result["category"] in main.CATEGORIES
    assert 0 <= result["confidence"] <= 1
    report = client.post("/reports", headers=auth(account), data={"description": "Organic waste model integration", "latitude": 0, "longitude": 0}, files={"image": image})
    assert report.status_code == 201, report.text
    assert report.json()["ai_category"] == result["category"]
    assert report.json()["ai_confidence"] == pytest.approx(result["confidence"])
    assert client.get("/dashboard", headers=auth(account)).json()["by_category"][result["category"]] == 1
    load_model.cache_clear()


def test_camera_photo_orientation_is_preserved_and_metadata_removed(system):
    client, _ = system
    account = signup(client)
    buffer = io.BytesIO()
    image = Image.new("RGB", (30, 20), "green")
    exif = Image.Exif()
    exif[274] = 6  # Rotate 90 degrees clockwise for display.
    image.save(buffer, "JPEG", exif=exif)
    response = client.post("/reports", headers=auth(account), data={"description": "Camera photo with orientation metadata", "latitude": 0, "longitude": 0}, files={"image": ("camera.jpg", buffer.getvalue(), "image/jpeg")})
    assert response.status_code == 201, response.text
    path = main.UPLOAD_DIR / Path(response.json()["image_url"]).name
    with Image.open(path) as stored:
        assert stored.size == (20, 30)
        assert not stored.getexif()

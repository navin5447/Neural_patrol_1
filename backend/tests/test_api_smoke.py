from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_root_status():
    response = client.get("/")
    assert response.status_code == 200
    assert "SpeciesTrace API" in response.json()["message"] or "operational" in response.json()["message"]


def test_demo_login():
    response = client.post("/auth/demo-login")
    assert response.status_code == 200
    assert "access_token" in response.json()


def test_case_creation_requires_auth():
    response = client.post("/cases", json={"case_number": "CHD-2026-041", "title": "Demo case"})
    assert response.status_code == 403

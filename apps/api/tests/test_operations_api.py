from fastapi.testclient import TestClient

from app.main import app


def test_operational_status():
    client = TestClient(app)
    response = client.get("/api/v1/operations/status")
    assert response.status_code == 200
    assert response.json()["runtime"] == "online"


def test_plan_mission_and_list_it():
    client = TestClient(app)
    response = client.post("/api/v1/operations/missions/plan", json={"objective": "criar uma loja ecommerce segura"})
    assert response.status_code == 200
    payload = response.json()
    assert payload["mission"]["objective"] == "criar uma loja ecommerce segura"
    assert payload["event_id"]

    missions = client.get("/api/v1/operations/missions")
    assert missions.status_code == 200
    assert any(item["id"] == payload["mission"]["id"] for item in missions.json()["missions"])


def test_recent_events():
    client = TestClient(app)
    client.post("/api/v1/operations/missions/plan", json={"objective": "analisar segurança"})
    response = client.get("/api/v1/operations/events?limit=10")
    assert response.status_code == 200
    assert response.json()["events"]

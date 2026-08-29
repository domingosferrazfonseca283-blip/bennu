from dataclasses import asdict
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from packages.core.operational_runtime import OperationalRuntime

router = APIRouter(prefix="/api/v1/operations", tags=["operations"])
runtime = OperationalRuntime()


class MissionRequest(BaseModel):
    objective: str = Field(min_length=1, max_length=5000)
    mission_id: str | None = None


@router.get("/status")
def operational_status():
    return runtime.status()


@router.get("/events")
def operational_events(limit: int = 50):
    if limit < 1 or limit > 200:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 200")
    return {"events": [asdict(event) for event in runtime.recent_events(limit)]}


@router.get("/missions")
def missions():
    return {"missions": runtime.missions.store.list_missions()}


@router.get("/missions/{mission_id}")
def mission(mission_id: str):
    item = runtime.missions.store.get_mission(mission_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Mission not found")
    return item


@router.post("/missions/plan")
def plan_mission(request: MissionRequest):
    mission_id = request.mission_id or f"m-{uuid4().hex[:12]}"
    try:
        return runtime.plan_mission(request.objective, mission_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

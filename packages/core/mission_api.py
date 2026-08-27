from dataclasses import asdict
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from packages.core.mission_engine import MissionEngine
from apps.api.app.auth import Principal, require_role

router = APIRouter(prefix="/api/v1/missions", tags=["missions"])
engine = MissionEngine()

class MissionRequest(BaseModel):
    objective: str

@router.post("")
def create_mission(request: MissionRequest, principal: Principal = Depends(require_role("admin", "operator", "developer", "security"))):
    mission = engine.plan(f"mission-{abs(hash((principal.subject, request.objective))) % 10**10}", request.objective)
    return asdict(mission)

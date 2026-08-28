from fastapi import APIRouter, Depends, HTTPException
from apps.api.app.auth import Principal, require_role
from packages.core.mission_query import MissionQuery

router = APIRouter(prefix="/api/v1", tags=["operations"])
query = MissionQuery()

READ_ROLES = ("admin", "operator", "developer", "security")

@router.get("/missions")
def list_missions(principal: Principal = Depends(require_role(*READ_ROLES))):
    return {"items": query.list_missions()}

@router.get("/missions/{mission_id}")
def get_mission(mission_id: str, principal: Principal = Depends(require_role(*READ_ROLES))):
    mission = query.get_mission(mission_id)
    if mission is None:
        raise HTTPException(status_code=404, detail="mission not found")
    return mission

@router.get("/executions")
def list_executions(principal: Principal = Depends(require_role(*READ_ROLES))):
    return {"items": query.list_executions()}

@router.get("/executions/{task_id}")
def get_execution(task_id: str, principal: Principal = Depends(require_role(*READ_ROLES))):
    execution = query.get_execution(task_id)
    if execution is None:
        raise HTTPException(status_code=404, detail="execution not found")
    return execution

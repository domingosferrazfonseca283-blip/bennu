from fastapi import APIRouter, Depends, HTTPException
from apps.api.app.auth import Principal, require_role
from packages.core.mission_orchestrator import MissionOrchestrator

router = APIRouter(prefix="/api/v1/orchestration", tags=["orchestration"])
orchestrator = MissionOrchestrator()

@router.post("/plan")
def plan_mission(mission: dict, principal: Principal = Depends(require_role("admin", "operator"))):
    try:
        # Adapter kept intentionally small: the existing mission engine remains the source of truth.
        from packages.core.mission_engine import Mission, Task
        tasks = tuple(Task(**t) for t in mission.get("tasks", []))
        model = Mission(id=str(mission["id"]), objective=str(mission["objective"]), tasks=tasks, status=mission.get("status", "planned"))
        plan = orchestrator.plan(model)
        return {"mission_id": plan.mission_id, "status": plan.status, "assignments": [
            {"task_id": a.task_id, "agent_id": a.agent_id, "role": a.role,
             "action": a.decision.action, "requires_approval": a.decision.requires_approval,
             "reason": a.decision.reason}
            for a in plan.assignments
        ]}
    except (KeyError, TypeError, ValueError) as exc:
        raise HTTPException(status_code=400, detail=str(exc))

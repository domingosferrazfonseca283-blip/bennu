from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from .auth import Principal, require_role
from packages.agents.security_agent_v01 import SecurityAgent

router = APIRouter(prefix="/api/v1/security", tags=["security"])
agent = SecurityAgent()

class PlanRequest(BaseModel):
    target: str
    autonomy_level: int = 2

@router.post("/plan")
def plan(request: PlanRequest, principal: Principal = Depends(require_role("security", "operator", "admin"))):
    target = request.target.strip()
    if not target:
        raise HTTPException(status_code=400, detail="Target is required")
    plan = agent.plan(target)
    decisions = agent.evaluate(target, request.autonomy_level)
    return {
        "target": plan.target,
        "requested_by": principal.subject,
        "actions": [
            {"name": action.name, "risk": action.risk,
             "requires_approval": action.requires_approval,
             "allowed": decision.allowed,
             "approval_required": decision.requires_approval,
             "reason": decision.reason}
            for action, decision in zip(plan.actions, decisions)
        ],
        "execution": "approval-required"
    }

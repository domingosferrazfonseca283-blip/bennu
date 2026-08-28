from fastapi import APIRouter, Depends
from apps.api.app.auth import Principal, require_role
from packages.core.default_agents import create_default_runtime

router = APIRouter(prefix="/api/v1/agents", tags=["agents"])
runtime = create_default_runtime()

@router.get("")
def list_agents(principal: Principal = Depends(require_role("admin", "operator", "security"))):
    return {"items": [
        {
            "agent_id": a.agent_id,
            "name": a.name,
            "role": a.role,
            "capabilities": list(a.capabilities),
            "permissions": list(a.permissions),
            "status": "idle",
        }
        for a in runtime.agents.values()
    ]}

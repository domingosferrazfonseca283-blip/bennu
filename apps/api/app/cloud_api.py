from fastapi import APIRouter, Depends
from pydantic import BaseModel
from .auth import Principal, require_role

router = APIRouter(prefix="/api/v1/cloud", tags=["cloud"])

class Deployment(BaseModel):
    name: str
    image: str
    replicas: int = 1

@router.get("/status")
def status(principal: Principal = Depends(require_role("viewer", "operator", "admin", "developer"))):
    return {"provider": "local", "containers": 0, "orchestrator": "not-configured"}

@router.post("/deploy")
def deploy(request: Deployment, principal: Principal = Depends(require_role("admin", "developer"))):
    return {"accepted": True, "deployment": request, "status": "approval-required"}

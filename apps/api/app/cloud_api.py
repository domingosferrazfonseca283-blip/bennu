from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from .main import db
from .models import AuditEvent, Deployment as DeploymentModel
from .auth import Principal, require_role

router = APIRouter(prefix="/api/v1/cloud", tags=["cloud"])

class Deployment(BaseModel):
    name: str
    image: str
    replicas: int = Field(default=1, ge=1, le=100)

@router.get("/status")
def status(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "developer"))):
    count = session.scalar(select(func.count()).select_from(DeploymentModel)) or 0
    return {"provider": "local", "deployments": count, "orchestrator": "capability-ready", "execution": "approval-gated"}

@router.get("/deployments")
def deployments(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "developer"))):
    return session.scalars(select(DeploymentModel).order_by(DeploymentModel.id.desc())).all()

@router.post("/deploy")
def deploy(request: Deployment, session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "developer"))):
    deployment = DeploymentModel(name=request.name, image=request.image, replicas=request.replicas, status="approval-required")
    session.add(deployment)
    session.add(AuditEvent(action="cloud.deployment.requested", actor=principal.subject, detail=request.model_dump_json()))
    session.commit(); session.refresh(deployment)
    return {"accepted": True, "deployment": deployment}

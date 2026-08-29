from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session
from .main import db
from .models import AuditEvent
from .auth import Principal, require_role

router = APIRouter(prefix="/api/v1/cloud", tags=["cloud"])

class Deployment(BaseModel):
    name: str
    image: str
    replicas: int = Field(default=1, ge=1, le=100)

@router.get("/status")
def status(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "developer"))):
    count = session.scalar(text("SELECT COUNT(*) FROM deployments")) or 0
    return {"provider": "local", "deployments": count, "orchestrator": "capability-ready", "execution": "approval-gated"}

@router.get("/deployments")
def deployments(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "developer"))):
    rows = session.execute(text("SELECT id, name, image, replicas, status, created_at FROM deployments ORDER BY id DESC")).mappings().all()
    return [dict(row) for row in rows]

@router.post("/deploy")
def deploy(request: Deployment, session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "developer"))):
    result = session.execute(
        text("INSERT INTO deployments (name, image, replicas, status, created_at) VALUES (:name, :image, :replicas, 'approval-required', CURRENT_TIMESTAMP) RETURNING id"),
        {"name": request.name, "image": request.image, "replicas": request.replicas},
    )
    deployment_id = result.scalar_one()
    session.add(AuditEvent(action="cloud.deployment.requested", actor=principal.subject, detail=request.model_dump_json()))
    session.commit()
    return {"accepted": True, "deployment_id": deployment_id, "status": "approval-required"}

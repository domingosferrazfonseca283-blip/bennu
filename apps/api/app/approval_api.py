from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from .auth import Principal, require_role
from .db import SessionLocal
from .models import Task, AuditEvent

router = APIRouter(prefix="/api/v1/approvals", tags=["approvals"])

class DecisionRequest(BaseModel):
    reason: str = ""

def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

@router.get("")
def pending(session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "operator", "security"))):
    return session.scalars(select(Task).where(Task.status == "approval-required").order_by(Task.id.desc())).all()

@router.post("/{task_id}/approve")
def approve(task_id: int, request: DecisionRequest, session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "security"))):
    task = session.get(Task, task_id)
    if not task or task.status != "approval-required":
        raise HTTPException(status_code=404, detail="Approval request not found")
    task.status = "approved"
    session.add(AuditEvent(action="task.approved", actor=principal.subject, detail=request.reason))
    session.commit()
    return {"task_id": task.id, "status": task.status, "approved_by": principal.subject}

@router.post("/{task_id}/reject")
def reject(task_id: int, request: DecisionRequest, session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "security"))):
    task = session.get(Task, task_id)
    if not task or task.status != "approval-required":
        raise HTTPException(status_code=404, detail="Approval request not found")
    task.status = "rejected"
    session.add(AuditEvent(action="task.rejected", actor=principal.subject, detail=request.reason))
    session.commit()
    return {"task_id": task.id, "status": task.status, "rejected_by": principal.subject}

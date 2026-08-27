from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from .auth import Principal, require_role
from .db import SessionLocal
from .models import Task, AuditEvent
from packages.agents.executor import SandboxedExecutor
from packages.agents.tool_registry import default_registry

router = APIRouter(prefix="/api/v1/approvals", tags=["approvals"])
executor = SandboxedExecutor(default_registry())

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

@router.post("/{task_id}/execute")
def execute_approved(task_id: int, session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "security"))):
    task = session.get(Task, task_id)
    if not task or task.status != "approved":
        raise HTTPException(status_code=409, detail="Task is not approved for execution")
    task.status = "running"
    session.add(AuditEvent(action="task.execution.started", actor=principal.subject, detail=str(task.id)))
    session.commit()
    # v0.1 deliberately supports only safe read-only tool adapters.
    tool_name = "system_status" if task.command.strip() == "system_status" else task.command.strip()
    result = executor.execute(tool_name, principal.role)
    task.status = "completed" if result.status == "completed" else result.status
    session.add(AuditEvent(action="task.execution.finished", actor=principal.subject, detail=result.message))
    session.commit()
    return {"task_id": task.id, "status": task.status, "tool": result.tool, "message": result.message}

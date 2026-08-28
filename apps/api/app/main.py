from datetime import datetime, timezone
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from .db import SessionLocal
from .models import Agent, Task, AuditEvent
from .tools_api import router as tools_router
from .security_plan_api import router as security_router
from .access_api import router as access_router
from .auth import Principal, require_role

app = FastAPI(title="Bennu Core", version="0.5.0")
app.include_router(tools_router)
app.include_router(security_router)
app.include_router(access_router)

class TaskRequest(BaseModel):
    command: str
    dry_run: bool = True

class AgentRequest(BaseModel):
    name: str
    role: str
    autonomous: bool = False

def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

@app.get("/health")
def health():
    return {"status": "online", "service": "bennu-core", "version": app.version, "timestamp": datetime.now(timezone.utc).isoformat()}

@app.get("/api/v1/system/status")
def system_status(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "security", "developer"))):
    return {"status": "online", "security_score": 100, "agents": session.query(Agent).count(), "tasks": session.query(Task).count(), "mode": "safe", "principal": principal.subject, "role": principal.role}

@app.get("/api/v1/agents")
def list_agents(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "security", "developer"))):
    return session.scalars(select(Agent).order_by(Agent.id)).all()

@app.post("/api/v1/agents")
def create_agent(request: AgentRequest, session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "operator"))):
    if request.role not in {"ceo", "security", "developer", "sales", "finance", "marketing"}:
        raise HTTPException(status_code=400, detail="Unsupported agent role")
    agent = Agent(name=request.name, role=request.role, autonomous=request.autonomous)
    session.add(agent)
    session.add(AuditEvent(action="agent.created", actor=principal.subject, detail=request.name))
    session.commit()
    session.refresh(agent)
    return agent

@app.post("/api/v1/tasks")
def create_task(request: TaskRequest, session: Session = Depends(db), principal: Principal = Depends(require_role("operator", "admin", "security", "developer"))):
    task = Task(command=request.command, dry_run=request.dry_run, status="pending" if request.dry_run else "approval-required")
    session.add(task)
    session.add(AuditEvent(action="task.created", actor=principal.subject, detail=request.command))
    session.commit()
    session.refresh(task)
    return {"accepted": True, "task_id": task.id, "execution": task.status, "command": task.command}

@app.get("/api/v1/audit")
def audit(session: Session = Depends(db), principal: Principal = Depends(require_role("admin", "operator", "security"))):
    return session.scalars(select(AuditEvent).order_by(AuditEvent.id.desc()).limit(100)).all()

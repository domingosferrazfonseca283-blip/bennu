from datetime import datetime, timezone
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from .db import SessionLocal
from .models import Agent, Task, AuditEvent
from .tools_api import router as tools_router
from .security_plan_api import router as security_router
from .access_api import router as access_router
from .business_api import router as business_router
from .sales_api import router as sales_router
from .marketplace_api import router as marketplace_router
from .cloud_api import router as cloud_router
from .operations_api import router as operations_router
from .auth import Principal, require_role

app = FastAPI(title="Bennu Core", version="0.7.0")
for router in (tools_router, security_router, access_router, business_router, sales_router, marketplace_router, cloud_router, operations_router):
    app.include_router(router)

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

@app.get("/api/v1/mobile/overview")
def mobile_overview(session: Session = Depends(db)):
    """Read-only mobile overview. No authentication is required because it exposes only aggregate telemetry."""
    task_rows = session.execute(select(Task.status)).all()
    task_status = {}
    for (status,) in task_rows:
        task_status[status] = task_status.get(status, 0) + 1

    agent_rows = session.execute(select(Agent.role)).all()
    agent_roles = {}
    for (role,) in agent_rows:
        agent_roles[role] = agent_roles.get(role, 0) + 1

    return {
        "status": "online",
        "service": "bennu-core",
        "version": app.version,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "agents": len(agent_rows),
        "tasks": len(task_rows),
        "task_status": task_status,
        "agent_roles": agent_roles,
    }

@app.get("/api/v1/system/status")
def system_status(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "security", "developer", "sales", "marketing", "finance"))):
    return {"status": "online", "security_score": 100, "agents": session.query(Agent).count(), "tasks": session.query(Task).count(), "mode": "safe", "principal": principal.subject, "role": principal.role}

@app.get("/api/v1/agents")
def list_agents(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "security", "developer", "sales", "marketing", "finance"))):
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

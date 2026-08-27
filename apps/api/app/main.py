from datetime import datetime, timezone
from fastapi import FastAPI, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from .db import Base, SessionLocal, engine
from .models import Agent, Task, AuditEvent

app = FastAPI(title="Bennu Core", version="0.2.0")
Base.metadata.create_all(bind=engine)

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
def system_status(session: Session = Depends(db)):
    return {"status": "online", "security_score": 100, "agents": session.query(Agent).count(), "tasks": session.query(Task).count(), "mode": "safe"}

@app.get("/api/v1/agents")
def list_agents(session: Session = Depends(db)):
    return session.scalars(select(Agent).order_by(Agent.id)).all()

@app.post("/api/v1/agents")
def create_agent(request: AgentRequest, session: Session = Depends(db)):
    agent = Agent(name=request.name, role=request.role, autonomous=request.autonomous)
    session.add(agent)
    session.add(AuditEvent(action="agent.created", actor="system", detail=request.name))
    session.commit()
    session.refresh(agent)
    return agent

@app.post("/api/v1/tasks")
def create_task(request: TaskRequest, session: Session = Depends(db)):
    task = Task(command=request.command, dry_run=request.dry_run, status="pending" if request.dry_run else "approval-required")
    session.add(task)
    session.add(AuditEvent(action="task.created", actor="system", detail=request.command))
    session.commit()
    session.refresh(task)
    return {"accepted": True, "task_id": task.id, "execution": task.status, "command": task.command}

@app.get("/api/v1/audit")
def audit(session: Session = Depends(db)):
    return session.scalars(select(AuditEvent).order_by(AuditEvent.id.desc()).limit(100)).all()

from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import SessionLocal
from .models import Agent, AuditEvent, Task

router = APIRouter(prefix="/api/v1/mobile", tags=["mobile"])


def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@router.get("/operations")
def operations(session: Session = Depends(db)):
    """Read-only operational telemetry for the private Command Center."""
    tasks = session.execute(select(Task).order_by(Task.id.desc()).limit(100)).scalars().all()
    agents = session.execute(select(Agent).order_by(Agent.id)).scalars().all()
    audits = session.execute(select(AuditEvent).order_by(AuditEvent.id.desc()).limit(30)).scalars().all()

    task_status = {}
    for task in tasks:
        task_status[task.status] = task_status.get(task.status, 0) + 1

    agent_roles = {}
    for agent in agents:
        agent_roles[agent.role] = agent_roles.get(agent.role, 0) + 1

    events = [
        {
            "id": item.id,
            "timestamp": item.created_at.isoformat() if item.created_at else None,
            "type": item.action,
            "actor": item.actor,
            "detail": item.detail,
        }
        for item in audits
    ]

    return {
        "status": "online",
        "service": "bennu-core",
        "version": "0.7.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "agents": len(agents),
        "tasks": len(tasks),
        "task_status": task_status,
        "agent_roles": agent_roles,
        "events": events,
    }

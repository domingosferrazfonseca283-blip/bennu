from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from .db import SessionLocal
from .models import Agent, AuditEvent, Task

router = APIRouter(prefix="/api/v1/analytics", tags=["analytics"])


def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@router.get("/overview")
def analytics_overview(session: Session = Depends(db)):
    """Read-only real telemetry for the Private Command Center."""
    total_tasks = session.scalar(select(func.count()).select_from(Task)) or 0
    total_agents = session.scalar(select(func.count()).select_from(Agent)) or 0
    total_events = session.scalar(select(func.count()).select_from(AuditEvent)) or 0

    task_rows = session.execute(
        select(Task.status, func.count()).group_by(Task.status).order_by(Task.status)
    ).all()
    task_status = [{"status": status, "count": count} for status, count in task_rows]

    agent_rows = session.execute(
        select(Agent.role, func.count()).group_by(Agent.role).order_by(Agent.role)
    ).all()
    agent_roles = [{"role": role, "count": count} for role, count in agent_rows]

    event_rows = session.execute(
        select(AuditEvent.action, func.count()).group_by(AuditEvent.action).order_by(AuditEvent.action)
    ).all()
    event_types = [{"type": action, "count": count} for action, count in event_rows]

    return {
        "status": "online",
        "source": "database",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "totals": {
            "tasks": total_tasks,
            "agents": total_agents,
            "events": total_events,
        },
        "task_status": task_status,
        "agent_roles": agent_roles,
        "event_types": event_types,
    }

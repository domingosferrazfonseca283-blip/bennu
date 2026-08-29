from datetime import datetime, timezone
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, func, text
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

app = FastAPI(title="Bennu Core", version="0.7.1")
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
    """Read-only aggregate telemetry for the private client. No PII or secrets are returned."""
    task_rows = session.execute(select(Task.status)).all()
    task_status = {}
    for (status,) in task_rows:
        task_status[status] = task_status.get(status, 0) + 1

    agent_rows = session.execute(select(Agent.role, Agent.status, Agent.autonomous)).all()
    agent_roles = {}
    agent_status = {}
    autonomous = 0
    for role, status, is_autonomous in agent_rows:
        agent_roles[role] = agent_roles.get(role, 0) + 1
        agent_status[status] = agent_status.get(status, 0) + 1
        autonomous += int(bool(is_autonomous))

    return {
        "status": "online",
        "service": "bennu-core",
        "version": app.version,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "agents": len(agent_rows),
        "autonomous_agents": autonomous,
        "tasks": len(task_rows),
        "task_status": task_status,
        "agent_roles": agent_roles,
        "agent_status": agent_status,
    }

@app.get("/api/v1/mobile/dashboard")
def mobile_dashboard(session: Session = Depends(db)):
    """Single privacy-safe telemetry contract used by Android, Linux and Windows clients."""
    def count(table: str) -> int:
        return int(session.scalar(text(f"SELECT COUNT(*) FROM {table}")) or 0)

    def grouped(table: str, column: str) -> dict[str, int]:
        rows = session.execute(text(f"SELECT {column}, COUNT(*) FROM {table} GROUP BY {column}")).all()
        return {str(key or "unknown"): int(value) for key, value in rows}

    task_status = grouped("tasks", "status")
    agent_status = grouped("agents", "status")
    agent_roles = grouped("agents", "role")
    access_status = grouped("access_requests", "status")
    opportunity_stages = grouped("opportunities", "stage")
    product_status = grouped("marketplace_products", "status")
    deployment_status = grouped("deployments", "status")

    pipeline_value = float(session.scalar(text("SELECT COALESCE(SUM(value), 0) FROM opportunities")) or 0)
    audit_total = count("audit_events")
    pending_access = access_status.get("pending", 0)
    active_agents = sum(v for k, v in agent_status.items() if k in {"online", "running", "active"})

    modules = {
        "ia_agentes": {"state": "online" if active_agents else "ready", "agents": count("agents"), "autonomous": int(session.scalar(text("SELECT COALESCE(SUM(CASE WHEN autonomous THEN 1 ELSE 0 END), 0) FROM agents")) or 0)},
        "seguranca": {"state": "protected", "audit_events": audit_total, "access_pending": pending_access},
        "business": {"state": "online", "leads": count("business_leads"), "opportunities": count("opportunities"), "pipeline_value": pipeline_value},
        "vendas": {"state": "online", "campaigns": count("sales_campaigns"), "opportunities": count("opportunities")},
        "marketplace": {"state": "online", "products": count("marketplace_products"), "product_status": product_status},
        "cloud": {"state": "online", "deployments": count("deployments"), "deployment_status": deployment_status},
        "operacoes": {"state": "online", "missions": len(getattr(runtime_missions := operations_router, "__dict__", {})) if False else 0},
    }

    return {
        "status": "online",
        "service": "bennu-core",
        "version": app.version,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "privacy": {"mode": "private", "pii_exposed": False, "secrets_exposed": False},
        "learning": {"mode": "telemetry-driven", "source": "live-core-database", "last_observed_at": datetime.now(timezone.utc).isoformat()},
        "summary": {"agents": count("agents"), "tasks": count("tasks"), "audit_events": audit_total, "pending_access": pending_access, "leads": count("business_leads"), "opportunities": count("opportunities"), "pipeline_value": pipeline_value, "campaigns": count("sales_campaigns"), "products": count("marketplace_products"), "deployments": count("deployments")},
        "task_status": task_status,
        "agent_status": agent_status,
        "agent_roles": agent_roles,
        "access_status": access_status,
        "opportunity_stages": opportunity_stages,
        "modules": modules,
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

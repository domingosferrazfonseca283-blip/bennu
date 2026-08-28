from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from .main import db
from .models import AuditEvent
from .auth import Principal, require_role

router = APIRouter(prefix="/api/v1/business", tags=["business"])

class Lead(BaseModel):
    name: str
    email: str
    source: str = "manual"

class Opportunity(BaseModel):
    lead: str
    value: float = 0
    stage: str = "new"

@router.get("/overview")
def overview(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "sales"))):
    events = session.scalars(select(AuditEvent).where(AuditEvent.action.in_(["business.lead.created", "business.opportunity.created"])).order_by(AuditEvent.id.desc()).limit(100)).all()
    return {"leads": sum(e.action == "business.lead.created" for e in events), "opportunities": sum(e.action == "business.opportunity.created" for e in events), "pipeline_value": 0, "updated_at": datetime.now(timezone.utc).isoformat()}

@router.post("/leads")
def create_lead(request: Lead, session: Session = Depends(db), principal: Principal = Depends(require_role("operator", "admin", "sales"))):
    session.add(AuditEvent(action="business.lead.created", actor=principal.subject, detail=request.model_dump_json()))
    session.commit()
    return {"accepted": True, "lead": request}

@router.post("/opportunities")
def create_opportunity(request: Opportunity, session: Session = Depends(db), principal: Principal = Depends(require_role("operator", "admin", "sales"))):
    session.add(AuditEvent(action="business.opportunity.created", actor=principal.subject, detail=request.model_dump_json()))
    session.commit()
    return {"accepted": True, "opportunity": request}

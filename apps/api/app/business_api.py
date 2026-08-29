from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from .dependencies import db
from .models import AuditEvent
from .business_models import BusinessLead, Opportunity
from .auth import Principal, require_role

router = APIRouter(prefix="/api/v1/business", tags=["business"])

class Lead(BaseModel):
    name: str
    email: str
    source: str = "manual"

class OpportunityRequest(BaseModel):
    lead: str
    value: float = 0
    stage: str = "new"

@router.get("/overview")
def overview(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "sales"))):
    return {"leads": session.scalar(select(func.count(BusinessLead.id))) or 0, "opportunities": session.scalar(select(func.count(Opportunity.id))) or 0, "pipeline_value": session.scalar(select(func.coalesce(func.sum(Opportunity.value), 0))) or 0, "updated_at": datetime.now(timezone.utc).isoformat()}

@router.post("/leads")
def create_lead(request: Lead, session: Session = Depends(db), principal: Principal = Depends(require_role("operator", "admin", "sales"))):
    lead = BusinessLead(**request.model_dump())
    session.add(lead)
    session.add(AuditEvent(action="business.lead.created", actor=principal.subject, detail=request.model_dump_json()))
    session.commit(); session.refresh(lead)
    return lead

@router.post("/opportunities")
def create_opportunity(request: OpportunityRequest, session: Session = Depends(db), principal: Principal = Depends(require_role("operator", "admin", "sales"))):
    opportunity = Opportunity(**request.model_dump())
    session.add(opportunity)
    session.add(AuditEvent(action="business.opportunity.created", actor=principal.subject, detail=request.model_dump_json()))
    session.commit(); session.refresh(opportunity)
    return opportunity

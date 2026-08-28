from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from .main import db
from .models import AuditEvent
from .auth import Principal, require_role

router = APIRouter(prefix="/api/v1/sales", tags=["sales"])

class Campaign(BaseModel):
    name: str
    channel: str
    status: str = "draft"

@router.get("/pipeline")
def pipeline(session: Session = Depends(db), principal: Principal = Depends(require_role("viewer", "operator", "admin", "sales"))):
    return {"stages": ["new", "contacted", "qualified", "proposal", "won", "lost"], "campaigns": 0}

@router.post("/campaigns")
def create_campaign(request: Campaign, session: Session = Depends(db), principal: Principal = Depends(require_role("operator", "admin", "sales", "marketing"))):
    session.add(AuditEvent(action="sales.campaign.created", actor=principal.subject, detail=request.model_dump_json()))
    session.commit()
    return {"accepted": True, "campaign": request}

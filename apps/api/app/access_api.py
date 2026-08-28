from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from .auth import Principal, current_identity, require_role
from .access_repository import AccessRepository
from .db import SessionLocal
from .models import AuditEvent

router = APIRouter(prefix="/api/v1/access", tags=["access"])


def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

class AccessDecision(BaseModel):
    role: str = "viewer"

@router.get("/me")
def me(principal: Principal = Depends(current_identity), session: Session = Depends(db)):
    repo = AccessRepository(session)
    owner = repo.get_owner()
    if owner and owner.issuer == principal.issuer and owner.subject == principal.subject:
        return {"subject": principal.subject, "email": principal.email, "role": "admin", "status": "approved", "owner": True}
    request = repo.find_identity(principal.issuer, principal.subject)
    return {"subject": principal.subject, "email": principal.email, "role": request.role if request and request.status == "approved" else None, "status": request.status if request else "pending", "owner": False}

@router.post("/bootstrap")
def bootstrap_owner(principal: Principal = Depends(current_identity), session: Session = Depends(db)):
    repo = AccessRepository(session)
    if repo.get_owner() is not None:
        raise HTTPException(status_code=409, detail="Owner is already initialized")
    owner = repo.create_owner(principal.issuer, principal.subject, principal.email)
    session.add(AuditEvent(action="owner.initialized", actor=principal.subject, detail=principal.email))
    session.commit()
    return {"owner": True, "subject": owner.subject, "email": owner.verified_email}

@router.post("/request")
def request_access(principal: Principal = Depends(current_identity), session: Session = Depends(db)):
    repo = AccessRepository(session)
    owner = repo.get_owner()
    if owner and owner.issuer == principal.issuer and owner.subject == principal.subject:
        return {"status": "approved", "owner": True, "role": "admin"}
    item = repo.create_request(principal.issuer, principal.subject, principal.email)
    session.add(AuditEvent(action="access.requested", actor=principal.subject, detail=principal.email))
    session.commit()
    return {"id": item.id, "status": item.status, "email": item.email}

@router.get("/requests")
def pending_requests(session: Session = Depends(db), principal: Principal = Depends(require_role("admin"))):
    return AccessRepository(session).list_pending()

@router.post("/requests/{request_id}/approve")
def approve(request_id: int, body: AccessDecision, session: Session = Depends(db), principal: Principal = Depends(require_role("admin"))):
    if body.role not in {"viewer", "operator", "security", "developer"}:
        raise HTTPException(status_code=400, detail="Unsupported role")
    try:
        item = AccessRepository(session).review_request(request_id, True, principal.subject, body.role)
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    session.add(AuditEvent(action="access.approved", actor=principal.subject, detail=f"{item.subject}:{body.role}"))
    session.commit()
    return item

@router.post("/requests/{request_id}/reject")
def reject(request_id: int, session: Session = Depends(db), principal: Principal = Depends(require_role("admin"))):
    try:
        item = AccessRepository(session).review_request(request_id, False, principal.subject)
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    session.add(AuditEvent(action="access.rejected", actor=principal.subject, detail=item.subject))
    session.commit()
    return item

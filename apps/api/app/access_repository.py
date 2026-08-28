from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.orm import Session
from .db import SessionLocal
from .models import OwnerIdentity, AccessRequest


def utcnow():
    return datetime.now(timezone.utc)


class AccessRepository:
    """Database-backed access registry.

    Identity is keyed by OIDC issuer + subject. Authorization state is durable
    and survives application restarts.
    """
    def __init__(self, session: Session | None = None):
        self._owned_session = session is None
        self.session = session or SessionLocal()

    def close(self):
        if self._owned_session:
            self.session.close()

    def get_owner(self) -> OwnerIdentity | None:
        return self.session.scalars(select(OwnerIdentity).limit(1)).first()

    def create_owner(self, issuer: str, subject: str, verified_email: str) -> OwnerIdentity:
        if self.get_owner() is not None:
            raise RuntimeError("owner is already initialized")
        owner = OwnerIdentity(issuer=issuer.strip(), subject=subject.strip(), verified_email=verified_email.strip().lower())
        self.session.add(owner)
        self.session.commit()
        self.session.refresh(owner)
        return owner

    def find_identity(self, issuer: str, subject: str) -> AccessRequest | None:
        return self.session.scalar(select(AccessRequest).where(AccessRequest.issuer == issuer, AccessRequest.subject == subject))

    def create_request(self, issuer: str, subject: str, email: str) -> AccessRequest:
        existing = self.find_identity(issuer, subject)
        if existing:
            return existing
        item = AccessRequest(issuer=issuer.strip(), subject=subject.strip(), email=email.strip().lower(), status="pending")
        self.session.add(item)
        self.session.commit()
        self.session.refresh(item)
        return item

    def review_request(self, request_id: int, approve: bool, reviewer: str, role: str = "viewer") -> AccessRequest:
        item = self.session.get(AccessRequest, request_id)
        if item is None:
            raise KeyError("access request not found")
        if item.status != "pending":
            raise ValueError("request is not pending")
        item.status = "approved" if approve else "rejected"
        item.role = role if approve else None
        item.reviewed_at = utcnow()
        item.reviewed_by = reviewer
        self.session.commit()
        self.session.refresh(item)
        return item

    def list_pending(self) -> list[AccessRequest]:
        return list(self.session.scalars(select(AccessRequest).where(AccessRequest.status == "pending").order_by(AccessRequest.id)).all())

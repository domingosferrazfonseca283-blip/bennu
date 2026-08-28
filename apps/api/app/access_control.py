from dataclasses import dataclass
from datetime import datetime, timezone
import os

@dataclass(frozen=True)
class AccessRequest:
    request_id: str
    email: str
    status: str
    created_at: str
    reviewed_at: str | None = None
    reviewed_by: str | None = None

class PrivateAccessControl:
    """Owner-mediated access registry. Persistence should be backed by a DB in production."""
    def __init__(self, owner_email: str | None = None):
        self.owner_email = (owner_email or os.getenv("BENNU_OWNER_EMAIL", "")).strip().lower()
        self.requests: list[AccessRequest] = []

    def request(self, email: str) -> AccessRequest:
        email = email.strip().lower()
        if not email or "@" not in email:
            raise ValueError("valid email is required")
        if self.owner_email and email == self.owner_email:
            return AccessRequest("owner", email, "approved", datetime.now(timezone.utc).isoformat())
        existing = next((r for r in self.requests if r.email == email and r.status == "pending"), None)
        if existing:
            return existing
        item = AccessRequest(f"access-{len(self.requests) + 1}", email, "pending", datetime.now(timezone.utc).isoformat())
        self.requests.append(item)
        return item

    def review(self, request_id: str, approve: bool, reviewer: str) -> AccessRequest:
        for i, item in enumerate(self.requests):
            if item.request_id == request_id:
                if item.status != "pending":
                    raise ValueError("request is not pending")
                updated = AccessRequest(item.request_id, item.email, "approved" if approve else "rejected", item.created_at, datetime.now(timezone.utc).isoformat(), reviewer)
                self.requests[i] = updated
                return updated
        raise KeyError("access request not found")

    def pending(self) -> list[AccessRequest]:
        return [r for r in self.requests if r.status == "pending"]

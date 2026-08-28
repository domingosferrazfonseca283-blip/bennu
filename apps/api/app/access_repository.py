from dataclasses import dataclass
from datetime import datetime, timezone
from threading import RLock

@dataclass(frozen=True)
class StoredOwner:
    issuer: str
    subject: str
    verified_email: str
    created_at: str

@dataclass(frozen=True)
class StoredAccessRequest:
    request_id: str
    issuer: str
    subject: str
    email: str
    status: str
    created_at: str
    reviewed_at: str | None = None
    reviewed_by: str | None = None
    role: str | None = None

class AccessRepository:
    """Persistence contract with a thread-safe local implementation.

    The interface is deliberately storage-agnostic so production can replace
    this implementation with SQLite/PostgreSQL without changing auth policy.
    """
    def __init__(self):
        self._lock = RLock()
        self._owner: StoredOwner | None = None
        self._requests: dict[str, StoredAccessRequest] = {}

    def get_owner(self) -> StoredOwner | None:
        with self._lock:
            return self._owner

    def create_owner(self, issuer: str, subject: str, verified_email: str) -> StoredOwner:
        with self._lock:
            if self._owner is not None:
                raise RuntimeError("owner is already initialized")
            owner = StoredOwner(issuer.strip(), subject.strip(), verified_email.strip().lower(), datetime.now(timezone.utc).isoformat())
            self._owner = owner
            return owner

    def find_request(self, request_id: str) -> StoredAccessRequest | None:
        with self._lock:
            return self._requests.get(request_id)

    def find_pending_identity(self, issuer: str, subject: str) -> StoredAccessRequest | None:
        with self._lock:
            return next((r for r in self._requests.values() if r.issuer == issuer and r.subject == subject and r.status == "pending"), None)

    def create_request(self, issuer: str, subject: str, email: str) -> StoredAccessRequest:
        with self._lock:
            existing = self.find_pending_identity(issuer, subject)
            if existing:
                return existing
            request_id = f"access-{len(self._requests) + 1}"
            item = StoredAccessRequest(request_id, issuer, subject, email.strip().lower(), "pending", datetime.now(timezone.utc).isoformat())
            self._requests[request_id] = item
            return item

    def review_request(self, request_id: str, approve: bool, reviewer: str, role: str = "viewer") -> StoredAccessRequest:
        with self._lock:
            item = self._requests.get(request_id)
            if item is None:
                raise KeyError("access request not found")
            if item.status != "pending":
                raise ValueError("request is not pending")
            updated = StoredAccessRequest(item.request_id, item.issuer, item.subject, item.email, "approved" if approve else "rejected", item.created_at, datetime.now(timezone.utc).isoformat(), reviewer, role if approve else None)
            self._requests[request_id] = updated
            return updated

    def list_pending(self) -> list[StoredAccessRequest]:
        with self._lock:
            return [r for r in self._requests.values() if r.status == "pending"]

    def get_identity(self, issuer: str, subject: str) -> StoredAccessRequest | None:
        with self._lock:
            return next((r for r in self._requests.values() if r.issuer == issuer and r.subject == subject), None)

from dataclasses import dataclass
from datetime import datetime, timezone

@dataclass(frozen=True)
class OwnerIdentity:
    issuer: str
    subject: str
    verified_email: str
    created_at: str

class OwnerBootstrap:
    """One-time owner binding. Store the identity in durable protected storage in production."""
    def __init__(self):
        self.owner: OwnerIdentity | None = None

    @property
    def initialized(self) -> bool:
        return self.owner is not None

    def initialize(self, issuer: str, subject: str, verified_email: str) -> OwnerIdentity:
        if self.owner is not None:
            raise RuntimeError("owner is already initialized")
        if not issuer.strip() or not subject.strip() or not verified_email.strip() or "@" not in verified_email:
            raise ValueError("verified identity is required")
        self.owner = OwnerIdentity(issuer.strip(), subject.strip(), verified_email.strip().lower(), datetime.now(timezone.utc).isoformat())
        return self.owner

    def is_owner(self, issuer: str, subject: str) -> bool:
        return bool(self.owner and self.owner.issuer == issuer and self.owner.subject == subject)

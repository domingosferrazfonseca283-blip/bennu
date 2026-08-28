from dataclasses import dataclass
import os
from fastapi import Header, HTTPException

@dataclass(frozen=True)
class Principal:
    subject: str
    role: str

# Development authentication is opt-in and must never be enabled in production.
DEMO_TOKENS = {
    "bennu-admin-dev": Principal("dev-admin", "admin"),
    "bennu-security-dev": Principal("dev-security", "security"),
    "bennu-operator-dev": Principal("dev-operator", "operator"),
    "bennu-developer-dev": Principal("dev-developer", "developer"),
    "bennu-viewer-dev": Principal("dev-viewer", "viewer"),
}


def _development_principal(token: str) -> Principal | None:
    if os.getenv("BENNU_DEV_AUTH", "false").lower() != "true":
        return None
    return DEMO_TOKENS.get(token)


def require_role(*allowed_roles: str):
    def dependency(authorization: str | None = Header(default=None)) -> Principal:
        token = authorization.removeprefix("Bearer ").strip() if authorization else ""
        principal = _development_principal(token)
        if principal is None:
            # Production integration point: a verified OIDC/JWT identity must be
            # converted to a server-side Principal before role authorization.
            raise HTTPException(status_code=401, detail="Verified authentication required")
        if principal.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient role")
        return principal
    return dependency

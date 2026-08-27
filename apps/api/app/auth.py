from dataclasses import dataclass
from fastapi import Header, HTTPException

@dataclass(frozen=True)
class Principal:
    subject: str
    role: str

# Development identity hook. Production must replace this with OIDC/JWT verification.
# Supported demo tokens are intentionally non-secret and only suitable for local development.
DEMO_TOKENS = {
    "bennu-admin-dev": Principal("dev-admin", "admin"),
    "bennu-security-dev": Principal("dev-security", "security"),
    "bennu-operator-dev": Principal("dev-operator", "operator"),
    "bennu-developer-dev": Principal("dev-developer", "developer"),
    "bennu-viewer-dev": Principal("dev-viewer", "viewer"),
}

def require_role(*allowed_roles: str):
    def dependency(authorization: str | None = Header(default=None), x_bennu_role: str | None = Header(default=None)) -> Principal:
        token = authorization.removeprefix("Bearer ").strip() if authorization else ""
        principal = DEMO_TOKENS.get(token)
        if principal is None and x_bennu_role in allowed_roles:
            # Backward-compatible local development path only.
            principal = Principal("dev-user", x_bennu_role)
        if principal is None:
            raise HTTPException(status_code=401, detail="Authentication required")
        if principal.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient role")
        return principal
    return dependency

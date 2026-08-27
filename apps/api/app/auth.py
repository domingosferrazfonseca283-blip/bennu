from dataclasses import dataclass
from fastapi import Header, HTTPException

@dataclass(frozen=True)
class Principal:
    subject: str
    role: str

# Development-only identity hook. Production will replace this with OIDC/JWT verification.
def require_role(*allowed_roles: str):
    def dependency(x_bennu_role: str | None = Header(default=None)) -> Principal:
        role = x_bennu_role or "viewer"
        if role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient role")
        return Principal(subject="dev-user", role=role)
    return dependency

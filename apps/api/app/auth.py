from dataclasses import dataclass
import os
from fastapi import Depends, Header, HTTPException
import jwt
from jwt import PyJWKClient
from .access_repository import AccessRepository

@dataclass(frozen=True)
class Principal:
    subject: str
    role: str
    issuer: str
    email: str


def verify_identity(token: str) -> Principal:
    issuer = os.getenv("BENNU_OIDC_ISSUER", "").strip().rstrip("/")
    audience = os.getenv("BENNU_OIDC_AUDIENCE", "").strip()
    jwks_url = os.getenv("BENNU_OIDC_JWKS_URL", "").strip() or (f"{issuer}/.well-known/jwks.json" if issuer else "")
    if not issuer or not audience:
        raise HTTPException(status_code=503, detail="OIDC is not configured")
    try:
        signing_key = PyJWKClient(jwks_url).get_signing_key_from_jwt(token).key
        claims = jwt.decode(
            token,
            signing_key,
            algorithms=["RS256", "RS384", "RS512", "ES256", "ES384", "ES512"],
            audience=audience,
            issuer=issuer,
        )
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid identity token") from exc
    subject = str(claims.get("sub", "")).strip()
    email = str(claims.get("email", "")).strip().lower()
    if not subject or not email or claims.get("email_verified") is not True:
        raise HTTPException(status_code=401, detail="Verified subject and email are required")
    return Principal(subject, "unassigned", issuer, email)


def current_identity(authorization: str | None = Header(default=None)) -> Principal:
    token = authorization.removeprefix("Bearer ").strip() if authorization else ""
    if not token:
        raise HTTPException(status_code=401, detail="Authentication required")
    return verify_identity(token)


def authorize(principal: Principal) -> Principal:
    repo = AccessRepository()
    try:
        owner = repo.get_owner()
        configured_owner_email = os.getenv("BENNU_OWNER_EMAIL", "").strip().lower()
        if owner is None and configured_owner_email and principal.email == configured_owner_email:
            try:
                owner = repo.create_owner(principal.issuer, principal.subject, principal.email)
            except RuntimeError:
                owner = repo.get_owner()
        if owner and owner.issuer == principal.issuer and owner.subject == principal.subject:
            return Principal(principal.subject, "admin", principal.issuer, principal.email)
        request = repo.find_identity(principal.issuer, principal.subject)
        if request and request.status == "approved" and request.role:
            return Principal(principal.subject, request.role, principal.issuer, principal.email)
        if request and request.status == "rejected":
            raise HTTPException(status_code=403, detail="Access rejected")
        raise HTTPException(status_code=403, detail="Access approval required")
    finally:
        repo.close()


def require_role(*allowed_roles: str):
    def dependency(principal: Principal = Depends(current_identity)) -> Principal:
        principal = authorize(principal)
        if principal.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient role")
        return principal
    return dependency

from dataclasses import dataclass
import os
from fastapi import Header, HTTPException
import jwt
from jwt import PyJWKClient
from .access_repository import AccessRepository

@dataclass(frozen=True)
class Principal:
    subject: str
    role: str
    issuer: str
    email: str

DEMO_TOKENS = {
    "bennu-admin-dev": Principal("dev-admin", "admin", "dev", "dev-admin@localhost"),
}


def _development_principal(token: str) -> Principal | None:
    if os.getenv("BENNU_DEV_AUTH", "false").lower() != "true":
        return None
    return DEMO_TOKENS.get(token)


def verify_identity(token: str) -> Principal:
    issuer = os.getenv("BENNU_OIDC_ISSUER", "").strip().rstrip("/")
    audience = os.getenv("BENNU_OIDC_AUDIENCE", "").strip()
    jwks_url = os.getenv("BENNU_OIDC_JWKS_URL", "").strip() or (f"{issuer}/.well-known/jwks.json" if issuer else "")
    if not issuer or not audience:
        raise HTTPException(status_code=503, detail="OIDC is not configured")
    try:
        signing_key = PyJWKClient(jwks_url).get_signing_key_from_jwt(token).key
        claims = jwt.decode(token, signing_key, algorithms=["RS256", "RS384", "RS512", "ES256", "ES384", "ES512"], audience=audience, issuer=issuer)
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid identity token") from exc
    subject = str(claims.get("sub", "")).strip()
    email = str(claims.get("email", "")).strip().lower()
    if not subject or not email or claims.get("email_verified") is not True:
        raise HTTPException(status_code=401, detail="Verified subject and email are required")
    return Principal(subject, "unassigned", issuer, email)


def _authorize(identity: Principal) -> Principal:
    repo = AccessRepository()
    try:
        owner = repo.get_owner()
        if owner and owner.issuer == identity.issuer and owner.subject == identity.subject:
            return Principal(identity.subject, "admin", identity.issuer, identity.email)
        request = repo.find_identity(identity.issuer, identity.subject)
        if request and request.status == "approved" and request.role:
            return Principal(identity.subject, request.role, identity.issuer, identity.email)
        if request and request.status == "rejected":
            raise HTTPException(status_code=403, detail="Access rejected")
        raise HTTPException(status_code=403, detail="Access approval required")
    finally:
        repo.close()


def current_identity(authorization: str | None = Header(default=None)) -> Principal:
    token = authorization.removeprefix("Bearer ").strip() if authorization else ""
    if not token:
        raise HTTPException(status_code=401, detail="Authentication required")
    demo = _development_principal(token)
    if demo:
        return demo
    return _authorize(verify_identity(token))


def require_role(*allowed_roles: str):
    def dependency(principal: Principal = __import__("fastapi").Depends(current_identity)) -> Principal:
        if principal.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient role")
        return principal
    return dependency

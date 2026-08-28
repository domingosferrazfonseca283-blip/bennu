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


def _verified_principal(token: str) -> Principal:
    issuer = os.getenv("BENNU_OIDC_ISSUER", "").strip().rstrip("/")
    audience = os.getenv("BENNU_OIDC_AUDIENCE", "").strip()
    jwks_url = os.getenv("BENNU_OIDC_JWKS_URL", "").strip()
    if not issuer or not audience:
        raise HTTPException(status_code=503, detail="OIDC is not configured")
    if not jwks_url:
        jwks_url = f"{issuer}/.well-known/jwks.json"
    try:
        signing_key = PyJWKClient(jwks_url).get_signing_key_from_jwt(token).key
        claims = jwt.decode(token, signing_key, algorithms=["RS256", "RS384", "RS512", "ES256", "ES384", "ES512"], audience=audience, issuer=issuer)
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid identity token") from exc
    subject = str(claims.get("sub", "")).strip()
    email = str(claims.get("email", "")).strip().lower()
    email_verified = claims.get("email_verified") is True
    if not subject or not email or not email_verified:
        raise HTTPException(status_code=401, detail="Verified subject and email are required")
    repo = AccessRepository()
    try:
        owner = repo.get_owner()
        if owner and owner.issuer == issuer and owner.subject == subject:
            return Principal(subject, "admin", issuer, email)
        identity = repo.find_identity(issuer, subject)
        if identity and identity.status == "approved" and identity.role:
            return Principal(subject, identity.role, issuer, email)
        if identity and identity.status == "rejected":
            raise HTTPException(status_code=403, detail="Access rejected")
        raise HTTPException(status_code=403, detail="Access approval required")
    finally:
        repo.close()


def require_role(*allowed_roles: str):
    def dependency(authorization: str | None = Header(default=None)) -> Principal:
        token = authorization.removeprefix("Bearer ").strip() if authorization else ""
        if not token:
            raise HTTPException(status_code=401, detail="Authentication required")
        principal = _development_principal(token) or _verified_principal(token)
        if principal.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient role")
        return principal
    return dependency

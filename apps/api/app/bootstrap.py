"""One-time bootstrap for the Bennu private owner identity.

The owner email is configuration, not a credential. A real OIDC token with a
verified email is still required at login.
"""
import os
from .access_repository import AccessRepository

DEFAULT_OWNER_EMAIL = "domingosferrazfonseca283@gmail.com"


def bootstrap_owner() -> None:
    email = os.getenv("BENNU_OWNER_EMAIL", DEFAULT_OWNER_EMAIL).strip().lower()
    if not email:
        raise RuntimeError("BENNU_OWNER_EMAIL must not be empty")
    repo = AccessRepository()
    try:
        if repo.get_owner() is None:
            # The subject/issuer are intentionally not guessed from an email.
            # They must be bound after the first verified OIDC login.
            return
    finally:
        repo.close()

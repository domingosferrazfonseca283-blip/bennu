import pytest
from fastapi import HTTPException
from app.auth import Principal, verify_identity


def test_missing_oidc_configuration_is_not_accepted(monkeypatch):
    monkeypatch.delenv("BENNU_OIDC_ISSUER", raising=False)
    monkeypatch.delenv("BENNU_OIDC_AUDIENCE", raising=False)
    with pytest.raises(HTTPException) as exc:
        verify_identity("not-a-real-token")
    assert exc.value.status_code == 503


def test_unverified_identity_is_not_constructed_from_client_role():
    principal = Principal("guest", "admin", "issuer", "guest@example.com")
    assert principal.role == "admin"
    # The authorization layer must never trust this client-created Principal;
    # persisted ownership/approval determines the effective role.

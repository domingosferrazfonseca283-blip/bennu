import pytest
from fastapi import HTTPException
from app.access_api import configured_owner_email


def test_configured_owner_email_is_normalized(monkeypatch):
    monkeypatch.setenv("BENNU_OWNER_EMAIL", " DomingosFerrazFonseca283@gmail.com ")
    assert configured_owner_email() == "domingosferrazfonseca283@gmail.com"


def test_owner_bootstrap_requires_configured_identity(monkeypatch):
    monkeypatch.setenv("BENNU_OWNER_EMAIL", "owner@example.com")
    assert configured_owner_email() == "owner@example.com"

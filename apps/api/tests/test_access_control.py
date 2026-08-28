import os
import tempfile

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.models import Base
from app.access_repository import AccessRepository


def test_owner_and_access_lifecycle():
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    try:
        engine = create_engine(f"sqlite:///{path}")
        Base.metadata.create_all(engine)
        Session = sessionmaker(bind=engine)
        with Session() as session:
            repo = AccessRepository(session)
            owner = repo.create_owner("https://issuer.example", "owner-1", "Owner@example.com")
            assert owner.verified_email == "owner@example.com"
            with pytest.raises(RuntimeError):
                repo.create_owner("https://issuer.example", "owner-2", "other@example.com")

            request = repo.create_request("https://issuer.example", "user-1", "user@example.com")
            assert request.status == "pending"
            assert repo.create_request("https://issuer.example", "user-1", "user@example.com").id == request.id

            approved = repo.review_request(request.id, True, "owner-1", "viewer")
            assert approved.status == "approved"
            assert approved.role == "viewer"

            with pytest.raises(ValueError):
                repo.review_request(request.id, True, "owner-1", "viewer")

            rejected = repo.create_request("https://issuer.example", "user-2", "user2@example.com")
            rejected = repo.review_request(rejected.id, False, "owner-1")
            assert rejected.status == "rejected"
            renewed = repo.create_request("https://issuer.example", "user-2", "user2@example.com")
            assert renewed.status == "pending"
    finally:
        os.unlink(path)

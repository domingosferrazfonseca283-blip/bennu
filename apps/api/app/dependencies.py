from collections.abc import Generator
from sqlalchemy.orm import Session
from .db import SessionLocal


def db() -> Generator[Session, None, None]:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

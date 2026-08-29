from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from threading import RLock
from typing import Any, Callable
from uuid import uuid4


@dataclass(frozen=True)
class OperationalEvent:
    """Immutable event exchanged between Bennu core modules."""

    event_id: str
    event_type: str
    source: str
    timestamp: str
    payload: dict[str, Any] = field(default_factory=dict)


EventHandler = Callable[[OperationalEvent], None]


class EventBus:
    """Small in-process event bus; external brokers can be added behind this boundary."""

    def __init__(self) -> None:
        self._events: list[OperationalEvent] = []
        self._handlers: dict[str, list[EventHandler]] = {}
        self._lock = RLock()

    def publish(
        self,
        event_type: str,
        source: str,
        payload: dict[str, Any] | None = None,
    ) -> OperationalEvent:
        event = OperationalEvent(
            event_id=str(uuid4()),
            event_type=event_type,
            source=source,
            timestamp=datetime.now(timezone.utc).isoformat(),
            payload=dict(payload or {}),
        )
        with self._lock:
            self._events.append(event)
            handlers = tuple(self._handlers.get(event_type, ()))
            wildcard = tuple(self._handlers.get("*", ()))
        for handler in handlers + wildcard:
            handler(event)
        return event

    def subscribe(self, event_type: str, handler: EventHandler) -> None:
        with self._lock:
            self._handlers.setdefault(event_type, []).append(handler)

    def recent(self, limit: int = 100) -> list[OperationalEvent]:
        if limit < 0:
            raise ValueError("limit must be non-negative")
        with self._lock:
            return list(self._events[-limit:])

    def count(self) -> int:
        with self._lock:
            return len(self._events)

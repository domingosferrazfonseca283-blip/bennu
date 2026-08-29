from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from threading import RLock
from typing import Any, Callable
from uuid import uuid4


@dataclass(frozen=True)
class OperationalEvent:
    event_id: str
    event_type: str
    source: str
    timestamp: str
    payload: dict[str, Any] = field(default_factory=dict)


EventHandler = Callable[[OperationalEvent], None]


class EventBus:
    def __init__(self) -> None:
        self._events: list[OperationalEvent] = []
        self._handlers: dict[str, list[EventHandler]] = {}
        self._lock = RLock()

    def publish(self, event_type: str, source: str, payload: dict[str, Any] | None = None) -> OperationalEvent:
        event = OperationalEvent(str(uuid4()), event_type, source, datetime.now(timezone.utc).isoformat(), dict(payload or {}))
        with self._lock:
            self._events.append(event)
            handlers = tuple(self._handlers.get(event_type, ())) + tuple(self._handlers.get("*", ()))
        for handler in handlers:
            handler(event)
        return event

    def subscribe(self, event_type: str, handler: EventHandler) -> None:
        with self._lock:
            self._handlers.setdefault(event_type, []).append(handler)

    def recent(self, limit: int = 50) -> list[OperationalEvent]:
        if limit < 0:
            raise ValueError("limit must be non-negative")
        with self._lock:
            return list(self._events[-limit:])

    def count(self) -> int:
        with self._lock:
            return len(self._events)

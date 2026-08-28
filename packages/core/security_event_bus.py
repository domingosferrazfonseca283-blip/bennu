from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Callable

@dataclass(frozen=True)
class SecurityEvent:
    event_id: str
    event_type: str
    source: str
    severity: str
    asset: str
    confidence: float
    timestamp: str
    metadata: dict[str, Any] = field(default_factory=dict)

class SecurityEventBus:
    def __init__(self):
        self.events: list[SecurityEvent] = []
        self.subscribers: list[Callable[[SecurityEvent], None]] = []

    def publish(self, event: SecurityEvent) -> SecurityEvent:
        if not 0 <= event.confidence <= 1:
            raise ValueError("confidence must be between 0 and 1")
        self.events.append(event)
        for subscriber in tuple(self.subscribers):
            subscriber(event)
        return event

    def subscribe(self, handler: Callable[[SecurityEvent], None]) -> None:
        self.subscribers.append(handler)

    def recent(self, limit: int = 100) -> list[SecurityEvent]:
        return self.events[-max(0, limit):]

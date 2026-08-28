from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from typing import Literal

Severity = Literal["info", "low", "medium", "high", "critical"]

@dataclass
class SecurityEvent:
    event_id: str
    event_type: str
    severity: Severity
    source: str
    resource: str
    message: str
    timestamp: str

class SecurityEventStore:
    """Structured security-event boundary for future SOC/IDS integrations."""
    def __init__(self):
        self.events: list[SecurityEvent] = []

    def emit(self, event_id: str, event_type: str, severity: Severity, source: str, resource: str, message: str) -> SecurityEvent:
        event = SecurityEvent(event_id, event_type, severity, source, resource, message, datetime.now(timezone.utc).isoformat())
        self.events.append(event)
        return event

    def list(self, severity: Severity | None = None):
        events = self.events if severity is None else [e for e in self.events if e.severity == severity]
        return [asdict(e) for e in reversed(events)]

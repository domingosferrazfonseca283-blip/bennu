from dataclasses import dataclass
from datetime import datetime, timezone
from packages.core.security_alert_engine import SecurityAlert

@dataclass(frozen=True)
class SecurityIncident:
    incident_id: str
    alert_ids: tuple[str, ...]
    title: str
    severity: str
    status: str
    created_at: str
    owner: str | None = None

class IncidentManager:
    def __init__(self):
        self.incidents: list[SecurityIncident] = []

    def create(self, alert: SecurityAlert, title: str | None = None) -> SecurityIncident:
        incident = SecurityIncident(
            incident_id=f"incident-{len(self.incidents) + 1}",
            alert_ids=(alert.alert_id,),
            title=title or f"Security incident from {alert.alert_id}",
            severity=alert.level,
            status="open",
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        self.incidents.append(incident)
        return incident

    def assign(self, incident_id: str, owner: str) -> SecurityIncident:
        for i, incident in enumerate(self.incidents):
            if incident.incident_id == incident_id:
                updated = SecurityIncident(**{**incident.__dict__, "owner": owner})
                self.incidents[i] = updated
                return updated
        raise KeyError("incident not found")

    def resolve(self, incident_id: str) -> SecurityIncident:
        for i, incident in enumerate(self.incidents):
            if incident.incident_id == incident_id:
                if incident.status == "resolved":
                    raise ValueError("incident already resolved")
                updated = SecurityIncident(**{**incident.__dict__, "status": "resolved"})
                self.incidents[i] = updated
                return updated
        raise KeyError("incident not found")

    def open_incidents(self) -> list[SecurityIncident]:
        return [i for i in self.incidents if i.status == "open"]

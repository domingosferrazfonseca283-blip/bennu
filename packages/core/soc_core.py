from dataclasses import dataclass
from packages.core.security_alert_engine import SecurityAlertEngine, SecurityAlert
from packages.core.security_event_bus import SecurityEvent, SecurityEventBus
from packages.core.security_risk_engine import RiskAssessment, SecurityRiskEngine
from packages.core.incident_manager import IncidentManager, SecurityIncident

@dataclass(frozen=True)
class SOCResult:
    assessment: RiskAssessment
    alert: SecurityAlert | None
    incident: SecurityIncident | None

class SOCCore:
    """Defensive SOC pipeline: event -> risk -> alert -> incident."""
    def __init__(self, bus: SecurityEventBus | None = None):
        self.bus = bus or SecurityEventBus()
        self.risk = SecurityRiskEngine()
        self.alerts = SecurityAlertEngine()
        self.incidents = IncidentManager()
        self.results: list[SOCResult] = []
        self.bus.subscribe(self.handle_event)

    def handle_event(self, event: SecurityEvent) -> SOCResult:
        assessment = self.risk.assess(event)
        alert = self.alerts.process(assessment)
        incident = self.incidents.create(alert) if alert else None
        result = SOCResult(assessment, alert, incident)
        self.results.append(result)
        return result

    def overview(self) -> dict:
        return {
            "events": len(self.bus.events),
            "open_alerts": len(self.alerts.open_alerts()),
            "open_incidents": len(self.incidents.open_incidents()),
            "latest_risk": self.results[-1].assessment.score if self.results else 0,
        }

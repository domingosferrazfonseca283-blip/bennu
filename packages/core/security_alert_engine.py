from dataclasses import dataclass
from datetime import datetime, timezone
from packages.core.security_risk_engine import RiskAssessment

@dataclass(frozen=True)
class SecurityAlert:
    alert_id: str
    event_id: str
    score: int
    level: str
    status: str
    created_at: str
    acknowledged_by: str | None = None
    acknowledged_at: str | None = None

class SecurityAlertEngine:
    def __init__(self, minimum_level: str = "HIGH"):
        levels = {"LOW": 0, "MEDIUM": 25, "HIGH": 50, "CRITICAL": 75}
        if minimum_level not in levels:
            raise ValueError("invalid minimum level")
        self.minimum_score = levels[minimum_level]
        self.alerts: list[SecurityAlert] = []

    def process(self, assessment: RiskAssessment) -> SecurityAlert | None:
        if assessment.score < self.minimum_score:
            return None
        alert = SecurityAlert(
            alert_id=f"alert-{len(self.alerts) + 1}",
            event_id=assessment.event_id,
            score=assessment.score,
            level=assessment.level,
            status="open",
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        self.alerts.append(alert)
        return alert

    def acknowledge(self, alert_id: str, reviewer: str) -> SecurityAlert:
        for i, alert in enumerate(self.alerts):
            if alert.alert_id == alert_id:
                if alert.status != "open":
                    raise ValueError("alert is not open")
                updated = SecurityAlert(
                    **{**alert.__dict__, "status": "acknowledged", "acknowledged_by": reviewer,
                       "acknowledged_at": datetime.now(timezone.utc).isoformat()}
                )
                self.alerts[i] = updated
                return updated
        raise KeyError("alert not found")

    def open_alerts(self) -> list[SecurityAlert]:
        return [a for a in self.alerts if a.status == "open"]

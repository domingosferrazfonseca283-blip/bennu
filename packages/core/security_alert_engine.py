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

class SecurityAlertEngine:
    def __init__(self, minimum_level: str = "HIGH"):
        self.minimum_score = {"LOW": 0, "MEDIUM": 25, "HIGH": 50, "CRITICAL": 75}[minimum_level]
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

    def open_alerts(self) -> list[SecurityAlert]:
        return [a for a in self.alerts if a.status == "open"]

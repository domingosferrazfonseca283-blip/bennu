from dataclasses import dataclass
from packages.core.security_events import SecurityEvent, Severity

WEIGHTS: dict[Severity, int] = {"info": 0, "low": 10, "medium": 25, "high": 50, "critical": 80}

@dataclass
class RiskAssessment:
    score: int
    level: str
    event_count: int

class RiskEngine:
    """Deterministic, explainable risk scoring; it only assesses and never auto-remediates."""
    def assess(self, events: list[SecurityEvent]) -> RiskAssessment:
        score = min(100, sum(WEIGHTS[e.severity] for e in events))
        if score >= 80: level = "critical"
        elif score >= 50: level = "high"
        elif score >= 25: level = "medium"
        elif score > 0: level = "low"
        else: level = "normal"
        return RiskAssessment(score, level, len(events))

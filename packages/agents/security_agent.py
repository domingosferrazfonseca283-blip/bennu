from dataclasses import dataclass
from .engine import Action, AgentEngine, Decision

@dataclass
class SecurityAgent:
    name: str = "Bennu Security Agent"
    autonomy_level: int = 2

    def plan_scan(self, target: str) -> dict:
        action = Action(name="authorized_security_scan", risk="medium")
        decision: Decision = AgentEngine().evaluate(self.autonomy_level, action)
        return {
            "agent": self.name,
            "target": target,
            "decision": decision.__dict__,
            "next_step": "approval_required" if decision.requires_approval else "ready",
        }

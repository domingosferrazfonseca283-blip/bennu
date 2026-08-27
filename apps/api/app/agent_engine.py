from dataclasses import dataclass
from .policy import can_execute

@dataclass
class AgentDecision:
    action: str
    allowed: bool
    reason: str

class AgentEngine:
    """Safe v0.1 planner: produces decisions but never executes arbitrary commands."""
    def decide(self, action: str, autonomy: int) -> AgentDecision:
        allowed = can_execute(action, autonomy)
        return AgentDecision(action, allowed, "policy-allowed" if allowed else "approval-required")

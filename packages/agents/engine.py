from dataclasses import dataclass
from enum import IntEnum

class Autonomy(IntEnum):
    READ_ONLY = 0
    SUGGEST = 1
    APPROVAL = 2
    LIMITED_AUTO = 3
    CONTROLLED_AUTO = 4

@dataclass(frozen=True)
class Action:
    name: str
    risk: str = "low"
    requires_approval: bool = False

@dataclass(frozen=True)
class Decision:
    allowed: bool
    requires_approval: bool
    reason: str

class PolicyEngine:
    def decide(self, autonomy: Autonomy, action: Action) -> Decision:
        if action.requires_approval:
            return Decision(False, True, "Action explicitly requires approval")
        if autonomy < Autonomy.LIMITED_AUTO:
            return Decision(False, True, "Agent autonomy is below automatic execution")
        if action.risk == "high" and autonomy < Autonomy.CONTROLLED_AUTO:
            return Decision(False, True, "High-risk actions require controlled autonomy")
        return Decision(True, False, "Action permitted by policy")

class AgentEngine:
    def __init__(self, policy: PolicyEngine | None = None):
        self.policy = policy or PolicyEngine()

    def evaluate(self, autonomy_level: int, action: Action) -> Decision:
        level = Autonomy(max(0, min(4, autonomy_level)))
        return self.policy.decide(level, action)

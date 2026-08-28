from dataclasses import dataclass
from enum import IntEnum

class Autonomy(IntEnum):
    READ_ONLY = 0
    SUGGEST = 1
    APPROVAL = 2
    LIMITED_AUTO = 3
    CONTROLLED_AUTO = 4

@dataclass(frozen=True)
class ActionPolicy:
    name: str
    risk: str = "low"
    requires_approval: bool = False
    authorized_scope_required: bool = False

@dataclass(frozen=True)
class PolicyDecision:
    allowed: bool
    requires_approval: bool
    reason: str

class PolicyEngine:
    def evaluate(self, autonomy: Autonomy, action: ActionPolicy, authorized_scope: bool = False) -> PolicyDecision:
        if action.authorized_scope_required and not authorized_scope:
            return PolicyDecision(False, True, "Authorized scope is required")
        if action.requires_approval:
            return PolicyDecision(False, True, "Action requires explicit approval")
        if autonomy < Autonomy.LIMITED_AUTO:
            return PolicyDecision(False, True, "Agent autonomy is below automatic execution")
        if action.risk == "high" and autonomy < Autonomy.CONTROLLED_AUTO:
            return PolicyDecision(False, True, "High-risk actions require controlled autonomy")
        return PolicyDecision(True, False, "Action permitted by policy")

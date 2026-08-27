from dataclasses import dataclass
from .engine import Action, AgentEngine, Decision

@dataclass(frozen=True)
class SecurityPlan:
    target: str
    actions: tuple[Action, ...]

class SecurityAgent:
    role = "security"

    def __init__(self, engine: AgentEngine | None = None):
        self.engine = engine or AgentEngine()

    def plan(self, target: str) -> SecurityPlan:
        return SecurityPlan(
            target=target,
            actions=(
                Action("network_inventory", risk="medium", requires_approval=True),
                Action("vulnerability_scan", risk="high", requires_approval=True),
            ),
        )

    def evaluate(self, target: str, autonomy_level: int) -> list[Decision]:
        return [self.engine.evaluate(autonomy_level, action) for action in self.plan(target).actions]

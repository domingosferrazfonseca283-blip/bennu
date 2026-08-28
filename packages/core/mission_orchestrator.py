from dataclasses import dataclass
from packages.core.mission_engine import Mission
from packages.core.mission_agent_assignment import Assignment, MissionAgentAssignmentEngine

@dataclass(frozen=True)
class OrchestrationPlan:
    mission_id: str
    status: str
    assignments: tuple[Assignment, ...]

class MissionOrchestrator:
    """Plans mission execution through agent assignment; execution remains a separate gated step."""
    def __init__(self, assignment_engine: MissionAgentAssignmentEngine | None = None):
        self.assignment_engine = assignment_engine or MissionAgentAssignmentEngine()

    def plan(self, mission: Mission) -> OrchestrationPlan:
        assignments = tuple(self.assignment_engine.assign(mission))
        status = "approval-required" if any(a.decision.requires_approval for a in assignments) else "ready"
        return OrchestrationPlan(mission.id, status, assignments)

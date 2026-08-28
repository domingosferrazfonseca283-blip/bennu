from dataclasses import asdict
from uuid import uuid4
from packages.core.default_agents import create_default_runtime
from packages.core.mission_engine import MissionEngine

class MissionService:
    """Plans missions through registered agents and leaves execution behind policy gates."""
    def __init__(self, engine: MissionEngine | None = None):
        self.engine = engine or MissionEngine()
        self.agents = create_default_runtime()

    def plan(self, objective: str):
        if not objective.strip():
            raise ValueError("objective is required")
        return self.engine.plan(str(uuid4()), objective.strip())

    def describe(self) -> dict:
        return {"agents": [asdict(agent) for agent in self.agents.agents.values()]}

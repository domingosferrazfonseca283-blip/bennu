from __future__ import annotations

from dataclasses import asdict
from typing import Any

from packages.core.agent_runtime import AgentRuntime
from packages.core.default_agents import create_default_runtime
from packages.core.event_bus import EventBus, OperationalEvent
from packages.core.mission_engine import MissionEngine
from packages.core.mission_orchestrator import MissionOrchestrator


class OperationalRuntime:
    """Coordinates mission planning and agent assignment without bypassing execution gates."""

    def __init__(self, event_bus: EventBus | None = None, agent_runtime: AgentRuntime | None = None, mission_engine: MissionEngine | None = None, orchestrator: MissionOrchestrator | None = None) -> None:
        self.events = event_bus or EventBus()
        self.agents = agent_runtime or create_default_runtime()
        self.missions = mission_engine or MissionEngine()
        self.orchestrator = orchestrator or MissionOrchestrator()

    def plan_mission(self, objective: str, mission_id: str) -> dict[str, Any]:
        objective = objective.strip()
        mission_id = mission_id.strip()
        if not objective or not mission_id:
            raise ValueError("mission_id and objective are required")
        mission = self.missions.plan(mission_id, objective)
        plan = self.orchestrator.plan(mission)
        event = self.events.publish("mission.planned", "operational-runtime", {
            "mission_id": mission.id,
            "objective": mission.objective,
            "status": plan.status,
            "assignments": [
                {"task_id": a.task_id, "agent_id": a.agent_id, "role": a.role, "action": a.decision.action, "requires_approval": a.decision.requires_approval}
                for a in plan.assignments
            ],
        })
        return {"mission": asdict(mission), "plan": asdict(plan), "event_id": event.event_id}

    def status(self) -> dict[str, Any]:
        return {"runtime": "online", "agents": len(self.agents.agents), "events": self.events.count(), "missions": len(self.missions.store.list_missions())}

    def recent_events(self, limit: int = 50) -> list[OperationalEvent]:
        return self.events.recent(limit)

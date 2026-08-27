from dataclasses import dataclass, field
from typing import Literal

MissionStatus = Literal["planned", "approval-required", "approved", "running", "completed", "failed"]

@dataclass
class MissionTask:
    id: str
    title: str
    agent_role: str
    risk: Literal["low", "medium", "high"] = "low"
    status: MissionStatus = "planned"

@dataclass
class Mission:
    id: str
    objective: str
    status: MissionStatus
    tasks: list[MissionTask] = field(default_factory=list)

class MissionEngine:
    """Turns natural-language objectives into a reviewable execution plan.

    v0.1 is intentionally planning-only: it never executes tools or grants
    permissions. High-risk tasks always require explicit approval.
    """
    def plan(self, mission_id: str, objective: str) -> Mission:
        text = objective.lower()
        tasks: list[MissionTask] = []
        if any(word in text for word in ("loja", "ecommerce", "site", "website")):
            tasks = [
                MissionTask("design", "Define application architecture", "developer"),
                MissionTask("build", "Build initial application", "developer", "medium"),
                MissionTask("security", "Review application security", "security", "medium"),
                MissionTask("deploy", "Prepare deployment plan", "developer", "high"),
            ]
        elif any(word in text for word in ("scan", "vulnerabil", "segurança", "security")):
            tasks = [
                MissionTask("scope", "Validate authorized scope", "security"),
                MissionTask("audit", "Run authorized security assessment", "security", "high"),
                MissionTask("report", "Generate remediation report", "security"),
            ]
        else:
            tasks = [MissionTask("analyze", "Analyze objective and propose next steps", "ceo")]
        status: MissionStatus = "approval-required" if any(t.risk == "high" for t in tasks) else "planned"
        if status == "approval-required":
            for task in tasks:
                if task.risk == "high": task.status = "approval-required"
        return Mission(mission_id, objective, status, tasks)

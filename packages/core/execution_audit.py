from dataclasses import dataclass
from datetime import datetime, timezone
from packages.core.allowlisted_executor import ExecutionResult
from packages.core.execution_gate import ExecutionPermit

@dataclass(frozen=True)
class ExecutionAuditEvent:
    approval_id: str
    mission_id: str
    agent_id: str
    action: str
    status: str
    message: str
    timestamp: str

class ExecutionAudit:
    def __init__(self):
        self.events: list[ExecutionAuditEvent] = []

    def record(self, permit: ExecutionPermit, result: ExecutionResult) -> ExecutionAuditEvent:
        event = ExecutionAuditEvent(permit.approval_id, permit.mission_id, permit.agent_id, permit.action, result.status, result.message, datetime.now(timezone.utc).isoformat())
        self.events.append(event)
        return event

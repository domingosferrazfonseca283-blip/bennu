from dataclasses import dataclass
from typing import Literal

ExecutionStatus = Literal["approved", "running", "completed", "blocked", "failed"]

@dataclass
class ExecutionResult:
    status: ExecutionStatus
    task_id: str
    output: str = ""
    reason: str | None = None

class SandboxExecutor:
    """Policy-aware execution boundary.

    v0.1 deliberately exposes no arbitrary shell/network execution. Callers
    must provide an approved task and an allow-listed operation name.
    """
    ALLOWED_OPERATIONS = {"noop", "health_check", "generate_report"}

    def execute(self, task_id: str, operation: str, approved: bool) -> ExecutionResult:
        if not approved:
            return ExecutionResult("blocked", task_id, reason="explicit approval required")
        if operation not in self.ALLOWED_OPERATIONS:
            return ExecutionResult("blocked", task_id, reason="operation is not allow-listed")
        if operation == "health_check":
            return ExecutionResult("completed", task_id, "sandbox health check passed")
        if operation == "generate_report":
            return ExecutionResult("completed", task_id, "report job accepted by sandbox")
        return ExecutionResult("completed", task_id, "no-op completed")

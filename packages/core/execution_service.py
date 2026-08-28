from dataclasses import dataclass
from packages.core.sandbox_executor import SandboxExecutor, ExecutionResult
from packages.core.persistence import JsonStore

@dataclass
class TaskExecution:
    task_id: str
    operation: str
    approved: bool = False
    result: ExecutionResult | None = None

class ExecutionService:
    """Joins approval state, sandbox execution and durable audit state."""
    def __init__(self, executor: SandboxExecutor | None = None, store: JsonStore | None = None):
        self.executor = executor or SandboxExecutor()
        self.store = store or JsonStore()
        self.tasks: dict[str, TaskExecution] = {}

    def register(self, task_id: str, operation: str) -> TaskExecution:
        task = TaskExecution(task_id, operation)
        self.tasks[task_id] = task
        self.store.save_execution(task)
        self.store.audit("system", "task.registered", task_id, {"operation": operation})
        return task

    def approve(self, task_id: str) -> TaskExecution:
        task = self.tasks[task_id]
        task.approved = True
        self.store.save_execution(task)
        self.store.audit("approval", "task.approved", task_id)
        return task

    def run(self, task_id: str) -> TaskExecution:
        task = self.tasks[task_id]
        task.result = self.executor.execute(task.task_id, task.operation, task.approved)
        self.store.save_execution(task)
        self.store.audit("executor", "task.executed", task_id, {"status": task.result.status, "reason": task.result.reason})
        return task

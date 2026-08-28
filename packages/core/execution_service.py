from dataclasses import dataclass
from packages.core.sandbox_executor import SandboxExecutor, ExecutionResult

@dataclass
class TaskExecution:
    task_id: str
    operation: str
    approved: bool = False
    result: ExecutionResult | None = None

class ExecutionService:
    """Application service joining approval state to the sandbox boundary."""
    def __init__(self, executor: SandboxExecutor | None = None):
        self.executor = executor or SandboxExecutor()
        self.tasks: dict[str, TaskExecution] = {}

    def register(self, task_id: str, operation: str) -> TaskExecution:
        task = TaskExecution(task_id, operation)
        self.tasks[task_id] = task
        return task

    def approve(self, task_id: str) -> TaskExecution:
        task = self.tasks[task_id]
        task.approved = True
        return task

    def run(self, task_id: str) -> TaskExecution:
        task = self.tasks[task_id]
        task.result = self.executor.execute(task.task_id, task.operation, task.approved)
        return task

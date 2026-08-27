from dataclasses import dataclass
from .tool_registry import ToolRegistry

@dataclass(frozen=True)
class ExecutionResult:
    status: str
    tool: str
    message: str

class SandboxedExecutor:
    """Safe execution boundary. v0.1 only executes registered read-only tools."""
    READ_ONLY_TOOLS = frozenset({"system_status", "git_read"})

    def __init__(self, registry: ToolRegistry):
        self.registry = registry

    def execute(self, tool_name: str, role: str) -> ExecutionResult:
        tool = self.registry.get(tool_name)
        if tool is None:
            return ExecutionResult("rejected", tool_name, "Tool is not registered")
        if not self.registry.can_use(tool_name, role):
            return ExecutionResult("rejected", tool_name, "Role is not authorized for this tool")
        if tool_name not in self.READ_ONLY_TOOLS:
            return ExecutionResult("approval-required", tool_name, "Execution is gated until a sandbox adapter is enabled")
        return ExecutionResult("completed", tool_name, "Read-only tool execution completed in the safe executor")

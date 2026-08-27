from dataclasses import dataclass
from typing import FrozenSet

@dataclass(frozen=True)
class ToolSpec:
    name: str
    description: str
    risk: str
    allowed_roles: FrozenSet[str]
    requires_approval: bool = True

class ToolRegistry:
    def __init__(self):
        self._tools: dict[str, ToolSpec] = {}

    def register(self, tool: ToolSpec) -> None:
        if tool.name in self._tools:
            raise ValueError(f"Tool already registered: {tool.name}")
        self._tools[tool.name] = tool

    def get(self, name: str) -> ToolSpec | None:
        return self._tools.get(name)

    def list(self) -> list[ToolSpec]:
        return list(self._tools.values())

    def can_use(self, tool_name: str, role: str) -> bool:
        tool = self.get(tool_name)
        return tool is not None and role in tool.allowed_roles


def default_registry() -> ToolRegistry:
    registry = ToolRegistry()
    registry.register(ToolSpec("system_status", "Read Bennu system status", "low", frozenset({"ceo", "security", "developer"}), False))
    registry.register(ToolSpec("network_inventory", "Read an authorized network inventory", "medium", frozenset({"security"}), True))
    registry.register(ToolSpec("vulnerability_scan", "Run a vulnerability scan against an explicitly authorized scope", "high", frozenset({"security"}), True))
    registry.register(ToolSpec("git_read", "Read repository metadata and files", "low", frozenset({"developer", "ceo"}), False))
    registry.register(ToolSpec("git_write", "Modify an authorized repository", "high", frozenset({"developer"}), True))
    return registry

from fastapi import APIRouter, HTTPException
from packages.agents.tool_registry import default_registry

router = APIRouter(prefix="/api/v1/tools", tags=["tools"])
registry = default_registry()

@router.get("")
def list_tools():
    return [
        {"name": t.name, "description": t.description, "risk": t.risk,
         "allowed_roles": sorted(t.allowed_roles), "requires_approval": t.requires_approval}
        for t in registry.list()
    ]

@router.get("/{tool_name}")
def get_tool(tool_name: str):
    tool = registry.get(tool_name)
    if not tool:
        raise HTTPException(status_code=404, detail="Tool not found")
    return {"name": tool.name, "description": tool.description, "risk": tool.risk,
            "allowed_roles": sorted(tool.allowed_roles), "requires_approval": tool.requires_approval}

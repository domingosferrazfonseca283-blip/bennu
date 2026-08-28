from fastapi import APIRouter, Depends
from apps.api.app.auth import Principal, require_role
from packages.core.security_events import SecurityEventStore, Severity

router = APIRouter(prefix="/api/v1/security", tags=["security"])
store = SecurityEventStore()

@router.get("/events")
def list_events(severity: Severity | None = None, principal: Principal = Depends(require_role("admin", "operator", "security"))):
    return {"items": store.list(severity)}

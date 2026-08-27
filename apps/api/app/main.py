from datetime import datetime, timezone
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Bennu Core", version="0.1.0")


class TaskRequest(BaseModel):
    command: str
    dry_run: bool = True


@app.get("/health")
def health():
    return {
        "status": "online",
        "service": "bennu-core",
        "version": "0.1.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/api/v1/system/status")
def system_status():
    return {
        "status": "online",
        "security_score": 100,
        "agents": 0,
        "tasks": 0,
        "mode": "safe",
    }


@app.post("/api/v1/tasks")
def create_task(request: TaskRequest):
    # v0.1 deliberately does not execute arbitrary commands.
    return {
        "accepted": True,
        "execution": "dry-run" if request.dry_run else "approval-required",
        "command": request.command,
        "message": "Task registered; execution policy is enforced by Bennu Core.",
    }

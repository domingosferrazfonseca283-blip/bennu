from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
import json

class JsonStore:
    """Small durable store for the prototype; PostgreSQL can replace this adapter."""
    def __init__(self, path: str = "data/bennu_state.json"):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists(): self._write({"missions": {}, "executions": {}, "audit": []})

    def _read(self): return json.loads(self.path.read_text())
    def _write(self, data): self.path.write_text(json.dumps(data, indent=2, ensure_ascii=False))

    def save_mission(self, mission):
        data = self._read(); data["missions"][mission.id] = asdict(mission); self._write(data)
        return mission

    def save_execution(self, execution):
        data = self._read(); data["executions"][execution.task_id] = asdict(execution); self._write(data)
        return execution

    def audit(self, actor: str, action: str, resource: str, details: dict | None = None):
        data = self._read(); data["audit"].append({"timestamp": datetime.now(timezone.utc).isoformat(), "actor": actor, "action": action, "resource": resource, "details": details or {}}); self._write(data)

    def list_missions(self): return list(self._read()["missions"].values())
    def get_mission(self, mission_id: str): return self._read()["missions"].get(mission_id)
    def list_executions(self): return list(self._read()["executions"].values())
    def get_execution(self, task_id: str): return self._read()["executions"].get(task_id)
    def list_audit(self): return list(reversed(self._read()["audit"]))

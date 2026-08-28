from packages.core.persistence import JsonStore

class MissionQuery:
    """Read-only query adapter for the Mission Board and operations APIs."""
    def __init__(self, store: JsonStore | None = None):
        self.store = store or JsonStore()

    def list_missions(self):
        return list(self.store._read().get("missions", {}).values())

    def get_mission(self, mission_id: str):
        return self.store._read().get("missions", {}).get(mission_id)

    def list_executions(self):
        return list(self.store._read().get("executions", {}).values())

    def get_execution(self, task_id: str):
        return self.store._read().get("executions", {}).get(task_id)

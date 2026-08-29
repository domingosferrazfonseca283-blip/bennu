from pathlib import Path

from packages.core.event_bus import EventBus
from packages.core.mission_engine import MissionEngine
from packages.core.operational_runtime import OperationalRuntime
from packages.core.persistence import JsonStore


def test_event_bus_dispatches_typed_events():
    bus = EventBus()
    received = []
    bus.subscribe("mission.planned", received.append)

    event = bus.publish("mission.planned", "test", {"mission_id": "m1"})

    assert event.event_type == "mission.planned"
    assert received == [event]
    assert bus.count() == 1


def test_runtime_plans_and_emits_mission(tmp_path: Path):
    store = JsonStore(str(tmp_path / "state.json"))
    runtime = OperationalRuntime(
        event_bus=EventBus(),
        mission_engine=MissionEngine(store),
    )

    result = runtime.plan_mission("criar uma loja ecommerce segura", "m1")

    assert result["mission"]["id"] == "m1"
    assert result["plan"]["mission_id"] == "m1"
    assert result["event_id"]
    assert runtime.status()["events"] == 1
    assert store.get_mission("m1")["objective"] == "criar uma loja ecommerce segura"

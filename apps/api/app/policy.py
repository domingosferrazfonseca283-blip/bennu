from enum import IntEnum

class Autonomy(IntEnum):
    READ_ONLY = 0
    SUGGEST = 1
    APPROVAL = 2
    LIMITED_AUTO = 3
    CONTROLLED_AUTO = 4

SAFE_ACTIONS = {"status.read", "logs.read", "inventory.read", "task.plan"}

def can_execute(action: str, autonomy: int) -> bool:
    if action in SAFE_ACTIONS:
        return autonomy >= Autonomy.READ_ONLY
    return autonomy >= Autonomy.LIMITED_AUTO

import asyncio
from collections.abc import AsyncIterator
from packages.core.security_event_bus import SecurityEvent, SecurityEventBus

class SecurityEventStream:
    """Async bridge from the in-process security bus to realtime consumers."""
    def __init__(self, bus: SecurityEventBus):
        self._queue: asyncio.Queue[SecurityEvent] = asyncio.Queue()
        bus.subscribe(self.publish)

    def publish(self, event: SecurityEvent) -> None:
        self._queue.put_nowait(event)

    async def events(self) -> AsyncIterator[SecurityEvent]:
        while True:
            yield await self._queue.get()

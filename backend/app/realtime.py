from __future__ import annotations
import asyncio
from collections import defaultdict
from fastapi import WebSocket
class ConnectionManager:
    def __init__(self) -> None:
        self._connections: dict[int, set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()
    async def connect(self, user_id: int, ws: WebSocket) -> None:
        await ws.accept()
        async with self._lock:
            self._connections[user_id].add(ws)
    async def disconnect(self, user_id: int, ws: WebSocket) -> None:
        async with self._lock:
            self._connections[user_id].discard(ws)
            if not self._connections[user_id]:
                self._connections.pop(user_id, None)
    async def send_to_user(self, user_id: int, message: dict) -> None:
        conns = list(self._connections.get(user_id, set()))
        for ws in conns:
            try:
                await ws.send_json(message)
            except Exception:
                await self.disconnect(user_id, ws)
manager = ConnectionManager()
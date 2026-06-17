from __future__ import annotations
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.config import settings
from app.database import init_db
from app.routers import ai, alerts, auth, devices, measurements, users
@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
app = FastAPI(
    title=f"{settings.app_name} API",
    version="1.1.0",
    description="API de Circe · Sistema Inteligente de Monitoreo Biomédico",
    lifespan=lifespan,
)
_static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.isdir(_static_dir):
    app.mount("/static", StaticFiles(directory=_static_dir), name="static")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_origin_regex=r"https://([a-z0-9-]+\.)*(pages\.dev|itb\.lat)",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(devices.router)
app.include_router(measurements.router)
app.include_router(alerts.router)
app.include_router(ai.router)
@app.get("/", tags=["health"])
async def root():
    return {"name": settings.app_name, "status": "ok", "version": "1.0.0"}
@app.get("/health", tags=["health"])
async def health():
    return {"status": "healthy"}
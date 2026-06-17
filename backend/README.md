# Backend · Monitor Biomédico (FastAPI)

API REST + WebSocket para cuentas de usuario, vinculación de dispositivos,
ingestión de mediciones, alertas, recomendaciones de IA (Groq) y emails (Resend).

## Stack

- **FastAPI** + **Uvicorn**
- **SQLAlchemy 2 (async)** — SQLite en desarrollo, PostgreSQL en producción
- **JWT** (python-jose) + **bcrypt** (passlib)
- **Groq** (IA/chat) y **Resend** (emails) vía HTTP (`httpx`)

## Desarrollo

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env               # rellena GROQ_API_KEY, RESEND_API_KEY, JWT_SECRET
uvicorn app.main:app --reload
```

- Docs interactivas: http://127.0.0.1:8000/docs
- Salud: http://127.0.0.1:8000/health

Sin claves de Groq/Resend la API **igual funciona**: el chat devuelve 503 y las
recomendaciones usan un fallback estadístico; los emails se registran en consola.

## Estructura

```
app/
├── main.py            # app FastAPI, CORS, routers, lifespan (crea tablas)
├── config.py          # settings desde .env (pydantic-settings)
├── database.py        # engine async + sesión + init_db
├── models.py          # User, HealthProfile, Device, Measurement, Alert, ChatMessage...
├── schemas.py         # Pydantic (entrada/salida)
├── security.py        # hashing, JWT, API keys, códigos de vinculación
├── deps.py            # auth de usuario (JWT) y de dispositivo (X-API-Key)
├── health_rules.py    # reglas clínicas + texto de SMS (compartido con firmware)
├── realtime.py        # gestor de WebSocket
├── routers/           # auth, users, devices, measurements, alerts, ai
└── services/          # groq_service, resend_service, analysis
```

## Endpoints principales

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/v1/auth/register` | — | Crear cuenta (envía email de verificación) |
| POST | `/api/v1/auth/login` | — | Iniciar sesión → JWT |
| GET  | `/api/v1/auth/me` | JWT | Usuario actual |
| GET/PUT | `/api/v1/users/profile` | JWT | Perfil de salud (edad, peso, etc.) |
| POST | `/api/v1/users/delete-data` | JWT | Borrado de datos (privacidad) |
| POST | `/api/v1/devices/provision` | — | La ESP32 obtiene API key + código |
| POST | `/api/v1/devices/pair` | JWT | El usuario vincula con el código |
| PUT  | `/api/v1/devices/{id}/config` | JWT | Modo, nombre, números SMS |
| GET  | `/api/v1/devices/config/remote` | API key | La ESP32 lee su config |
| POST | `/api/v1/ingest` | API key | **La ESP32 envía una medición** |
| GET  | `/api/v1/measurements` | JWT | Historial |
| WS   | `/api/v1/ws/measurements?token=JWT` | JWT | Stream en tiempo real |
| GET  | `/api/v1/alerts` | JWT | Alertas |
| GET  | `/api/v1/ai/recommendation` | JWT | Recomendación personalizada |
| POST | `/api/v1/ai/chat` | JWT | Chat en vivo con IA |

## Probar sin hardware

```bash
python test.py            # flujo completo: registro → vinculación → mediciones → IA
python test.py --alert    # fuerza valores de alerta
python test.py --once     # una sola medición
```

## Despliegue en VPS Ubuntu

```bash
# Dependencias del sistema
sudo apt update && sudo apt install -y python3-venv nginx
# (Postgres opcional) sudo apt install -y postgresql

# App
git clone <repo> /opt/monitor && cd /opt/monitor/backend
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt gunicorn
cp .env.example .env   # ENVIRONMENT=production, DATABASE_URL=postgres..., claves

# Servicio systemd (ejemplo)
# ExecStart=/opt/monitor/backend/.venv/bin/gunicorn app.main:app \
#   -k uvicorn.workers.UvicornWorker -w 2 -b 127.0.0.1:8000

# Nginx como reverse proxy + certbot para TLS (HTTPS)
```

> En producción usa **HTTPS** siempre (la ESP32 y la app envían credenciales).
> Para la ESP32 con GPRS, considera permitir HTTP solo si el SIM800L no soporta el
> certificado, o usa un proxy. Mejor: TLS en todos lados.

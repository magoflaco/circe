from __future__ import annotations
import argparse
import random
import sys
import time
import uuid
import httpx
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass
DEFAULT_BASE = "http://127.0.0.1:8000"
def log(emoji: str, msg: str) -> None:
    print(f"{emoji}  {msg}")
def random_vitals(force_alert: bool = False) -> dict:
    if force_alert:
        return {
            "heart_rate": random.randint(105, 130),
            "spo2": random.randint(85, 93),
            "temperature": round(random.uniform(37.8, 39.5), 1),
        }
    if random.random() < 0.75:
        return {
            "heart_rate": random.randint(60, 95),
            "spo2": random.randint(96, 100),
            "temperature": round(random.uniform(36.2, 37.2), 1),
        }
    return {
        "heart_rate": random.choice([random.randint(101, 125), random.randint(45, 55)]),
        "spo2": random.randint(88, 96),
        "temperature": round(random.uniform(37.4, 39.0), 1),
    }
def main() -> int:
    parser = argparse.ArgumentParser(description="Simulador del Monitor Biomédico")
    parser.add_argument("--base", default=DEFAULT_BASE, help="URL base de la API")
    parser.add_argument("--once", action="store_true", help="una sola medición")
    parser.add_argument("--alert", action="store_true", help="fuerza valores de alerta")
    parser.add_argument("--interval", type=float, default=5.0, help="segundos entre lecturas")
    parser.add_argument("--count", type=int, default=12, help="número de lecturas")
    args = parser.parse_args()
    base = args.base.rstrip("/")
    client = httpx.Client(base_url=base, timeout=30)
    try:
        r = client.get("/health")
        r.raise_for_status()
    except Exception as exc:
        log("❌", f"No se pudo conectar al backend en {base}: {exc}")
        return 1
    log("✅", f"Backend activo en {base}")
    email = f"paciente_{uuid.uuid4().hex[:8]}@example.com"
    password = "Password123!"
    r = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "full_name": "Paciente de Prueba"},
    )
    if r.status_code not in (200, 201):
        log("❌", f"Registro falló: {r.status_code} {r.text}")
        return 1
    token = r.json()["access_token"]
    auth = {"Authorization": f"Bearer {token}"}
    log("👤", f"Usuario registrado: {email}")
    client.put(
        "/api/v1/users/profile",
        headers=auth,
        json={"age": 21, "gender": "male", "weight_kg": 72, "height_cm": 178},
    )
    log("🩺", "Perfil de salud guardado (edad 21, 72 kg, 178 cm)")
    device_uid = f"ESP32C3-{uuid.uuid4().hex[:6].upper()}"
    r = client.post("/api/v1/devices/provision", json={"device_uid": device_uid})
    r.raise_for_status()
    prov = r.json()
    api_key = prov["api_key"]
    pairing_code = prov["pairing_code"]
    log("📟", f"Dispositivo provisionado: {device_uid} | código {pairing_code}")
    r = client.post(
        "/api/v1/devices/pair",
        headers=auth,
        json={"pairing_code": pairing_code, "name": "Mi Monitor"},
    )
    r.raise_for_status()
    log("🔗", "Dispositivo vinculado a la cuenta")
    device_id = r.json()["id"]
    client.put(
        f"/api/v1/devices/{device_id}/config",
        headers=auth,
        json={"mode": "wifi", "sms_numbers": ["+593999999999"]},
    )
    device_headers = {"X-API-Key": api_key}
    n = 1 if args.once else args.count
    log("📡", f"Enviando {n} medición(es) cada {args.interval}s...")
    for i in range(n):
        vitals = random_vitals(force_alert=args.alert)
        r = client.post("/api/v1/ingest", headers=device_headers, json=vitals)
        if r.status_code != 200:
            log("⚠️", f"Ingest falló: {r.status_code} {r.text}")
            continue
        res = r.json()
        icon = "🚨" if res["status"] == "Alerta" else "💚"
        log(
            icon,
            f"[{i+1}/{n}] FC {vitals['heart_rate']} | SpO2 {vitals['spo2']}% | "
            f"T {vitals['temperature']}°C → {res['status']}",
        )
        if res["alert_created"]:
            log("   ", f"   SMS simulado → {res['summary']}")
        if not args.once and i < n - 1:
            time.sleep(args.interval)
    r = client.get("/api/v1/ai/recommendation", headers=auth)
    if r.status_code == 200:
        rec = r.json()
        log("🤖", f"Recomendación (basada en {rec['based_on']} mediciones):")
        print(f"     {rec['recommendation']}")
    r = client.get("/api/v1/alerts", headers=auth)
    if r.status_code == 200:
        log("🔔", f"Alertas generadas: {len(r.json())}")
    log("🎉", "Flujo completo OK. Inicia sesión en la app con:")
    print(f"     email: {email}\n     pass:  {password}")
    return 0
if __name__ == "__main__":
    sys.exit(main())
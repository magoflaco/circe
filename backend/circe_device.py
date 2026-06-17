from __future__ import annotations
import json
import os
import random
import sys
import time
import uuid
import httpx
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass
CONFIG_PATH = os.path.join(os.path.dirname(__file__), "circe_device.json")
DEFAULT_BACKEND = "https://api-monitor.itb.lat"
HR_LOW, HR_HIGH, SPO2_LOW, TEMP_LOW, TEMP_HIGH = 50, 100, 95, 35.0, 37.5
def banner():
    print("\n" + "=" * 52)
    print("   ⚕  CIRCE · Simulador de dispositivo (ESP32 virtual)")
    print("=" * 52)
def load_config() -> dict | None:
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return None
    return None
def save_config(cfg: dict) -> None:
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
def ask(prompt: str, default: str = "") -> str:
    suffix = f" [{default}]" if default else ""
    val = input(f"{prompt}{suffix}: ").strip()
    return val or default
def provision(cfg: dict) -> dict:
    client = httpx.Client(base_url=cfg["backend"], timeout=30)
    try:
        client.get("/health").raise_for_status()
    except Exception as exc:
        print(f"❌ No se pudo conectar al backend {cfg['backend']}: {exc}")
        sys.exit(1)
    r = client.post(
        "/api/v1/devices/provision",
        json={"device_uid": cfg["device_uid"], "name": cfg["name"]},
    )
    if r.status_code != 200:
        print(f"❌ Provisión falló: {r.status_code} {r.text}")
        sys.exit(1)
    data = r.json()
    cfg["api_key"] = data["api_key"]
    cfg["pairing_code"] = data["pairing_code"]
    save_config(cfg)
    return cfg
def setup() -> dict:
    banner()
    print("\nPrimera configuración del dispositivo (como el portal de la ESP32):\n")
    backend = ask("Servidor backend", DEFAULT_BACKEND).rstrip("/")
    name = ask("Nombre del dispositivo", "Mi Circe")
    sms = ask("Números para SMS (coma)", "+593999999999")
    cfg = {
        "backend": backend,
        "name": name,
        "sms_numbers": sms,
        "device_uid": f"CIRCE-VIRT-{uuid.uuid4().hex[:6].upper()}",
    }
    cfg = provision(cfg)
    print("\n" + "-" * 52)
    print(f"  Dispositivo:  {cfg['device_uid']}")
    print(f"  CÓDIGO DE VINCULACIÓN:  >>>  {cfg['pairing_code']}  <<<")
    print("-" * 52)
    print("  Inicia sesión en la app/web de Circe e introduce ese código")
    print("  en 'Dispositivos → Vincular nuevo dispositivo'.")
    print("-" * 52)
    return cfg
def status_label(hr: int, spo2: int, temp: float) -> str:
    alert = hr > HR_HIGH or hr < HR_LOW or spo2 < SPO2_LOW or temp > TEMP_HIGH or temp < TEMP_LOW
    return "🚨 ALERTA" if alert else "💚 Normal"
def send(cfg: dict, hr: int, spo2: int, temp: float) -> None:
    client = httpx.Client(base_url=cfg["backend"], timeout=30)
    r = client.post(
        "/api/v1/ingest",
        headers={"X-API-Key": cfg["api_key"]},
        json={"heart_rate": hr, "spo2": spo2, "temperature": temp},
    )
    if r.status_code == 200:
        res = r.json()
        print(f"   ✓ Enviado · FC {hr} | SpO2 {spo2}% | T {temp}°C → {res['status']}")
        if res.get("alert_created"):
            print(f"     SMS simulado → {res['summary']}")
    elif r.status_code == 401:
        print("   ❌ API key inválida. Usa la opción 5 para reprovisionar.")
    else:
        print(f"   ⚠ Error {r.status_code}: {r.text}")
def random_vitals(force_alert=False) -> tuple[int, int, float]:
    if force_alert:
        return (random.randint(105, 130), random.randint(85, 93), round(random.uniform(37.8, 39.4), 1))
    if random.random() < 0.75:
        return (random.randint(60, 95), random.randint(96, 100), round(random.uniform(36.2, 37.2), 1))
    return (random.choice([random.randint(101, 125), random.randint(45, 55)]),
            random.randint(88, 96), round(random.uniform(37.4, 39.0), 1))
def manual(cfg: dict) -> None:
    try:
        hr = int(ask("Frecuencia cardíaca (lpm)", "78"))
        spo2 = int(ask("Oxígeno SpO₂ (%)", "98"))
        temp = float(ask("Temperatura (°C)", "36.6"))
    except ValueError:
        print("   Valores inválidos."); return
    print(f"   {status_label(hr, spo2, temp)}")
    send(cfg, hr, spo2, temp)
def auto(cfg: dict) -> None:
    try:
        n = int(ask("¿Cuántas mediciones?", "10"))
        interval = float(ask("Intervalo en segundos", "3"))
    except ValueError:
        print("   Valores inválidos."); return
    force = ask("¿Forzar alertas? (s/n)", "n").lower().startswith("s")
    print()
    for i in range(n):
        hr, spo2, temp = random_vitals(force)
        print(f"  [{i+1}/{n}] {status_label(hr, spo2, temp)}")
        send(cfg, hr, spo2, temp)
        if i < n - 1:
            time.sleep(interval)
    print("\n   ✓ Listo. Revisa tu panel en la app.")
def main() -> None:
    cfg = load_config()
    if not cfg or "api_key" not in cfg:
        cfg = setup()
    else:
        banner()
        print(f"\n  Dispositivo: {cfg['device_uid']}  ({cfg['backend']})")
        if cfg.get("pairing_code"):
            print(f"  Código de vinculación pendiente: {cfg['pairing_code']}")
    while True:
        print("\n  ┌─────────────────────────────────────────────┐")
        print("  │  1) Enviar medición manual                    │")
        print("  │  2) Generar mediciones aleatorias             │")
        print("  │  3) Mostrar código de vinculación             │")
        print("  │  4) Salir                                     │")
        print("  │  5) Reconfigurar (nuevo dispositivo)          │")
        print("  └─────────────────────────────────────────────┘")
        opt = ask("  Opción", "2")
        if opt == "1":
            manual(cfg)
        elif opt == "2":
            auto(cfg)
        elif opt == "3":
            code = cfg.get("pairing_code") or "(ya vinculado)"
            print(f"\n   Dispositivo {cfg['device_uid']} · código: {code}")
        elif opt == "4":
            print("\n   👋 Hasta luego.")
            break
        elif opt == "5":
            if os.path.exists(CONFIG_PATH):
                os.remove(CONFIG_PATH)
            cfg = setup()
if __name__ == "__main__":
    main()
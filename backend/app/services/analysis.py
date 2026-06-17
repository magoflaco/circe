from __future__ import annotations
from statistics import mean
from app.models import Measurement
def summarize(measurements: list[Measurement]) -> dict:
    if not measurements:
        return {"count": 0}
    hr = [m.heart_rate for m in measurements]
    spo2 = [m.spo2 for m in measurements]
    temp = [m.temperature for m in measurements]
    alerts = sum(1 for m in measurements if m.status == "Alerta")
    return {
        "count": len(measurements),
        "alerts": alerts,
        "alert_ratio": round(alerts / len(measurements), 2),
        "heart_rate": {"avg": round(mean(hr), 1), "min": min(hr), "max": max(hr)},
        "spo2": {"avg": round(mean(spo2), 1), "min": min(spo2), "max": max(spo2)},
        "temperature": {
            "avg": round(mean(temp), 1),
            "min": round(min(temp), 1),
            "max": round(max(temp), 1),
        },
    }
def summary_text(measurements: list[Measurement]) -> str:
    s = summarize(measurements)
    if s["count"] == 0:
        return "Sin mediciones registradas todavía."
    return (
        f"{s['count']} mediciones, {s['alerts']} con alerta "
        f"({int(s['alert_ratio'] * 100)}%). "
        f"FC media {s['heart_rate']['avg']} lpm (min {s['heart_rate']['min']}, "
        f"max {s['heart_rate']['max']}). "
        f"SpO2 media {s['spo2']['avg']}% (min {s['spo2']['min']}). "
        f"Temp media {s['temperature']['avg']}°C "
        f"(min {s['temperature']['min']}, max {s['temperature']['max']})."
    )
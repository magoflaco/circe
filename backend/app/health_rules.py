from __future__ import annotations
from dataclasses import dataclass
HR_LOW, HR_HIGH = 50, 100          
SPO2_LOW = 95                      
TEMP_LOW, TEMP_HIGH = 35.0, 37.5   
@dataclass
class Evaluation:
    status: str            
    severity: str          
    issues: list[str]      
    summary: str           
    recommendation: str    
def evaluate(heart_rate: int, spo2: int, temperature: float) -> Evaluation:
    issues: list[str] = []
    severity = "info"
    if heart_rate > HR_HIGH:
        issues.append(f"Frecuencia cardíaca elevada ({heart_rate} lpm)")
        severity = "warning"
    elif heart_rate < HR_LOW:
        issues.append(f"Frecuencia cardíaca baja ({heart_rate} lpm)")
        severity = "warning"
    if spo2 < SPO2_LOW:
        issues.append(f"Oxígeno en sangre bajo ({spo2}%)")
        severity = "critical" if spo2 < 90 else "warning"
    if temperature > TEMP_HIGH:
        issues.append(f"Temperatura elevada ({temperature:.1f}°C)")
        severity = "critical" if temperature >= 39 else "warning"
    elif temperature < TEMP_LOW:
        issues.append(f"Temperatura baja ({temperature:.1f}°C)")
        severity = "warning"
    status = "Alerta" if issues else "Normal"
    if not issues:
        summary = "Signos vitales dentro de rangos normales."
        recommendation = "Mantén tus hábitos saludables."
    else:
        summary = "Anomalía detectada: " + "; ".join(issues) + "."
        recommendation = (
            "Se recomienda reposo y vigilancia. Si los síntomas persisten o "
            "empeoran, acude a un profesional de la salud."
        )
    return Evaluation(
        status=status,
        severity=severity,
        issues=issues,
        summary=summary,
        recommendation=recommendation,
    )
def sms_text(name: str, heart_rate: int, spo2: int, temperature: float) -> str:
    ev = evaluate(heart_rate, spo2, temperature)
    head = f"[Monitor Biomedico] {name or 'Paciente'}"
    vitals = f"FC:{heart_rate}lpm SpO2:{spo2}% T:{temperature:.1f}C"
    if ev.status == "Normal":
        return f"{head} OK. {vitals}."
    return f"{head} ALERTA. {vitals}. {ev.summary} Consulte a un medico."
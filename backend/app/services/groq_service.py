from __future__ import annotations
import httpx
from app.config import settings
SYSTEM_PROMPT = (
    "Eres un asistente de salud del sistema 'Monitor Biomédico'. Ayudas a pacientes "
    "a entender sus signos vitales (frecuencia cardíaca, oxígeno en sangre y "
    "temperatura) de forma clara, empática y en español. "
    "Das orientación general y hábitos saludables, NUNCA un diagnóstico definitivo. "
    "Siempre recuerdas que ante síntomas serios o persistentes deben consultar a un "
    "profesional de la salud. Sé conciso y útil."
)
class GroqUnavailable(Exception):
    pass
async def _chat_completion(messages: list[dict], temperature: float = 0.5) -> str:
    if not settings.groq_api_key:
        raise GroqUnavailable("GROQ_API_KEY no configurada")
    url = f"{settings.groq_base_url}/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.groq_api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": settings.groq_model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": 800,
    }
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, headers=headers, json=payload)
        resp.raise_for_status()
        data = resp.json()
    return data["choices"][0]["message"]["content"].strip()
async def chat(history: list[dict], user_message: str, profile_context: str = "") -> str:
    system = SYSTEM_PROMPT
    if profile_context:
        system += f"\n\nContexto del paciente:\n{profile_context}"
    messages = [{"role": "system", "content": system}, *history,
                {"role": "user", "content": user_message}]
    return await _chat_completion(messages, temperature=0.6)
async def recommendation(profile_context: str, vitals_summary: str) -> str:
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {
            "role": "user",
            "content": (
                "Analiza estos datos del paciente y dame una recomendación breve "
                "(máximo 4 frases) y accionable.\n\n"
                f"Perfil:\n{profile_context}\n\nResumen de mediciones recientes:\n{vitals_summary}"
            ),
        },
    ]
    return await _chat_completion(messages, temperature=0.4)
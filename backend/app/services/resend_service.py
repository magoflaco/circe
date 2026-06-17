from __future__ import annotations
import httpx
from app.config import settings
RESEND_URL = "https://api.resend.com/emails"
BANNER_URL = f"{settings.public_base_url}/static/circe_banner.jpg"
def _wrap(title: str, body_html: str, footnote: str = "") -> str:
    return f"""\
<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;background:#eef0ff;font-family:'Segoe UI',system-ui,Arial,sans-serif;">
  <div style="max-width:560px;margin:0 auto;padding:24px 14px;">
    <div style="background:#ffffff;border-radius:22px;overflow:hidden;
         box-shadow:0 14px 40px rgba(158,143,224,.25);">
      <img src="{BANNER_URL}" alt="Circe" width="560"
           style="width:100%;display:block;">
      <div style="padding:30px 34px 36px;">
        <h1 style="margin:0 0 6px;font-size:22px;color:#33414f;">{title}</h1>
        {body_html}
      </div>
    </div>
    <p style="text-align:center;color:#9aa6b6;font-size:12px;margin:18px 8px;">
      Circe · Sistema inteligente de monitoreo biomédico<br>
      {footnote or 'Este es un mensaje automático, por favor no respondas a este correo.'}
    </p>
  </div>
</body></html>"""
def _code_box(code: str) -> str:
    return f"""\
<div style="margin:22px 0;text-align:center;">
  <div style="display:inline-block;padding:16px 30px;border-radius:16px;
       background:linear-gradient(90deg,#eafaf6,#eef0ff,#fbeef5);
       border:1px solid #e0dbf2;">
    <span style="font-size:34px;font-weight:800;letter-spacing:10px;color:#5b4ba0;">{code}</span>
  </div>
</div>"""
async def send_email(to: str, subject: str, html: str) -> bool:
    if not settings.resend_api_key:
        print(f"[resend:dev] (sin API key) -> {to} | {subject}")
        return False
    headers = {
        "Authorization": f"Bearer {settings.resend_api_key}",
        "Content-Type": "application/json",
    }
    payload = {"from": settings.resend_from, "to": [to], "subject": subject, "html": html}
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(RESEND_URL, headers=headers, json=payload)
            resp.raise_for_status()
        return True
    except Exception as exc:
        print(f"[resend] error enviando a {to}: {exc}")
        return False
async def send_verification_email(to: str, name: str, code: str) -> bool:
    body = f"""\
<p style="color:#5b6b7b;line-height:1.6;font-size:15px;">
  Hola{(' ' + name) if name else ''}, ¡bienvenido/a a <b>Circe</b>! 🌿<br>
  Usa este código para verificar tu cuenta dentro de la aplicación:
</p>
{_code_box(code)}
<p style="color:#8794a6;font-size:13px;line-height:1.6;">
  El código es de un solo uso. Si no creaste esta cuenta, puedes ignorar este correo.
</p>"""
    return await send_email(to, "Tu código de verificación · Circe", _wrap("Verifica tu cuenta", body))
async def send_reset_email(to: str, name: str, code: str) -> bool:
    body = f"""\
<p style="color:#5b6b7b;line-height:1.6;font-size:15px;">
  Hola{(' ' + name) if name else ''}, recibimos una solicitud para restablecer tu
  contraseña. Ingresa este código en la app para crear una nueva:
</p>
{_code_box(code)}
<p style="color:#8794a6;font-size:13px;line-height:1.6;">
  Si no solicitaste el cambio, ignora este correo y tu contraseña seguirá igual.
</p>"""
    return await send_email(to, "Restablece tu contraseña · Circe", _wrap("Restablecer contraseña", body))
async def send_welcome_email(to: str, name: str) -> bool:
    body = f"""\
<p style="color:#5b6b7b;line-height:1.6;font-size:15px;">
  ¡Tu cuenta está verificada{(', ' + name) if name else ''}! 🎉<br>
  Ya puedes vincular tu dispositivo Circe y empezar a monitorear tus signos
  vitales en tiempo real, recibir alertas y recomendaciones con IA.
</p>
<div style="margin:24px 0;text-align:center;">
  <a href="{settings.frontend_url}" style="display:inline-block;padding:13px 28px;
     border-radius:14px;background:#5b4ba0;color:#fff;text-decoration:none;
     font-weight:600;">Abrir Circe</a>
</div>"""
    return await send_email(to, "¡Bienvenido/a a Circe!", _wrap("Cuenta verificada", body))
async def send_deletion_confirmation(to: str, name: str) -> bool:
    body = f"""\
<p style="color:#5b6b7b;line-height:1.6;font-size:15px;">
  Hola{(' ' + name) if name else ''}, hemos recibido y procesado tu solicitud de
  eliminación de datos. Tus mediciones, alertas, perfil y conversaciones han sido
  eliminados permanentemente, y tus dispositivos quedaron liberados.
</p>
<p style="color:#8794a6;font-size:13px;line-height:1.6;">
  Gracias por haber confiado en Circe. Puedes volver cuando quieras.
</p>"""
    return await send_email(to, "Tus datos han sido eliminados · Circe",
                            _wrap("Solicitud completada", body))
# Frontend · Monitor Biomédico (Flutter)

App **web + Android** para el paciente: inicio de sesión, dashboard en tiempo
real, perfil de salud, vinculación de dispositivos, asistente de IA y gestión de
privacidad. Estética pastel clara, gráficos y animaciones suaves.

## Stack

- **Flutter** (Material 3) · tema pastel personalizado (`lib/theme.dart`)
- **provider** — estado de sesión
- **http** + **web_socket_channel** — API REST y mediciones en tiempo real
- **fl_chart** — gráficos de tendencia
- **shared_preferences** — persistencia del token
- **google_fonts** (Poppins)

## Estructura

```
lib/
├── main.dart            # arranque + enrutado por estado de sesión
├── config.dart          # URL del backend (--dart-define=API_BASE=...)
├── theme.dart           # paleta pastel y estilos
├── models.dart          # Measurement, Alert, HealthProfile, Device, ChatMessage
├── widgets.dart         # PastelBackground, SoftCard, VitalCard, showError
├── services/
│   ├── api_service.dart      # cliente HTTP del backend
│   ├── auth_provider.dart    # login/registro/logout + token persistente
│   └── realtime_service.dart # WebSocket de mediciones
└── screens/
    ├── login_screen.dart
    ├── register_screen.dart   # con aceptación de manejo de datos
    ├── home_shell.dart        # navegación inferior
    ├── dashboard_screen.dart  # signos, gráfico, recomendación, historial, tiempo real
    ├── devices_screen.dart    # vincular/configurar/desvincular dispositivos
    ├── chat_screen.dart       # asistente de IA
    ├── profile_screen.dart    # perfil de salud (edad, peso, IMC...) + ajustes
    └── privacy_screen.dart    # cookies, datos, descargo y borrado de datos
```

## Desarrollo

```bash
flutter pub get

# Web (apunta al backend local)
flutter run -d chrome --dart-define=API_BASE=http://127.0.0.1:8000

# Web contra el VPS
flutter run -d chrome --dart-define=API_BASE=http://140.86.213.1:8000

# Android (dispositivo/emulador)
flutter run -d <android> --dart-define=API_BASE=http://140.86.213.1:8000
```

> El backend debe estar corriendo y su `CORS_ORIGINS` debe incluir el origen del
> frontend. Para móvil real usa la IP del VPS (no `127.0.0.1`).

## Build de producción

```bash
# Web -> Cloudflare Pages (sube la carpeta build/web)
flutter build web --release --dart-define=API_BASE=https://api.tudominio.com

# Android
flutter build apk --release --dart-define=API_BASE=https://api.tudominio.com
```

### Desplegar la web en Cloudflare Pages

1. `flutter build web --release --dart-define=API_BASE=https://api.tudominio.com`
2. Sube `build/web` a Cloudflare Pages (o conecta el repo y usa ese comando como
   build con output `build/web`).
3. Asegúrate de que el backend permita el dominio en `CORS_ORIGINS`.

## Notas

- El token de sesión se guarda en `shared_preferences` (localStorage en web).
- El dashboard recibe mediciones nuevas al instante por WebSocket; si se cae,
  basta con refrescar (pull-to-refresh).
- Si Groq no está configurado en el backend, el chat avisa y la recomendación usa
  el análisis estadístico de respaldo.

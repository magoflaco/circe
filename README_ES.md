# Circe: Automatización del Monitoreo de Signos Vitales

![Circe Banner](./docs/circe_banner.JPG)

**Circe** es un sistema de monitoreo inteligente enfocado en el cuidado de adultos mayores, que integra tecnologías IoT, sensores biomédicos, un microcontrolador y comunicación inalámbrica para adquirir, procesar y transmitir información fisiológica crítica en tiempo real de forma continua.

Basado en el artículo: *"Automation of Vital Signs Monitoring Through Smart Sensors and GSM Communication for Elderly Care"* (Disponible en este repositorio como `./docs/circe_paper.pdf`).

## Demostración en Vivo

🚀 **Puedes probar la aplicación y la interfaz web directamente en:** [https://monitor.itb.lat/](https://monitor.itb.lat/)

## Características

- **Monitoreo Continuo de Signos Vitales**: Frecuencia cardíaca, saturación de oxígeno en sangre (SpO₂) y temperatura corporal.
- **Alertas Automáticas**: Una regla de decisión en el dispositivo genera alertas SMS automáticas a través de GSM cuando se superan los umbrales fisiológicos.
- **Aplicación Multiplataforma**: Una aplicación móvil basada en Flutter con paneles en tiempo real, integraciones de salud y notificaciones de emergencia.
- **Backend Robusto**: Un backend en FastAPI para el procesamiento de datos, análisis con IA y gestión de alertas.
- **Hardware Confiable**: Construido con un microcontrolador ESP32, un sensor de pulsoximetría MAX30102, un termómetro infrarrojo MLX90614 y un módulo GSM SIM800L.

## Arquitectura

1. **Firmware (C++)**: Código para el ESP32 que recopila datos de los sensores MAX30102 y MLX90614. Procesa esta información localmente y puede activar independientemente alertas SMS a través del módulo SIM800L, asegurando la funcionalidad incluso sin internet.
2. **Backend (Python)**: Un servidor FastAPI que maneja la sincronización de datos, análisis de salud impulsado por IA (Groq), alertas en tiempo real y autenticación de usuarios.
3. **Frontend (Flutter)**: La aplicación de interfaz para cuidadores y familiares, que proporciona un panel completo, configuraciones del dispositivo y monitoreo en tiempo real.

## Empezando

Por favor, consulte los directorios específicos para más detalles:
- `frontend/README.md` - Para la configuración de la aplicación móvil.
- `backend/README.md` - Para la configuración del servidor.
- `firmware/README.md` - Para las instrucciones de grabación de hardware.

## Agradecimientos

Los autores agradecen al Instituto Superior Universitario Bolivariano de Tecnología (ITB) por el apoyo institucional brindado durante el desarrollo de este trabajo.

## Licencia

Este proyecto está licenciado bajo la Licencia GPL-3.0. Consulte el archivo `LICENSE` para más detalles.

Copyright (C) 2026 Gabriel Chaviano (gchaviano@itb.edu.ec)

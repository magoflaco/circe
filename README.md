# Circe: Automation of Vital Signs Monitoring

![Circe Banner](./circe_banner.JPG)

**Circe** is an intelligent monitoring system focused on elderly care, integrating IoT technologies, biomedical sensors, a microcontroller, and wireless communication to continuously acquire, process, and transmit critical physiological information in real-time.

Based on the paper: *"Automation of Vital Signs Monitoring Through Smart Sensors and GSM Communication for Elderly Care"* (Available in this repository as `circe_paper.pdf`).

## Features

- **Continuous Vital Signs Monitoring**: Heart rate, blood-oxygen saturation (SpO₂), and body temperature.
- **Automatic Alerts**: An on-device decision rule generates automatic SMS alerts via GSM when physiological thresholds are exceeded.
- **Cross-Platform App**: A Flutter-based mobile application with real-time dashboards, health integrations, and emergency notifications.
- **Robust Backend**: A FastAPI backend for data processing, AI analysis, and alert management.
- **Reliable Hardware**: Built with an ESP32 microcontroller, MAX30102 pulse-oximetry sensor, MLX90614 infrared thermometer, and a SIM800L GSM module.

## Architecture

1. **Firmware (C++)**: ESP32 code that gathers data from the MAX30102 and MLX90614 sensors. It processes this data locally and can independently trigger SMS alerts through the SIM800L module, ensuring functionality even without internet.
2. **Backend (Python)**: A FastAPI server that handles data synchronization, AI-powered health analysis (Groq), real-time alerts, and user authentication.
3. **Frontend (Flutter)**: The user-facing application for caregivers and family members, providing a comprehensive dashboard, device settings, and real-time monitoring.

## Getting Started

Please refer to the specific directories for more details:
- `frontend/README.md` - For mobile app setup.
- `backend/README.md` - For server setup.
- `firmware/README.md` - For hardware flashing instructions.

## License

This project is licensed under the GPL-3.0 License. See the `LICENSE` file for details.

Copyright (C) 2026 Gabriel Chaviano (gchaviano@itb.edu.ec)

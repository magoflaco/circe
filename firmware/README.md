# Circe Firmware

This directory contains the C++ firmware for the ESP32 microcontroller. The firmware is responsible for interfacing with biomedical sensors and managing GSM communications for the Circe project.

## Hardware Components
- ESP32 Microcontroller
- MAX30102 (Pulse Oximetry and Heart Rate)
- MLX90614 (Non-contact Infrared Thermometer)
- SIM800L (GSM Module)

## Dependencies
Ensure the following libraries are installed in your Arduino IDE or PlatformIO environment:
- Wire.h (I2C communication)
- Hardware-specific sensor libraries for MAX30102 and MLX90614

## Configuration
Before flashing the firmware, review and update `config.h` with your specific parameters, including default threshold values and connection settings.

## Deployment
1. Open `monitor_biomedico.ino` in the Arduino IDE.
2. Select the appropriate ESP32 board configuration.
3. Compile and upload the sketch to the hardware.

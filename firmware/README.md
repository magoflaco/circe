# Firmware · ESP32-C3 SuperMini

Firmware del módulo de monitoreo. Lee FC + SpO₂ (MAX30102) y temperatura
(MLX90614), envía los datos al backend por **WiFi** o **GPRS**, y manda **SMS de
alerta por el SIM800L de forma independiente** del modo online.

## Componentes

| Componente | Función | Bus |
|------------|---------|-----|
| ESP32-C3 SuperMini | Cerebro | — |
| MAX30102 | Frecuencia cardíaca + SpO₂ | I²C |
| MLX90614 | Temperatura corporal (IR) | I²C |
| SIM800L | SMS + datos GPRS | UART |
| LM2596 / fuente | Alimentar el SIM800L (picos ~2 A) | — |
| Batería 18650 + TP4056 | Energía portátil | — |

## Cableado (pines por defecto en `config.h`, editables)

```
MAX30102 / MLX90614 (I²C, comparten bus)
  VIN  -> 3V3
  GND  -> GND
  SDA  -> GPIO8   (I2C_SDA_PIN)
  SCL  -> GPIO9   (I2C_SCL_PIN)

SIM800L (UART1)
  VCC  -> 3.7-4.2V desde LM2596/batería (NO al 3V3 del ESP32)
  GND  -> GND común con el ESP32
  TXD  -> GPIO20  (SIM800_RX_PIN, recibe en el ESP32)
  RXD  -> GPIO21  (SIM800_TX_PIN, transmite el ESP32)
```

> ⚠️ El SIM800L es muy sensible a la alimentación. Usa una fuente que aguante
> picos de ~2 A y un capacitor de 1000 µF cerca del módulo. No lo alimentes del
> pin 3V3 del ESP32-C3 o se reiniciará.

> Los pines GPIO8/GPIO9 son los I²C sugeridos; si tu placa usa el LED en GPIO8,
> deja `STATUS_LED_PIN -1` o mueve el I²C a otros pines libres.

## Librerías (Arduino IDE → Gestor de librerías)

- **SparkFun MAX3010x Pulse and Proximity Sensor Library**
- **Adafruit MLX90614 Library**
- **TinyGSM** (Volodymyr Shymanskyy)
- **ArduinoJson** (Benoit Blanchon)
- Core **esp32** de Espressif (incluye WiFi, WebServer, DNSServer, Preferences, HTTPClient, Wire)

## Configuración antes de compilar

1. Instala el **core ESP32** en Arduino IDE (Gestor de tarjetas → "esp32").
2. Selecciona placa: **ESP32C3 Dev Module** (o "ESP32-C3 SuperMini" si aparece).
3. Abre `monitor_biomedico/monitor_biomedico.ino`.
4. Revisa `config.h`: pon la **IP de tu VPS** en `DEFAULT_BACKEND_HOST` y los pines.
5. Compila y flashea.

## Primer uso (provisión y vinculación)

1. Al primer arranque el ESP32 crea un AP **`MonitorBio-XXXX`**
   (contraseña `monitor123`). Conéctate con el móvil.
2. Se abre el **portal de configuración** (o ve a `http://192.168.4.1`).
3. Elige **WiFi** o **GPRS**, pon credenciales, números de SMS y la IP del backend.
4. Guarda → el dispositivo se reinicia, se conecta y se **provisiona** contra el
   backend, mostrando un **código de vinculación** (en el Monitor Serie y en el portal).
5. En la app/web, inicia sesión e introduce ese código para vincular el dispositivo.
6. A partir de ahí, cada ciclo (`MEASURE_INTERVAL_MS`) lee, manda SMS y envía la
   medición al backend.

## Notas

- **SMS en cada medición:** controlado por `DEFAULT_SMS_EVERY_MEASUREMENT`. Con
  intervalos cortos consume mucho saldo; el intervalo es `MEASURE_INTERVAL_MS`
  (5 min por defecto). Reconfigurable.
- **Reconfiguración remota:** los números SMS y el modo se pueden cambiar desde la
  app; el firmware los sincroniza con `/api/v1/devices/config/remote`.
- **HTTPS:** el SIM800L tiene soporte TLS limitado. Para GPRS quizá necesites HTTP
  plano contra un puerto del VPS; por WiFi usa HTTPS sin problema.
- Los umbrales clínicos en `config.h` deben coincidir con
  `backend/app/health_rules.py`.

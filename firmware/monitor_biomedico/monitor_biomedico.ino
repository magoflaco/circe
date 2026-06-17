#include "config.h"
#include <Wire.h>
#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <MAX30105.h>
#include "spo2_algorithm.h"
#include <Adafruit_MLX90614.h>
#define TINY_GSM_MODEM_SIM800
#include <TinyGsm.h>
Preferences prefs;
struct Config {
  String mode = "wifi";          
  String wifiSsid = "";
  String wifiPass = "";
  String apn = "internet";       
  String apnUser = "";
  String apnPass = "";
  String smsNumbers = "";        
  String backendHost = DEFAULT_BACKEND_HOST;
  int    backendPort = DEFAULT_BACKEND_PORT;
  bool   useHttps = DEFAULT_USE_HTTPS;
  bool   smsEvery = DEFAULT_SMS_EVERY_MEASUREMENT;
  String apiKey = "";            
  String pairingCode = "";       
  bool   configured = false;
};
Config cfg;
String deviceUid;
MAX30105 maxSensor;
Adafruit_MLX90614 mlx = Adafruit_MLX90614();
bool maxOk = false, mlxOk = false;
HardwareSerial SerialGSM(1);
TinyGsm modem(SerialGSM);
TinyGsmClient gsmClient(modem);
bool gsmReady = false;
WebServer server(PORTAL_PORT);
DNSServer dnsServer;
bool portalMode = false;
unsigned long lastMeasure = 0;
unsigned long lastSync = 0;
String macSuffix() {
  uint8_t mac[6];
  WiFi.macAddress(mac);
  char buf[7];
  sprintf(buf, "%02X%02X%02X", mac[3], mac[4], mac[5]);
  return String(buf);
}
void blink(int times, int ms = 120) {
#if STATUS_LED_PIN >= 0
  for (int i = 0; i < times; i++) {
    digitalWrite(STATUS_LED_PIN, HIGH); delay(ms);
    digitalWrite(STATUS_LED_PIN, LOW);  delay(ms);
  }
#endif
}
void loadConfig() {
  prefs.begin("monitor", true);
  cfg.mode        = prefs.getString("mode", cfg.mode);
  cfg.wifiSsid    = prefs.getString("ssid", "");
  cfg.wifiPass    = prefs.getString("wpass", "");
  cfg.apn         = prefs.getString("apn", cfg.apn);
  cfg.apnUser     = prefs.getString("apnuser", "");
  cfg.apnPass     = prefs.getString("apnpass", "");
  cfg.smsNumbers  = prefs.getString("sms", "");
  cfg.backendHost = prefs.getString("host", cfg.backendHost);
  cfg.backendPort = prefs.getInt("port", cfg.backendPort);
  cfg.useHttps    = prefs.getBool("https", cfg.useHttps);
  cfg.smsEvery    = prefs.getBool("smsevery", cfg.smsEvery);
  cfg.apiKey      = prefs.getString("apikey", "");
  cfg.pairingCode = prefs.getString("pair", "");
  cfg.configured  = prefs.getBool("cfgdone", false);
  prefs.end();
}
void saveConfig() {
  prefs.begin("monitor", false);
  prefs.putString("mode", cfg.mode);
  prefs.putString("ssid", cfg.wifiSsid);
  prefs.putString("wpass", cfg.wifiPass);
  prefs.putString("apn", cfg.apn);
  prefs.putString("apnuser", cfg.apnUser);
  prefs.putString("apnpass", cfg.apnPass);
  prefs.putString("sms", cfg.smsNumbers);
  prefs.putString("host", cfg.backendHost);
  prefs.putInt("port", cfg.backendPort);
  prefs.putBool("https", cfg.useHttps);
  prefs.putBool("smsevery", cfg.smsEvery);
  prefs.putString("apikey", cfg.apiKey);
  prefs.putString("pair", cfg.pairingCode);
  prefs.putBool("cfgdone", cfg.configured);
  prefs.end();
}
String htmlPage() {
  String pair = cfg.pairingCode.length()
    ? "<div class='code'>Código de vinculación: <b>" + cfg.pairingCode + "</b></div>"
    : "";
  String html =
    "<!DOCTYPE html><html lang='es'><head><meta charset='UTF-8'>"
    "<meta name='viewport' content='width=device-width,initial-scale=1'>"
    "<title>Circe · Configuración</title><style>"
    "*{box-sizing:border-box}"
    "body{font-family:system-ui,-apple-system,sans-serif;margin:0;padding:18px;color:#33414f;"
    "background:linear-gradient(135deg,#eafaf4,#eef0ff 45%,#f6ecf7)}"
    ".card{background:#fff;max-width:460px;margin:auto;border-radius:22px;padding:24px;"
    "box-shadow:0 14px 40px rgba(158,143,224,.25)}"
    ".brand{display:flex;align-items:center;gap:12px;margin-bottom:6px}"
    ".logo{width:46px;height:46px;border-radius:14px;flex:none;"
    "background:conic-gradient(from 200deg,#3FB7A6,#5BA8E0,#9E8FE0,#DB6FA8,#3FB7A6);"
    "box-shadow:0 6px 18px rgba(158,143,224,.4)}"
    ".brand h1{margin:0;font-size:24px;font-weight:800;"
    "background:linear-gradient(90deg,#3FB7A6,#5BA8E0,#9E8FE0,#DB6FA8);"
    "-webkit-background-clip:text;background-clip:text;color:transparent}"
    "label{font-size:13px;font-weight:600;display:block;margin:14px 0 5px;color:#5b6b7b}"
    "input,select{width:100%;padding:11px;border:1px solid #e6e1f0;border-radius:12px;"
    "background:#fbfaf6;font-size:14px}"
    "input:focus,select:focus{outline:none;border-color:#9E8FE0}"
    "button{width:100%;margin-top:20px;padding:13px;border:0;border-radius:14px;color:#fff;"
    "font-weight:700;font-size:15px;background:linear-gradient(90deg,#5BA8E0,#9E8FE0,#DB6FA8)}"
    ".code{background:linear-gradient(90deg,#eafaf6,#eef0ff,#fbeef5);border:1px solid #e0dbf2;"
    "padding:14px;border-radius:14px;margin:14px 0;text-align:center;font-size:15px}"
    ".code b{font-size:24px;letter-spacing:6px;color:#5b4ba0}"
    "small{color:#8794a6}"
    "</style></head><body><div class='card'>"
    "<div class='brand'><div class='logo'></div><h1>Circe</h1></div>"
    "<small>Monitor biomédico · Dispositivo " + deviceUid + "</small>" + pair +
    "<form method='POST' action='/save'>"
    "<label>Modo de conexión</label><select name='mode'>"
    "<option value='wifi'" + (cfg.mode=="wifi"?" selected":"") + ">WiFi</option>"
    "<option value='gprs'" + (cfg.mode=="gprs"?" selected":"") + ">GPRS (SIM800L)</option></select>"
    "<label>WiFi · Nombre de red (SSID)</label><input name='ssid' value='" + cfg.wifiSsid + "'>"
    "<label>WiFi · Contraseña</label><input name='wpass' type='password' value='" + cfg.wifiPass + "'>"
    "<label>GPRS · APN</label><input name='apn' value='" + cfg.apn + "'>"
    "<label>Números para SMS (separados por coma)</label>"
    "<input name='sms' placeholder='+593999999999,+593888888888' value='" + cfg.smsNumbers + "'>"
    "<label>Servidor backend (host)</label><input name='host' value='" + cfg.backendHost + "'>"
    "<label>Puerto</label><input name='port' type='number' value='" + String(cfg.backendPort) + "'>"
    "<button type='submit'>Guardar y conectar</button></form>"
    "<small>Tras guardar, anota el código de vinculación e introdúcelo en la app.</small>"
    "</div></body></html>";
  return html;
}
void handleRoot()  { server.send(200, "text/html", htmlPage()); }
void handleSave() {
  cfg.mode        = server.arg("mode");
  cfg.wifiSsid    = server.arg("ssid");
  cfg.wifiPass    = server.arg("wpass");
  cfg.apn         = server.arg("apn");
  cfg.smsNumbers  = server.arg("sms");
  cfg.backendHost = server.arg("host");
  if (server.arg("port").length()) cfg.backendPort = server.arg("port").toInt();
  cfg.configured  = true;
  saveConfig();
  server.send(200, "text/html",
    "<meta charset='UTF-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
    "<body style=\"font-family:system-ui,sans-serif;text-align:center;padding:50px 24px;"
    "background:linear-gradient(135deg,#eafaf4,#eef0ff,#f6ecf7);color:#33414f\">"
    "<h2 style=\"background:linear-gradient(90deg,#3FB7A6,#9E8FE0,#DB6FA8);"
    "-webkit-background-clip:text;background-clip:text;color:transparent\">Configuración guardada</h2>"
    "<p>Circe se reiniciará y se conectará. Ya puedes cerrar esta página.</p></body>");
  delay(1500);
  ESP.restart();
}
void startPortal() {
  portalMode = true;
  String apName = String(AP_PREFIX) + macSuffix();
  WiFi.mode(WIFI_AP);
  WiFi.softAP(apName.c_str(), AP_PASSWORD);
  IPAddress ip = WiFi.softAPIP();
  dnsServer.start(53, "*", ip);
  server.onNotFound(handleRoot);   
  server.on("/", handleRoot);
  server.on("/save", HTTP_POST, handleSave);
  server.begin();
  Serial.println();
  Serial.println("======================================");
  Serial.print("  Portal de configuración: ");
  Serial.println(apName);
  Serial.print("  Contraseña AP: ");
  Serial.println(AP_PASSWORD);
  Serial.print("  Abre http://");
  Serial.println(ip);
  Serial.println("======================================");
}
bool connectWifi() {
  Serial.printf("Conectando a WiFi '%s'...\n", cfg.wifiSsid.c_str());
  WiFi.mode(WIFI_STA);
  WiFi.begin(cfg.wifiSsid.c_str(), cfg.wifiPass.c_str());
  unsigned long t0 = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t0 < 20000) {
    delay(400); Serial.print(".");
  }
  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("WiFi OK, IP: "); Serial.println(WiFi.localIP());
    return true;
  }
  Serial.println("WiFi FALLÓ.");
  return false;
}
bool connectGprs() {
  Serial.println("Iniciando GPRS (SIM800L)...");
  if (!modem.restart()) { Serial.println("No responde el módem."); return false; }
  if (!modem.gprsConnect(cfg.apn.c_str(), cfg.apnUser.c_str(), cfg.apnPass.c_str())) {
    Serial.println("GPRS FALLÓ."); return false;
  }
  Serial.print("GPRS OK, IP: "); Serial.println(modem.getLocalIP());
  return true;
}
void initModem() {
  SerialGSM.begin(SIM800_BAUD, SERIAL_8N1, SIM800_RX_PIN, SIM800_TX_PIN);
  delay(3000);
  Serial.println("Inicializando módem GSM para SMS...");
  if (modem.init() || modem.restart()) {
    gsmReady = true;
    Serial.println("Módem GSM listo.");
  } else {
    Serial.println("Módem GSM no detectado (los SMS no se enviarán).");
  }
}
void sendSmsAll(const String &text) {
  if (!gsmReady || cfg.smsNumbers.length() == 0) return;
  String list = cfg.smsNumbers;
  int start = 0;
  while (start < list.length()) {
    int comma = list.indexOf(',', start);
    if (comma < 0) comma = list.length();
    String number = list.substring(start, comma);
    number.trim();
    if (number.length() > 4) {
      Serial.printf("Enviando SMS a %s\n", number.c_str());
      modem.sendSMS(number, text);
    }
    start = comma + 1;
  }
}
String buildSummary(int hr, int spo2, float temp, bool &alert) {
  String issues = "";
  alert = false;
  if (hr > HR_HIGH)       { issues += "FC alta;"; alert = true; }
  else if (hr < HR_LOW)   { issues += "FC baja;"; alert = true; }
  if (spo2 < SPO2_LOW)    { issues += "SpO2 bajo;"; alert = true; }
  if (temp > TEMP_HIGH)   { issues += "Temp alta;"; alert = true; }
  else if (temp < TEMP_LOW){ issues += "Temp baja;"; alert = true; }
  return issues;
}
String buildSmsText(int hr, int spo2, float temp) {
  bool alert;
  String issues = buildSummary(hr, spo2, temp, alert);
  char vit[48];
  snprintf(vit, sizeof(vit), "FC:%dlpm SpO2:%d%% T:%.1fC", hr, spo2, temp);
  if (!alert)
    return String("[Monitor Biomedico] OK. ") + vit + ".";
  return String("[Monitor Biomedico] ALERTA. ") + vit + ". " + issues +
         " Sugerencia: reposo y vigilancia. Acuda a un medico.";
}
void initSensors() {
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  if (maxSensor.begin(Wire, I2C_SPEED_FAST)) {
    maxSensor.setup(0x1F, 4, 2, 100, 411, 4096); 
    maxOk = true;
    Serial.println("MAX30102 OK.");
  } else {
    Serial.println("MAX30102 NO detectado.");
  }
  if (mlx.begin()) { mlxOk = true; Serial.println("MLX90614 OK."); }
  else Serial.println("MLX90614 NO detectado.");
}
bool readPulseOx(int &hr, int &spo2) {
  if (!maxOk) return false;
  const int N = 100;
  static uint32_t irBuf[N], redBuf[N];
  for (int i = 0; i < N; i++) {
    while (!maxSensor.available()) maxSensor.check();
    redBuf[i] = maxSensor.getRed();
    irBuf[i]  = maxSensor.getIR();
    maxSensor.nextSample();
  }
  int32_t spo2v; int8_t spo2valid; int32_t hrv; int8_t hrvalid;
  maxim_heart_rate_and_oxygen_saturation(irBuf, N, redBuf, &spo2v, &spo2valid, &hrv, &hrvalid);
  if (hrvalid && hrv > 20 && hrv < 250) hr = hrv; else return false;
  if (spo2valid && spo2v > 50 && spo2v <= 100) spo2 = spo2v; else spo2 = 0;
  return true;
}
bool readVitals(int &hr, int &spo2, float &temp) {
  bool ok = readPulseOx(hr, spo2);
  temp = mlxOk ? mlx.readObjectTempC() : 0.0;
  if (ok && spo2 == 0) spo2 = 97;
  return ok && mlxOk;
}
String backendUrl(const String &path) {
  String scheme = cfg.useHttps ? "https://" : "http://";
  return scheme + cfg.backendHost + ":" + String(cfg.backendPort) + path;
}
String httpPostJson(const String &path, const String &body, bool withApiKey) {
  String response = "";
  if (cfg.mode == "wifi" && WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(backendUrl(path));
    http.addHeader("Content-Type", "application/json");
    if (withApiKey) http.addHeader("X-API-Key", cfg.apiKey);
    int code = http.POST(body);
    if (code > 0) response = http.getString();
    Serial.printf("POST %s -> %d\n", path.c_str(), code);
    http.end();
  } else if (cfg.mode == "gprs" && gsmReady) {
    if (!gsmClient.connect(cfg.backendHost.c_str(), cfg.backendPort)) {
      Serial.println("GPRS: no conecta al backend"); return "";
    }
    gsmClient.print(String("POST ") + path + " HTTP/1.1\r\n");
    gsmClient.print(String("Host: ") + cfg.backendHost + "\r\n");
    gsmClient.print("Content-Type: application/json\r\n");
    if (withApiKey) gsmClient.print(String("X-API-Key: ") + cfg.apiKey + "\r\n");
    gsmClient.print(String("Content-Length: ") + body.length() + "\r\n");
    gsmClient.print("Connection: close\r\n\r\n");
    gsmClient.print(body);
    unsigned long t0 = millis();
    while (gsmClient.connected() && millis() - t0 < 10000) {
      while (gsmClient.available()) { response += (char)gsmClient.read(); t0 = millis(); }
    }
    gsmClient.stop();
    int idx = response.indexOf("\r\n\r\n");      
    if (idx >= 0) response = response.substring(idx + 4);
  }
  return response;
}
bool provisionDevice() {
  StaticJsonDocument<128> doc;
  doc["device_uid"] = deviceUid;
  String body; serializeJson(doc, body);
  String resp = httpPostJson("/api/v1/devices/provision", body, false);
  if (resp.length() == 0) return false;
  StaticJsonDocument<512> out;
  if (deserializeJson(out, resp)) { Serial.println("Provision: JSON inválido"); return false; }
  if (!out.containsKey("api_key")) { Serial.println("Provision rechazada"); return false; }
  cfg.apiKey = out["api_key"].as<String>();
  cfg.pairingCode = out["pairing_code"].as<String>();
  saveConfig();
  Serial.println();
  Serial.println("======================================");
  Serial.print("  CÓDIGO DE VINCULACIÓN: ");
  Serial.println(cfg.pairingCode);
  Serial.println("  Introdúcelo en la app para vincular.");
  Serial.println("======================================");
  return true;
}
void sendMeasurement(int hr, int spo2, float temp) {
  StaticJsonDocument<128> doc;
  doc["heart_rate"] = hr;
  doc["spo2"] = spo2;
  doc["temperature"] = temp;
  String body; serializeJson(doc, body);
  String resp = httpPostJson("/api/v1/ingest", body, true);
  if (resp.indexOf("measurement") >= 0) Serial.println("Medición enviada al backend.");
}
void syncRemoteConfig() {
  String resp = "";
  if (cfg.mode == "wifi" && WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(backendUrl("/api/v1/devices/config/remote"));
    http.addHeader("X-API-Key", cfg.apiKey);
    if (http.GET() > 0) resp = http.getString();
    http.end();
  }
  if (resp.length()) {
    StaticJsonDocument<512> out;
    if (!deserializeJson(out, resp)) {
      if (out.containsKey("sms_numbers") && out["sms_numbers"].is<JsonArray>()) {
        String nums = "";
        for (JsonVariant v : out["sms_numbers"].as<JsonArray>()) {
          if (nums.length()) nums += ",";
          nums += v.as<String>();
        }
        if (nums.length()) { cfg.smsNumbers = nums; saveConfig(); }
      }
    }
  }
}
void setup() {
  Serial.begin(115200);
  delay(500);
#if STATUS_LED_PIN >= 0
  pinMode(STATUS_LED_PIN, OUTPUT);
#endif
  deviceUid = String("ESP32C3-") + macSuffix();
  Serial.println();
  Serial.print("Monitor Biomédico · "); Serial.println(deviceUid);
  loadConfig();
  initModem();
  if (!cfg.configured || cfg.wifiSsid.length() == 0 && cfg.mode == "wifi") {
    startPortal();
    return;
  }
  initSensors();
  bool online = (cfg.mode == "gprs") ? connectGprs() : connectWifi();
  if (!online) {
    Serial.println("Sin conexión de datos. Abriendo portal para reconfigurar...");
    startPortal();
    return;
  }
  if (cfg.apiKey.length() == 0) {
    if (!provisionDevice()) Serial.println("No se pudo provisionar (se reintenta luego).");
  } else if (cfg.pairingCode.length()) {
    Serial.print("Pendiente de vinculación. Código: ");
    Serial.println(cfg.pairingCode);
  }
  lastMeasure = millis() - MEASURE_INTERVAL_MS;  
  blink(3);
}
void loop() {
  if (portalMode) {
    dnsServer.processNextRequest();
    server.handleClient();
    return;
  }
  unsigned long now = millis();
  if (now - lastMeasure >= MEASURE_INTERVAL_MS) {
    lastMeasure = now;
    if (cfg.apiKey.length() == 0) provisionDevice();
    int hr = 0, spo2 = 0; float temp = 0;
    if (readVitals(hr, spo2, temp)) {
      Serial.printf("Lectura: FC=%d SpO2=%d Temp=%.1f\n", hr, spo2, temp);
      bool alert;
      buildSummary(hr, spo2, temp, alert);
      if (cfg.smsEvery || alert) {
        sendSmsAll(buildSmsText(hr, spo2, temp));
      }
      if (cfg.apiKey.length()) sendMeasurement(hr, spo2, temp);
      blink(alert ? 5 : 1);
    } else {
      Serial.println("Lectura inválida (¿dedo en el sensor?). Reintentando luego.");
    }
  }
  if (now - lastSync >= CONFIG_SYNC_MS) {
    lastSync = now;
    if (cfg.apiKey.length()) syncRemoteConfig();
  }
  delay(50);
}
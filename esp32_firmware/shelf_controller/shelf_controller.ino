/*
 * REEBJAI — ESP32 Shelf Controller Firmware
 * 
 * Board: ESP32 #2 (Shelf)
 * Role:  BLE Beacon + LCD Display + Buzzer
 * 
 * Communication:
 *   - Advertises BLE beacon name "REEBJAI_SHELF"
 *   - Connects to WiFi
 *   - Listens to Firebase RTDB: /boards/shelf_001/command
 *   - Reports status to:        /boards/shelf_001/status
 *
 * Wiring (แจกแจงทุกสาย):
 *
 *   [Buzzer Module — 3 ขา: VCC / I/O / GND]
 *   Buzzer VCC    → 3.3V (ใช้ pin 3V3 ของ ESP32)
 *   Buzzer I/O    → GPIO 32
 *   Buzzer GND    → GND
 *
 *   [LCD I2C 16x2 — 4 ขา: GND / VCC / SDA / SCL]
 *   LCD GND       → GND
 *   LCD VCC       → 5V (ใช้ pin VIN ของ ESP32)
 *   LCD SDA       → GPIO 21
 *   LCD SCL       → GPIO 22
 *
 *   [GND ร่วม]
 *   ESP32 GND     → GND ของทุกตัว (Buzzer, LCD) ลง rail เดียวกัน
 *
 * Libraries needed (install via Arduino Library Manager):
 *   - Firebase ESP Client by mobizt
 *   - LiquidCrystal_I2C
 *   - ESP32 BLE Arduino (built-in)
 */

#include <WiFi.h>
#include <FirebaseESP32.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLEAdvertising.h>

// ─── WiFi Config 
#define WIFI_SSID     "My home 2.4G"       // ← ใส่ชื่อ WiFi
#define WIFI_PASSWORD "0964136844"          // ← ใส่รหัส WiFi

// ─── Firebase Config 
#define FIREBASE_HOST "reejai-app-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "aIhmHLLUzCYR8EZXhQVG59dLgT93VpauswcjXr3l"

// ─── Board Identity 
#define BOARD_ID      "shelf_001"
#define BLE_NAME      "REEBJAI_SHELF"

// ─── Pin Assignments 
#define PIN_SDA     21
#define PIN_SCL     22
#define PIN_BUZZER  32

// Buzzer Module 3 ขา = Active LOW (LOW=ดัง, HIGH=เงียบ)
#define BUZZER_ON   LOW
#define BUZZER_OFF  HIGH

// ─── LCD (I2C address 0x27 — common for 16x2 LCD) 
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ─── Firebase Objects 
FirebaseData fbData;
FirebaseConfig fbConfig;
FirebaseAuth fbAuth;

// ─── State 
String currentState = "idle";
String lastCommandId = "";
unsigned long lastHeartbeat = 0;
const unsigned long HEARTBEAT_INTERVAL = 10000;

// ─── Setup 

void setup() {
  Serial.begin(115200);
  Serial.println("\n[REEBJAI] Shelf Controller Starting...");

  // Setup pins
  pinMode(PIN_BUZZER, OUTPUT);
  digitalWrite(PIN_BUZZER, BUZZER_OFF);  // เงียบตอนเริ่ม

  // Setup LCD
  Wire.begin(PIN_SDA, PIN_SCL);
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("REEBJAI Shelf");
  lcd.setCursor(0, 1);
  lcd.print("Starting...");

  // Connect WiFi
  connectWiFi();

  // Setup Firebase
  setupFirebase();

  // Setup BLE Beacon
  setupBleBeacon();

  // Report online
  reportStatus("idle");

  // Show ready on LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("REEBJAI Ready");
  lcd.setCursor(0, 1);
  lcd.print("Scan a product");

  Serial.println("[REEBJAI] Shelf Controller Ready!");
}

// ─── Main Loop 

void loop() {
  checkCommand();

  if (millis() - lastHeartbeat > HEARTBEAT_INTERVAL) {
    reportStatus(currentState);
    lastHeartbeat = millis();
  }

  delay(500);
}

// ─── WiFi 

void connectWiFi() {
  Serial.print("[WiFi] Connecting to ");
  Serial.println(WIFI_SSID);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 30) {
    delay(500);
    Serial.print(".");
    retries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Connected! IP: " + WiFi.localIP().toString());
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi OK");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP().toString());
    delay(1000);
  } else {
    Serial.println("\n[WiFi] FAILED!");
    lcd.clear();
    lcd.print("WiFi FAIL!");
    delay(2000);
    ESP.restart();
  }
}

// ─── Firebase 

void setupFirebase() {
  fbConfig.host = FIREBASE_HOST;
  fbConfig.signer.tokens.legacy_token = FIREBASE_AUTH;

  Firebase.begin(&fbConfig, &fbAuth);
  Firebase.reconnectWiFi(true);

  Serial.println("[Firebase] Connected");
}

void checkCommand() {
  String path = "/boards/" + String(BOARD_ID) + "/command";

  if (Firebase.getJSON(fbData, path)) {
    FirebaseJson &json = fbData.jsonObject();
    FirebaseJsonData result;

    json.get(result, "commandId");
    String cmdId = result.stringValue;

    if (cmdId.length() > 0 && cmdId != lastCommandId) {
      lastCommandId = cmdId;

      json.get(result, "type");
      String cmdType = result.stringValue;

      Serial.println("[CMD] Received: " + cmdType);
      executeCommand(cmdType, json);

      Firebase.setString(fbData, path + "/status", "done");
    }
  }
}

void executeCommand(String type, FirebaseJson &json) {
  FirebaseJsonData result;

  if (type == "show_product") {
    json.get(result, "payload/productName");
    String name = result.stringValue;
    json.get(result, "payload/price");
    float price = result.floatValue;

    showProduct(name, price);

  } else if (type == "lcd_message") {
    json.get(result, "payload/line1");
    String line1 = result.stringValue;
    json.get(result, "payload/line2");
    String line2 = result.stringValue;

    showMessage(line1, line2);

  } else if (type == "buzzer_on") {
    digitalWrite(PIN_BUZZER, BUZZER_ON);
    currentState = "buzzer_on";

  } else if (type == "buzzer_off") {
    digitalWrite(PIN_BUZZER, BUZZER_OFF);
    currentState = "idle";

  } else {
    Serial.println("[CMD] Unknown: " + type);
  }

  reportStatus(currentState);
}

// ─── LCD Actions 

void showProduct(String name, float price) {
  Serial.println("[LCD] Product: " + name + " = " + String(price) + " THB");

  // Truncate name if too long for 16-char LCD
  if (name.length() > 16) {
    name = name.substring(0, 16);
  }

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(name);
  lcd.setCursor(0, 1);
  lcd.print("Price: ");
  lcd.print(price, 0);
  lcd.print(" THB");

  // Short beep to confirm scan
  digitalWrite(PIN_BUZZER, BUZZER_ON);
  delay(80);
  digitalWrite(PIN_BUZZER, BUZZER_OFF);

  currentState = "showing_product";
}

void showMessage(String line1, String line2) {
  if (line1.length() > 16) line1 = line1.substring(0, 16);
  if (line2.length() > 16) line2 = line2.substring(0, 16);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(line1);
  lcd.setCursor(0, 1);
  lcd.print(line2);

  currentState = "showing_message";
}

// ─── BLE Beacon ──────────────────────────────────────

void setupBleBeacon() {
  BLEDevice::init(BLE_NAME);
  BLEServer *pServer = BLEDevice::createServer();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] Advertising as: " + String(BLE_NAME));
}

// ─── Status Reporting 

void reportStatus(String state) {
  String path = "/boards/" + String(BOARD_ID) + "/status";

  FirebaseJson json;
  json.set("boardId", BOARD_ID);
  json.set("role", "shelf");
  json.set("online", true);
  json.set("lastSeen", getTimestamp());
  json.set("currentState", state);

  Firebase.setJSON(fbData, path, json);
}

String getTimestamp() {
  unsigned long ms = millis();
  return String(ms / 1000) + "s uptime";
}

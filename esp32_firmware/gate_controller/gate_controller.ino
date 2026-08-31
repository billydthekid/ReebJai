/*
 * 
 * REEBJAI — ESP32 Gate Controller Firmware
 * 
 * 
 * ★ ระบบนี้ใช้ ESP32 แค่ตัวเดียว ไม่ใช้ Shelf board
 * ★ บอร์ดนี้ทำงาน 2 ครั้ง
 *     ครั้งที่ 1: เปิดประตูเข้าร้าน check-in สแกน QR
 *     ครั้งที่ 2: เปิดประตูออกจากร้าน (จ่ายเงินแล้ว)
 *     ถ้าไม่จ่าย  alarm ไฟแดงกระพริบ  buzzer
 * 
 * Board: ESP32 DevKit v1 (ตัวเดียว — Gate Controller)
 * Role:  BLE Beacon + Gate control (Buzzer, 2x LED, LCD)
 * 
 * Communication:
 *   - Advertises BLE beacon name "REEBJAI_GATE"
 *   - Connects to WiFi
 *   - Listens to Firebase RTDB: /boards/gate_001/command
 *   - Reports status to:        /boards/gate_001/status
 *
 * 
 * ตำแหน่งติดตั้ง — ประตูร้าน
 * 
 * 
 * ประตูร้านขนาดมาตรฐาน:
 *   - ความกว้าง: ~90 cm (ประตูบานเดียว) หรือ ~180 cm (ประตูคู่)
 *   - ความสูง:   ~210 cm
 *   - ประตูกระจกเลื่อนอัตโนมัติ (sliding door)
 * 
 * วางอุปกรณ์:
 *   
 *                                              
 *                         
 *       ประตู        90cm      ประตู         
 *       ซ้าย     ◄──────────► ขวา        
 *                         
 *           วาง ESP32 ตรงนี้   
 *        ข้างขอบประตูด้านใน    
 *        สูงจากพื้น ~100 cm    
 *        [LCD 16x2]  ← หันหน้าเข้าร้าน        
 *        [ Red] [ Green] [ Buzzer]     
 *        [ESP32 DevKit]                       
 *        ← กล่องพลาสติก ~15x10x5 cm        
 *      QR Code ติดข้างๆ สูง ~120 cm              
 *      (ให้ลูกค้าสแกนก่อนเข้า)                    
 *                                                
 *   
 * 
 * ขนาดกล่องใส่อุปกรณ์ 
 *   - กล่องพลาสติกใส: 15 x 10 x 5 cm
 *   - LCD โผล่หน้ากล่อง ให้อ่านได้
 *   - LED 2 ดวงโผล่ด้านบน
 *   - Buzzer อยู่ในกล่อง (เสียงทะลุได้)
 *   - จ่ายไฟ: USB cable จากปลั๊กในร้าน
 * 
 * 
 *
 * Wiring (แจกแจงทุกสาย):
 *
 *   [Red LED — 2 ขา]
 *   GPIO 25       → [220Ω] → LED ขายาว(+) → LED ขาสั้น(-) → GND
 *
 *   [Green LED — 2 ขา]
 *   GPIO 26       → [220Ω] → LED ขายาว(+) → LED ขาสั้น(-) → GND
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
 *   ESP32 GND     → GND ของทุกตัว (LED, Buzzer, LCD) ลง rail เดียวกัน
 *
 * Libraries needed (install via Arduino Library Manager):
 *   - Firebase ESP Client by mobizt
 *   - LiquidCrystal_I2C by Frank de Brabander
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
#define WIFI_SSID     "My home 2.4G"       //  ชื่อ WiFi
#define WIFI_PASSWORD "09641368XX"          // ใส่รหัส WiFi

// ─── Firebase Config 
#define FIREBASE_HOST "reejai-app-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "aIhmHLLUzCYR8EZXhQVG59dLgT93VpauswcjXr3l"

// ─── Board Identity 
#define BOARD_ID      "gate_001"
#define BLE_NAME      "REEBJAI_GATE"

// ─── Pin Assignments 
#define PIN_RED     25
#define PIN_GREEN   26
#define PIN_BUZZER  32
#define PIN_SDA     21
#define PIN_SCL     22

// Buzzer Module = Active HIGH (HIGH=ดัง, LOW=เงียบ)
#define BUZZER_ON   HIGH
#define BUZZER_OFF  LOW

// ─── LCD (I2C address 0x27 — common for 16x2) ───────
#define USE_LCD     false  // เปลี่ยนเป็น true ถ้าต่อจอสำเร็จ
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ─── Firebase Objects 
FirebaseData fbData;
FirebaseConfig fbConfig;
FirebaseAuth fbAuth;

// ─── State 
String currentState = "idle";
String lastCommandId = "";
unsigned long lastHeartbeat = 0;
const unsigned long HEARTBEAT_INTERVAL = 10000; // 10 seconds

// ─── Setup 

void setup() {
  Serial.begin(115200);
  Serial.println("\n[REEBJAI] Gate Controller Starting...");

  // Setup LED + Buzzer pins
  pinMode(PIN_RED, OUTPUT);
  pinMode(PIN_GREEN, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  
  // Start with all off
  setLed(false, false);
  digitalWrite(PIN_BUZZER, BUZZER_OFF);  // เงียบตอนเริ่ม

  // Setup LCD
  if (USE_LCD) {
    Wire.begin(PIN_SDA, PIN_SCL);
    lcd.init();
    lcd.backlight();
  }
  lcdShow("REEBJAI Gate", "Starting...");

  // Connect WiFi
  connectWiFi();

  // Setup Firebase
  setupFirebase();

  // Setup BLE Beacon
  setupBleBeacon();

  // Report online status
  reportStatus("idle");
  
  // Show ready
  blinkGreen(3);
  setLed(false, true); // เปิดเขียวค้างไว้เป็นสถานะ Standby (Idle)
  lcdShow("REEBJAI Gate", "Ready - Idle");
  Serial.println("[REEBJAI] Gate Controller Ready!");
}

// ─── Main Loop 

void loop() {
  // Check for new commands from Firebase
  checkCommand();

  // Send heartbeat every 10 seconds
  if (millis() - lastHeartbeat > HEARTBEAT_INTERVAL) {
    reportStatus(currentState);
    lastHeartbeat = millis();
  }

  delay(500); // Poll every 500ms
}

// ─── WiFi 

void connectWiFi() {
  Serial.print("[WiFi] Connecting to ");
  Serial.println(WIFI_SSID);
  lcdShow("WiFi...", WIFI_SSID);
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 30) {
    delay(500);
    Serial.print(".");
    retries++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Connected! IP: " + WiFi.localIP().toString());
    lcdShow("WiFi OK!", WiFi.localIP().toString());
    delay(1000);
  } else {
    Serial.println("\n[WiFi] FAILED! Restarting...");
    lcdShow("WiFi FAILED!", "Restarting...");
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
  lcdShow("Firebase OK!", "Waiting cmd...");
  delay(500);
}

void checkCommand() {
  String path = "/boards/" + String(BOARD_ID) + "/command";
  
  if (Firebase.getJSON(fbData, path)) {
    FirebaseJson &json = fbData.jsonObject();
    FirebaseJsonData result;
    
    // Check commandId to avoid re-executing
    json.get(result, "commandId");
    String cmdId = result.stringValue;
    
    if (cmdId.length() > 0 && cmdId != lastCommandId) {
      lastCommandId = cmdId;
      
      // Get command type
      json.get(result, "type");
      String cmdType = result.stringValue;
      
      Serial.println("[CMD] Received: " + cmdType);
      
      // Execute command
      executeCommand(cmdType, json);
      
      // Mark command as done
      Firebase.setString(fbData, path + "/status", "done");
    }
  }
}

void executeCommand(String type, FirebaseJson &json) {
  FirebaseJsonData result;

  if (type == "open_gate") {
    // อ่าน reason เพื่อแยก: เข้าร้าน vs ออกจากร้าน
    json.get(result, "reason");
    String reason = result.stringValue;

    // อ่าน payload สำหรับข้อความ LCD (ถ้ามี)
    json.get(result, "payload/line1");
    String line1 = result.stringValue;
    json.get(result, "payload/line2");
    String line2 = result.stringValue;

    if (reason == "payment_complete") {
      //  ครั้งที่ 2 เปิดประตูออก (จ่ายเงินแล้ว) 
      openGateExit(line1, line2);
    } else {
      //  ครั้งที่ 1 เปิดประตูเข้า (check-in) 
      openGateEntry();
    }

  } else if (type == "close_gate") {
    closeGate();
  } else if (type == "alarm") {
    triggerAlarm();
  } else if (type == "alarm_off") {
    stopAlarm();
  } else if (type == "lcd_message") {
    json.get(result, "payload/line1");
    String l1 = result.stringValue;
    json.get(result, "payload/line2");
    String l2 = result.stringValue;
    lcdShow(l1, l2);
    currentState = "lcd_message";
  } else if (type == "led_green") {
    setLed(false, true);
    lcdShow("LED: Green", "Manual control");
    currentState = "led_green";
  } else if (type == "led_red") {
    setLed(true, false);
    lcdShow("LED: Red", "Manual control");
    currentState = "led_red";
  } else if (type == "led_off") {
    setLed(false, false);
    lcdShow("LED: Off", "Idle");
    currentState = "idle";
  } else {
    Serial.println("[CMD] Unknown command: " + type);
    lcdShow("Unknown CMD:", type.substring(0, 16));
  }
  
  reportStatus(currentState);
}

// ─── Gate Actions 

//  ครั้งที่ 1 เปิดประตูเข้าร้าน (Check-in) 
void openGateEntry() {
  Serial.println("[GATE] Opening for ENTRY (check-in)...");
  setLed(false, true);  // Green
  lcdShow("> GATE OPEN <", "Welcome!");
  
  // Beep once (short)
  digitalWrite(PIN_BUZZER, BUZZER_ON);
  delay(100);
  digitalWrite(PIN_BUZZER, BUZZER_OFF);
  
  currentState = "gate_open_entry";
  reportStatus(currentState);
  
  // Auto-close after 5 seconds
  delay(5000);
  closeGate();
}

//  ครั้งที่ 2 เปิดประตูออกจากร้าน (จ่ายเงินแล้ว) 
void openGateExit(String line1, String line2) {
  Serial.println("[GATE] Opening for EXIT (payment complete)...");
  setLed(false, true);  // Green

  // แสดงข้อความจากแอป ถ้ามี หรือใช้ default
  if (line1.length() > 0) {
    lcdShow(line1, line2);
  } else {
    lcdShow("Payment OK!", "Thank you!");
  }
  
  // Beep twice (to distinguish from entry)
  digitalWrite(PIN_BUZZER, BUZZER_ON);
  delay(100);
  digitalWrite(PIN_BUZZER, BUZZER_OFF);
  delay(100);
  digitalWrite(PIN_BUZZER, BUZZER_ON);
  delay(100);
  digitalWrite(PIN_BUZZER, BUZZER_OFF);
  
  currentState = "gate_open_exit";
  reportStatus(currentState);
  
  // Auto-close after 5 seconds
  delay(5000);
  closeGate();
}

void closeGate() {
  Serial.println("[GATE] Closing...");
  // เปลี่ยนเป็นสีเขียวค้างไว้แทนสีแดงตอนประตูปิด (ตามที่ Request)
  setLed(false, true);  // Green
  lcdShow("> GATE CLOSED <", "Please check in");
  currentState = "gate_closed";
  reportStatus(currentState);
  
  // After 2 seconds, go to idle
  delay(2000);
  // Idle ก็ให้เป็นสีเขียว (พร้อมใช้งาน)
  setLed(false, true);
  lcdShow("REEBJAI Gate", "Ready - Idle");
  currentState = "idle";
}

void triggerAlarm() {
  Serial.println("[ALARM] !! UNPAID EXIT !!");
  currentState = "alarm";
  reportStatus(currentState);
  
  // Flash red + buzzer for 5 seconds
  for (int i = 0; i < 10; i++) {
    setLed(true, false); // ไฟแดงกระพริบเมื่อไม่จ่ายตัง!
    digitalWrite(PIN_BUZZER, BUZZER_ON);
    lcdShow("!! ALARM !!", "UNPAID EXIT");
    delay(250);
    setLed(false, false);
    digitalWrite(PIN_BUZZER, BUZZER_OFF);
    delay(250);
  }
  
  // กลับสู่สถานะปกติ (เขียว)
  setLed(false, true);
  lcdShow("REEBJAI Gate", "Ready - Idle");
  currentState = "idle";
}

void stopAlarm() {
  Serial.println("[ALARM] Stopped");
  digitalWrite(PIN_BUZZER, BUZZER_OFF);
  setLed(false, true); // เปลี่ยนกลับเป็นเขียว
  lcdShow("Alarm stopped", "Ready - Idle");
  currentState = "idle";
}

// ─── LED Control (2 LEDs: Red + Green) 

void setLed(bool red, bool green) {
  digitalWrite(PIN_RED, red ? HIGH : LOW);
  digitalWrite(PIN_GREEN, green ? HIGH : LOW);
}

void blinkGreen(int times) {
  for (int i = 0; i < times; i++) {
    setLed(false, true);
    delay(200);
    setLed(false, false);
    delay(200);
  }
}

// ─── LCD Display 

void lcdShow(String line1, String line2) {
  if (!USE_LCD) return;

  // Truncate to 16 chars for LCD 16x2
  if (line1.length() > 16) line1 = line1.substring(0, 16);
  if (line2.length() > 16) line2 = line2.substring(0, 16);
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(line1);
  lcd.setCursor(0, 1);
  lcd.print(line2);
}

// ─── BLE Beacon 

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
  json.set("role", "gate");
  json.set("online", true);
  json.set("lastSeen", getTimestamp());
  json.set("currentState", state);
  
  Firebase.setJSON(fbData, path, json);
}

String getTimestamp() {
  // Simple timestamp from millis (use NTP for real time)
  unsigned long ms = millis();
  return String(ms / 1000) + "s uptime";
}

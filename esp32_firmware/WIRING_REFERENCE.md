# REEBJAI ESP32 Wiring Reference

คู่มือการต่อสายอุปกรณ์ทั้งหมดของ ESP32 สำหรับระบบ Gate Controller


## ESP32 Gate Controller (gate_001)

อุปกรณ์ที่ใช้ มี 4 ชิ้น คือ Red LED (2 ขา) Green LED (2 ขา) Buzzer Module (3 ขา) และ LCD I2C 16x2 (4 ขา)

### Red LED

LED มี 2 ขา คือ ขายาว (+) และ ขาสั้น (-)

| สายของ LED | ต่อกับ |
|-----------|--------|
| ขายาว (+) | ตัวต้านทาน 220 โอห์ม แล้วต่อไป GPIO 25 |
| ขาสั้น (-) | GND |

### Green LED

LED มี 2 ขา คือ ขายาว (+) และ ขาสั้น (-)

| สายของ LED | ต่อกับ |
|-----------|--------|
| ขายาว (+) | ตัวต้านทาน 220 โอห์ม แล้วต่อไป GPIO 26 |
| ขาสั้น (-) | GND |

### Buzzer Module

Buzzer Module มี 3 ขา คือ VCC, I/O (Signal) และ GND

| สายของ Buzzer | ต่อกับ |
|-------------|--------|
| VCC | 3V3 (pin 3.3V ของ ESP32) |
| I/O (Signal) | GPIO 32 |
| GND | GND |

Buzzer Module ต้องต่อ VCC ด้วย ใช้ 3.3V จาก pin 3V3 ของ ESP32 ถ้าเป็น 5V module ให้ต่อ VCC เข้า VIN แทน

### LCD I2C 16x2

LCD I2C มี 4 ขา คือ GND, VCC, SDA และ SCL

| สายของ LCD | ต่อกับ |
|-----------|--------|
| GND | GND |
| VCC | VIN (pin 5V ของ ESP32) |
| SDA | GPIO 21 |
| SCL | GPIO 22 |

LCD ต้องใช้ 5V ต่อผ่าน pin VIN ของ ESP32 LCD I2C address ปกติคือ 0x27 ถ้าไม่ขึ้นให้ลอง 0x3F

### GND ร่วม

ESP32 GND ต่อลง GND rail บน breadboard แล้วอุปกรณ์ทุกตัว (LED ทั้ง 2 ดวง Buzzer GND และ LCD GND) ต่อลง rail เดียวกัน

### สรุป Pin ทั้งหมดของ ESP32

| ESP32 Pin | ต่อไปที่ |
|-----------|---------|
| 3V3 | Buzzer VCC |
| VIN (5V) | LCD VCC |
| GND | GND rail (ทุกตัวร่วม) |
| GPIO 25 | ตัวต้านทาน 220 โอห์ม แล้วต่อ Red LED (+) |
| GPIO 26 | ตัวต้านทาน 220 โอห์ม แล้วต่อ Green LED (+) |
| GPIO 32 | Buzzer I/O |
| GPIO 21 | LCD SDA |
| GPIO 22 | LCD SCL |

LCD แสดงสถานะต่างๆ เช่น GATE OPEN, GATE CLOSED, ALARM และ Ready Idle


## ESP32 Shelf Controller (shelf_001) ไม่ได้ใช้งานในปัจจุบัน

เก็บไว้เป็น reference เท่านั้น ระบบปัจจุบันใช้แค่ Gate Controller ตัวเดียว

อุปกรณ์ มี 2 ชิ้น คือ Buzzer Module (3 ขา) และ LCD I2C 16x2 (4 ขา)

### Buzzer Module

| สายของ Buzzer | ต่อกับ |
|-------------|--------|
| VCC | 3V3 (pin 3.3V ของ ESP32) |
| I/O (Signal) | GPIO 32 |
| GND | GND |

### LCD I2C 16x2

| สายของ LCD | ต่อกับ |
|-----------|--------|
| GND | GND |
| VCC | VIN (pin 5V ของ ESP32) |
| SDA | GPIO 21 |
| SCL | GPIO 22 |

### สรุป Pin ทั้งหมดของ ESP32 Shelf Controller

| ESP32 Pin | ต่อไปที่ |
|-----------|---------|
| 3V3 | Buzzer VCC |
| VIN (5V) | LCD VCC |
| GND | GND rail (ทุกตัวร่วม) |
| GPIO 32 | Buzzer I/O |
| GPIO 21 | LCD SDA |
| GPIO 22 | LCD SCL |


## วิธีตั้งค่า

### 1 ตั้งค่า Arduino IDE

1. ติดตั้ง Arduino IDE เวอร์ชัน 2.x
2. เพิ่ม ESP32 board โดยไปที่ File แล้วเลือก Preferences แล้วเพิ่ม URL นี้ในช่อง Board Manager URLs

```
https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
```

3. ไปที่ Tools แล้วเลือก Board Manager แล้วค้นหา ESP32 แล้วกด Install
4. เลือก board เป็น ESP32 Dev Module

### 2 ติดตั้ง Libraries

ติดตั้งผ่าน Sketch แล้วเลือก Include Library แล้วเลือก Manage Libraries

| Library | ผู้พัฒนา |
|---------|---------|
| Firebase ESP32 Client | Mobizt |
| LiquidCrystal I2C | Frank de Brabander |
| ArduinoJson | Benoit Blanchon |

### 3 ตั้งค่า Firebase Realtime Database

1. เปิด Firebase Console แล้วไปที่ Realtime Database แล้วกด Create Database
2. เลือก region แล้วเริ่มในโหมด test mode
3. คัดลอก database URL เช่น reejai-app-default-rtdb.firebaseio.com
4. ไปที่ Project Settings แล้วเลือก Service accounts แล้วเลือก Database secrets แล้วคัดลอก secret

### 4 Upload Firmware

1. เปิดไฟล์ gate_controller.ino
2. แก้ค่า YOUR_WIFI_SSID, YOUR_WIFI_PASSWORD และ YOUR_DATABASE_SECRET ในโค้ด
3. เลือก COM port ที่ถูกต้อง
4. กด Upload

### 5 ตรวจสอบ

1. เปิด Serial Monitor ที่ 115200 baud
2. ต้องเห็นข้อความ REEBJAI Gate Controller Ready
3. ตรวจ Firebase Console ที่ Realtime Database ใน path /boards/gate_001/status ต้องเห็น online เป็น true

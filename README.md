# REEBJAI Smart Convenience Store Checkout

ระบบร้านสะดวกซื้อแบบ self-checkout ที่ลูกค้าสามารถสแกนสินค้าและจ่ายเงินผ่านแอปมือถือ โดยไม่ต้องผ่านแคชเชียร์ พร้อมระบบ Web Admin Panel สำหรับจัดการสาขาร้าน สต๊อกสินค้า พิมพ์บาร์โค้ด และดูยอดเงิน

ขั้นตอนหลัก คือ ลูกค้าสแกน QR Code เข้าร้าน จากนั้นประตูจะเปิดให้เข้า จากนั้นสแกนบาร์โค้ดสินค้าใส่ตะกร้าในแอป จ่ายเงินผ่านแอป แล้วประตูจะเปิดให้ออก

โปรเจกต์นี้พัฒนาด้วย Flutter และรองรับเฉพาะ Android เท่านั้น ใช้ Firebase เป็น backend (ชื่อโปรเจกต์ Firebase คือ reejai-app) และใช้ ESP32 เป็นตัวควบคุมประตูร้าน


## สำหรับผู้ที่ต้องการใช้งานแอป (ไม่ต้อง build เอง)

ถ้าต้องการแค่ทดลองใช้งานแอป สามารถดาวน์โหลดไฟล์ APK ที่ build ไว้แล้วได้เลย โดยไม่ต้องติดตั้ง Android Studio หรือเครื่องมืออื่นใด

ขั้นตอน
1. ดาวน์โหลดไฟล์ APK จากหน้า Releases ของโปรเจกต์
2. ส่งไฟล์ APK ไปที่มือถือ Android ผ่าน LINE, Email หรือ Google Drive
3. เปิดไฟล์ APK บนมือถือแล้วกด Install
4. ถ้ามือถือบล็อคการติดตั้ง ให้ไปที่ Settings แล้วเลือก Install unknown apps แล้วอนุญาต
5. เปิดแอปแล้วกด Allow ตอนแอปขอสิทธิ์กล้อง

ต้องใช้มือถือ Android เวอร์ชัน 5.0 (Lollipop) ขึ้นไป


## สำหรับนักพัฒนาที่ต้องการ build เองหรือพัฒนาต่อ

ถ้าต้องการแก้ไขโค้ดหรือ build APK เอง ต้องเตรียมสิ่งเหล่านี้

สิ่งที่ต้องมี
- คอมพิวเตอร์ที่ติดตั้ง Android Studio (ดาวน์โหลดจาก https://developer.android.com/studio)
- Flutter SDK เวอร์ชัน 3.x ขึ้นไป (ดาวน์โหลดจาก https://flutter.dev)
- มือถือ Android สำหรับทดสอบแอป (ต้องเปิด USB Debugging)
- สาย USB สำหรับเชื่อมต่อมือถือกับคอมพิวเตอร์

Android Studio จำเป็นต้องติดตั้งเพราะมี Android SDK, Emulator และเครื่องมือ build ที่ Flutter ต้องใช้ แม้จะเขียนโค้ดใน VS Code ก็ยังต้องมี Android Studio อยู่ดี


## สิ่งที่ต้องติดตั้งก่อนใช้งาน

ด้านล่างนี้เป็นรายละเอียดการติดตั้งทั้งฝั่ง Flutter (แอปมือถือ) และฝั่ง ESP32 (ฮาร์ดแวร์ประตู)

### สำหรับ Flutter App (แอปมือถือ)

**เครื่องมือที่ต้องมี**

- Flutter SDK เวอร์ชัน 3.x ขึ้นไป
- Dart SDK เวอร์ชัน 3.11.1 ขึ้นไป (มากับ Flutter)
- Android Studio หรือ VS Code ที่มี Flutter Extension
- Firebase CLI สำหรับ setup Firebase project

**Flutter Packages ที่ใช้ในโปรเจกต์ (อยู่ใน pubspec.yaml)**

รันคำสั่ง flutter pub get เพื่อติดตั้ง package ทั้งหมดอัตโนมัติ

| Package | เวอร์ชัน | ใช้ทำอะไร |
|---------|----------|-----------|
| firebase_core | 4.5.0 | เชื่อมต่อ Firebase เป็น package หลักที่ทุก Firebase service ต้องใช้ |
| cloud_firestore | 6.1.3 | ฐานข้อมูล Firestore สำหรับเก็บข้อมูลร้าน สินค้า session และ payment |
| firebase_database | 12.1.4 | Firebase Realtime Database สำหรับส่งคำสั่งไป ESP32 แบบทันที |
| provider | 6.1.2 | จัดการ state ของแอป เช่น ตะกร้าสินค้า session ปัจจุบัน สถานะบอร์ด |
| flutter_stripe | 11.3.0 | ระบบชำระเงินผ่าน Stripe รองรับบัตรเครดิตและ debit |
| mobile_scanner | 6.0.2 | สแกน QR Code และ Barcode ผ่านกล้องมือถือ |
| flutter_blue_plus | 1.35.2 | เชื่อมต่อ Bluetooth Low Energy สำหรับตรวจจับ ESP32 ที่อยู่ใกล้ |
| uuid | 4.5.1 | สร้าง ID ที่ไม่ซ้ำกัน สำหรับ session, payment, command |
| intl | 0.20.2 | จัดรูปแบบวันที่และตัวเลขให้ถูกต้องตาม locale |
| http | 1.2.2 | เรียก HTTP API เช่น Stripe API |
| image_picker | 1.2.1 | เลือกรูปภาพจากกล้องหรือแกลเลอรี |
| qr_flutter | 4.1.0 | สร้าง QR Code แสดงในแอป |
| cupertino_icons | 1.0.8 | ชุดไอคอนสไตล์ iOS |

**วิธีติดตั้ง Flutter packages**

```bash
cd reeb_jai_app
flutter pub get
```

### สำหรับ ESP32 (ฮาร์ดแวร์ประตู)

**เครื่องมือที่ต้องมี**

- Arduino IDE เวอร์ชัน 2.x
- สาย USB สำหรับต่อ ESP32 กับคอมพิวเตอร์

**เพิ่ม ESP32 Board ใน Arduino IDE**

ไปที่ File แล้วเลือก Preferences แล้วเพิ่ม URL นี้ในช่อง Additional Boards Manager URLs

```
https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
```

จากนั้นไปที่ Tools แล้วเลือก Board แล้วเลือก Boards Manager แล้วค้นหา esp32 แล้วกด Install

**Arduino Libraries ที่ต้องติดตั้ง**

ติดตั้งผ่าน Tools แล้วเลือก Manage Libraries ใน Arduino IDE

| Library | ผู้พัฒนา | ใช้ทำอะไร |
|---------|---------|-----------|
| Firebase ESP32 Client | Mobizt | เชื่อมต่อ ESP32 กับ Firebase Realtime Database เพื่อรับคำสั่งเปิดปิดประตู |
| LiquidCrystal I2C | Frank de Brabander | ควบคุมจอ LCD 16x2 แบบ I2C สำหรับแสดงสถานะประตู |
| ArduinoJson | Benoit Blanchon | อ่านและสร้างข้อมูล JSON สำหรับสื่อสารกับ Firebase |

ESP32 BLE Arduino เป็น library ที่มากับ ESP32 Board Package อยู่แล้ว ไม่ต้องติดตั้งเพิ่ม

### สำหรับ Firebase (ชื่อโปรเจกต์ Firebase คือ reejai-app)

โปรเจกต์นี้ใช้ Firebase ของ Google เป็น backend ชื่อโปรเจกต์คือ reejai-app ต้องเปิดใช้งาน service เหล่านี้

- Cloud Firestore สำหรับเก็บข้อมูลร้าน สินค้า session payment และ receipt
- Realtime Database สำหรับส่งคำสั่งไป ESP32 แบบ real-time

ข้อมูลเชื่อมต่อ Firebase อยู่ในไฟล์ lib/firebase_options.dart ซึ่ง Flutter สร้างให้อัตโนมัติจากคำสั่ง flutterfire configure

### สำหรับ Stripe (ระบบจ่ายเงิน)

สมัครบัญชีที่ stripe.com แล้วคัดลอก API keys มาใส่ในไฟล์ lib/core/constants/stripe_config.dart

```dart
class StripeConfig {
  static const String publishableKey = 'pk_test_ใส่ key ของคุณ';
  static const String secretKey = 'sk_test_ใส่ secret ของคุณ';
}
```

ถ้ายังไม่ใส่ Stripe key ระบบจะ mock payment โดยจ่ายสำเร็จอัตโนมัติ เพื่อให้ทดสอบ flow ได้


## Web Admin Panel (ระบบจัดการร้านและสินค้าผ่านเว็บ)

โปรเจกต์นี้มีระบบเว็บสำหรับผู้ดูแลร้าน (Admin) พัฒนาด้วย HTML, JavaScript และเชื่อมต่อตรงกับ Firebase Firestore โดยไม่ต้องรันเซิร์ฟเวอร์แยก สามารถเปิดใช้งานในเครื่องหรือ Deploy ขึ้น Vercel ได้ทันที

### ความสามารถของระบบ Web Admin

1. ระบบจัดการสาขาร้าน (Store Management)
- เพิ่มสาขาใหม่ โดยระบุชื่อร้าน ที่อยู่ และรหัส QR Code ID
- ระบบจะสร้าง QR Code ของสาขาให้อัตโนมัติ
- สามารถกดสั่งพิมพ์ QR Code เพื่อนำไปติดที่หน้าประตูทางเข้าร้านได้ทันที
- ดูรายการสาขาทั้งหมด พร้อมปุ่มเข้าไปจัดการสต๊อกสินค้าและดูยอดเงินของแต่ละสาขา

2. ระบบจัดการสินค้าและสต๊อก (Inventory Manager)
- เพิ่มสินค้าใหม่เข้าสาขา โดยเลือกหมวดหมู่ (อาหารแช่แข็ง เครื่องดื่ม ขนมขบเคี้ยว)
- กำหนดบาร์โค้ด ชื่อสินค้า ราคาขาย ต้นทุน จำนวนสต๊อก วันหมดอายุ และหน่วยนับ
- ระบบจะสร้างบาร์โค้ดสินค้า (Barcode Catalog) ให้อัตโนมัติ
- มีปุ่มสั่งพิมพ์บาร์โค้ด เพื่อนำไปแปะบนสินค้าจริงสำหรับให้ลูกค้าสแกนในแอป
- จัดการแก้ไขสต๊อก ลบสินค้า และอัปเดตข้อมูลแบบ Real-time ลง Firestore

3. ระบบตรวจสอบการชำระเงิน (Payments History)
- ดูประวัติรายการคำสั่งซื้อของแต่ละสาขา
- ตรวจสอบยอดเงิน และสถานะการชำระเงินของลูกค้า

### ไฟล์หน้าเว็บในโฟลเดอร์ assets/

- assets/index.html หน้ารวมเมนูหลักและ Login
- assets/store-stock.html หน้าระบบจัดการสาขาและสต๊อกสินค้า
- assets/qr-barcode.html หน้าสร้างและพิมพ์ QR Code ร้าน และบาร์โค้ดสินค้า
- assets/payments.html หน้าตรวจสอบรายการชำระเงิน

### วิธีนำ Web Admin ขึ้น Vercel (Deploy to Vercel)

1. เข้าเว็บไซต์ Vercel แล้วเลือก Import Git Repository ของโปรเจกต์นี้
2. ในหน้าตั้งค่าโปรเจกต์ (Project Settings)
- ตรงส่วน Root Directory ให้กด Edit แล้วระบุเป็น assets แล้วกด Save
- ตรงส่วน Build and Output Settings ในช่อง Framework Preset ให้เลือกเป็น Other
- ช่อง Build Command ให้เว้นว่างไว้ (ไม่ต้องใส่คำสั่ง build)
3. กด Deploy เพื่อเริ่มการทำงาน
4. เมื่อ Deploy สำเร็จ จะได้ URL เว็บไซต์สำหรับเปิดใช้งานระบบจัดการร้านและพิมพ์บาร์โค้ดได้ทันที


## ภาพรวมระบบ

| ส่วน | เทคโนโลยี | หน้าที่ |
|------|-----------|--------|
| Flutter App | Flutter + Firebase | แอปลูกค้า สำหรับลงทะเบียน สแกน QR และ Barcode จ่ายเงิน |
| Web Admin | HTML + JS + Firestore | เว็บจัดการร้าน เพิ่มสินค้า สร้างและพิมพ์ QR/Barcode ดูยอดเงิน |
| Cloud Firestore | Firestore | ฐานข้อมูลหลัก เก็บข้อมูลร้าน สินค้า session payment receipt |
| Firebase RTDB | Realtime Database | สั่ง ESP32 แบบ real-time เช่น เปิดประตู alarm แสดงข้อความ LCD |
| ESP32 Gate | ESP32 ตัวเดียว | ควบคุมประตู เปิดปิด 2 ครั้ง (เข้าและออก) ไฟ LED Buzzer LCD BLE |

ระบบใช้ ESP32 แค่ตัวเดียว วางข้างประตูทางเข้าออก ทำงาน 2 ครั้ง คือตอนเข้าร้านและตอนออกจากร้าน


## ขั้นตอนการทำงานของระบบ

### ขั้นที่ 1 ลงทะเบียน (ทำครั้งเดียว)

ผู้ใช้กรอกชื่อ นามสกุล เบอร์โทร แอปจะบันทึกลง Firestore ใน collection users แล้วได้ userId เก็บไว้ใช้ตลอด

### ขั้นที่ 2 เข้าร้าน (ESP32 ทำงานครั้งที่ 1 เปิดประตูเข้า)

ผู้ใช้สแกน QR Code ที่หน้าประตูร้าน เช่น QR มีค่า REEBJAI_STORE_001

แอปจะทำงานดังนี้
1. query Firestore หาร้านที่ตรงกับ qrCode
2. ได้ข้อมูลร้าน (storeId ชื่อ ที่อยู่)
3. สร้าง Session ที่มี sessionId userId storeId และ status เป็น active
4. บันทึก Session ลง Firestore

จากนั้นแอปส่งคำสั่ง open_gate ผ่าน Firebase RTDB ไปที่ path /boards/gate_001/command โดยมี reason เป็น checkin

ESP32 รับคำสั่งแล้วทำงานดังนี้
- ไฟเขียวติด
- Buzzer ดังสั้น 1 ครั้ง
- LCD แสดง GATE OPEN / Welcome
- รอ 5 วินาที แล้วปิดประตูอัตโนมัติ
- กลับสู่สถานะ Idle

แอปนำผู้ใช้ไปหน้า Check-in Success

### ขั้นที่ 3 สแกนสินค้าใส่ตะกร้า

ผู้ใช้สแกนบาร์โค้ดบนสินค้าจริงผ่านกล้องมือถือ แอป query Firestore หาสินค้าที่ตรงกับ barcode แล้วเพิ่มเข้าตะกร้า ถ้าสินค้าซ้ำจะเพิ่มจำนวน สแกนสินค้าเพิ่มได้เรื่อยๆ จนครบ

ขั้นตอนนี้ใช้แค่มือถือ ไม่มี shelf board

### ขั้นที่ 4 ตะกร้าสินค้าและ Checkout

ผู้ใช้ดูรายการสินค้าในตะกร้า ลบหรือเพิ่มจำนวนได้ แล้วกด Checkout เพื่อไปหน้า Payment

### ขั้นที่ 5 จ่ายเงิน

ผู้ใช้เลือกวิธีจ่ายเงิน เช่น Credit Card หรือ Debit Card ผ่าน Stripe

แอปจะทำงานดังนี้
1. สร้าง Payment ที่มี paymentId amount และ status เป็น pending
2. เรียก Stripe API เพื่อชำระเงิน
3. อัปเดต Payment status เป็น paid
4. อัปเดต Session status เป็น paid
5. สร้าง Receipt และคำนวณ Points
6. บันทึกทุกอย่างลง Firestore

### ขั้นที่ 6 ออกจากร้าน (ESP32 ทำงานครั้งที่ 2 เปิดประตูออก)

**กรณีจ่ายเงินแล้ว**

แอปส่ง open_gate พร้อม reason เป็น payment_complete ไปที่ ESP32

ESP32 ทำงานดังนี้
- ไฟเขียวติด
- LCD แสดง Payment OK
- Buzzer ดัง 2 ครั้งสั้น
- ประตูเปิด 5 วินาทีแล้วปิดอัตโนมัติ
- กลับสู่สถานะ Idle

**กรณีไม่จ่ายเงิน (session ยังเป็น active)**

ระบบส่ง alarm ไปที่ ESP32

ESP32 ทำงานดังนี้
- ไฟแดงกระพริบ 5 วินาที
- Buzzer ดังต่อเนื่อง
- LCD แสดง ALARM / UNPAID EXIT
- ประตูล็อค

พนักงานสามารถส่ง alarm_off เพื่อหยุดสัญญาณเตือน


## ระบบร้าน สินค้า และสาขา

### แนวคิดหลัก

Firestore แบ่งเป็น collection หลักๆ ดังนี้

- stores เก็บข้อมูลร้านแต่ละสาขา มี storeId ชื่อ ที่อยู่ และ qrCode สำหรับให้ลูกค้าสแกน
- products เก็บข้อมูลสินค้า มี barcode ชื่อ ราคา stock
- sessions เก็บข้อมูล session ของลูกค้าแต่ละครั้ง มี userId storeId และ status

### วิธีเพิ่มสาขาใหม่

1. เพิ่มข้อมูลร้านในไฟล์ lib/core/seed/seed_data.dart หรือเพิ่มผ่าน Web Admin Panel

```dart
{
  'storeId': 'store_003',
  'name': 'REEBJAI Store Silom',
  'address': 'Silom Road, Bangkok 10500',
  'qrCode': 'REEBJAI_STORE_003',
  'isOpen': true,
},
```

2. เพิ่มข้อมูลร้านในไฟล์ assets/qr-barcode.html หรือสร้างผ่าน Web Admin Panel เพื่อสร้าง QR Code

```javascript
{ id: 'store_003', name: 'REEBJAI Store Silom', address: 'Silom Rd', qr: 'REEBJAI_STORE_003' },
```

3. พิมพ์ QR Code ไปติดหน้าร้าน

4. หากเพิ่มในโค้ด ให้กดปุ่ม Seed ในแอป หรือเรียก SeedData.forceReseedAll() เพื่อ import ข้อมูลเข้า Firestore

### วิธีเพิ่มสินค้าใหม่

1. เพิ่มข้อมูลสินค้าในไฟล์ lib/core/seed/seed_data.dart หรือเพิ่มผ่าน Web Admin Panel

```dart
{
  'productId': 'prod_011',
  'barcode': '8850123456789',
  'name': 'ชื่อสินค้าใหม่',
  'price': 25.0,
  'category': 'snack',
  'imageUrl': '',
  'stock': 50,
},
```

2. เพิ่มข้อมูลในไฟล์ assets/qr-barcode.html หรือสร้างผ่าน Web Admin Panel เพื่อสร้าง Barcode

```javascript
{ name: 'ชื่อสินค้าใหม่', barcode: '8850123456789', price: 25 },
```

3. พิมพ์ Barcode ไปติดบนสินค้า


## ESP32 Gate Controller

ใช้ ESP32 ตัวเดียว วางข้างประตูทางเข้าออก ทำหน้าที่ควบคุมประตู

### การทำงานครั้งที่ 1 ตอนเข้าร้าน (Check-in)

| เหตุการณ์ | คำสั่ง | LED | Buzzer | LCD | ระยะเวลา |
|-----------|--------|-----|--------|-----|----------|
| ลูกค้าสแกน QR | open_gate (reason: checkin) | เขียว | Beep 1 ครั้ง | GATE OPEN / Welcome | 5 วินาที |
| ปิดอัตโนมัติ | auto | เขียว | ไม่มี | GATE CLOSED แล้วกลับ Idle | 2 วินาที |

### การทำงานครั้งที่ 2 ตอนออกจากร้าน (Exit)

| เหตุการณ์ | คำสั่ง | LED | Buzzer | LCD | ระยะเวลา |
|-----------|--------|-----|--------|-----|----------|
| จ่ายแล้ว | open_gate (reason: payment_complete) | เขียว | Beep 2 ครั้ง | Payment OK | 5 วินาที |
| ไม่จ่าย | alarm | แดงกระพริบ | ดัง 5 วินาที | ALARM / UNPAID EXIT | 5 วินาที |
| หยุด alarm | alarm_off | เขียว | หยุด | Ready Idle | ทันที |

### คำสั่งทั้งหมดที่ ESP32 รับได้

| คำสั่ง (type) | reason | การทำงาน |
|---------------|--------|----------|
| open_gate | checkin | เปิดประตูเข้า ไฟเขียว beep LCD Welcome |
| open_gate | payment_complete | เปิดประตูออก ไฟเขียว beep LCD Payment OK |
| close_gate | ไม่มี | ปิดประตู ไฟเขียว |
| alarm | ไม่มี | สัญญาณเตือน ไฟแดงกระพริบ buzzer 5 วินาที |
| alarm_off | ไม่มี | หยุดสัญญาณเตือน |
| lcd_message | ไม่มี | แสดงข้อความบน LCD 2 บรรทัด |

### การสื่อสารระหว่าง Flutter App กับ ESP32

การสื่อสารผ่าน Firebase Realtime Database

- Flutter App เขียนคำสั่งไปที่ path /boards/gate_001/command โดยมี type commandId reason และ payload
- ESP32 อ่านคำสั่งจาก path เดียวกัน โดย poll ทุก 500 มิลลิวินาที แล้วทำงานตามคำสั่ง
- ESP32 เขียนสถานะไปที่ path /boards/gate_001/status โดยมี online และ currentState
- Flutter App อ่านสถานะจาก path เดียวกัน เพื่อแสดงสถานะบอร์ดในแอป

### Wiring (การต่อสาย)

| ESP32 Pin | ต่อไปที่ | หมายเหตุ |
|-----------|---------|----------|
| GPIO 25 | ตัวต้านทาน 220 โอห์ม แล้วต่อ Red LED ขายาว (+) | ขาสั้น (-) ต่อ GND |
| GPIO 26 | ตัวต้านทาน 220 โอห์ม แล้วต่อ Green LED ขายาว (+) | ขาสั้น (-) ต่อ GND |
| GPIO 32 | Buzzer I/O (Signal) | Buzzer VCC ต่อ 3V3 และ GND ต่อ GND |
| GPIO 21 | LCD SDA | |
| GPIO 22 | LCD SCL | LCD VCC ต่อ VIN (5V) และ GND ต่อ GND |
| 3V3 | Buzzer VCC | |
| VIN (5V) | LCD VCC | |
| GND | GND ร่วมของทุกอุปกรณ์ (LED Buzzer LCD) | ต่อลง GND rail บน breadboard |

### ตำแหน่งติดตั้ง

วาง ESP32 ข้างขอบประตูด้านใน สูงจากพื้นประมาณ 100 เซนติเมตร ใส่ในกล่องพลาสติกขนาดประมาณ 15 x 10 x 5 เซนติเมตร

- LCD โผล่หน้ากล่อง หันหน้าออกทางประตู ให้ลูกค้าอ่านได้
- LED 2 ดวงโผล่ด้านบน
- Buzzer อยู่ในกล่อง เสียงทะลุได้
- จ่ายไฟผ่าน USB cable จากปลั๊กในร้าน
- ยึดกับผนังหรือเสาด้วยสกรูหรือแถบกาว 2 หน้า
- QR Code ติดข้างๆ สูงประมาณ 120 เซนติเมตร ให้ลูกค้าสแกนก่อนเข้า

### วิธี Upload Firmware

1. ติดตั้ง Arduino IDE จาก https://www.arduino.cc/en/software
2. เพิ่ม ESP32 Board ตามที่อธิบายในส่วน สิ่งที่ต้องติดตั้ง
3. ติดตั้ง Libraries ตามตารางในส่วน Arduino Libraries ที่ต้องติดตั้ง
4. เปิดไฟล์ esp32_firmware/gate_controller/gate_controller.ino
5. แก้ค่า WiFi และ Firebase ในโค้ด

```cpp
#define WIFI_SSID     "ชื่อ WiFi ของคุณ"
#define WIFI_PASSWORD "รหัส WiFi ของคุณ"
#define FIREBASE_HOST "reejai-app-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "database_secret_ของคุณ"
```

6. เลือก Board เป็น ESP32 Dev Module ใน Tools แล้วเลือก Board
7. เลือก Port ที่ ESP32 ต่ออยู่ ใน Tools แล้วเลือก Port
8. กดปุ่ม Upload
9. ถ้า upload ไม่ได้ ให้กดปุ่ม BOOT บน ESP32 ค้างไว้ตอนที่ขึ้น Connecting
10. เปิด Serial Monitor ที่ 115200 baud ต้องเห็นข้อความ REEBJAI Gate Controller Ready


## QR Code และ Barcode

### QR Code สำหรับสาขา

| สาขา | QR Value | ติดที่ |
|------|----------|--------|
| REEBJAI Store Siam Square | REEBJAI_STORE_001 | หน้าประตูร้าน |
| REEBJAI Store Central World | REEBJAI_STORE_002 | หน้าประตูร้าน |

QR Value ต้องตรงกับ field qrCode ใน Firestore collection stores

### Barcode สำหรับสินค้า

| สินค้า | Barcode (EAN-13) | ราคา |
|--------|------------------|------|
| Crystal Drinking Water 600ml | 8850006140021 | 7 บาท |
| Lay's Original Chips | 8851123456789 | 20 บาท |
| Pepsi Can 330ml | 8850006140022 | 17 บาท |
| Mama Shrimp Tom Yum | 8851987654321 | 6 บาท |
| KitKat Chocolate 2F | 8850001234567 | 35 บาท |
| Red Bull Original 150ml | 8852222222222 | 12 บาท |
| Oishi Green Tea 500ml | 8858998581110 | 20 บาท |
| Testo Corn Snack BBQ | 8850999111222 | 10 บาท |
| CP Chicken Rice (Frozen) | 8851111333444 | 45 บาท |
| Dutch Mill Yoghurt Strawberry | 8850777555666 | 15 บาท |

Barcode ต้องตรงกับ field barcode ใน Firestore collection products

### วิธีสร้าง QR Code และ Barcode

1. เปิดผ่านระบบ Web Admin Panel หรือเปิดไฟล์ assets/qr-barcode.html ในเบราว์เซอร์
2. QR Code และ Barcode ทุกตัวจะถูกสร้างอัตโนมัติ
3. กดพิมพ์เพื่อนำไปใช้งาน


## ไฟล์สำคัญที่ต้องรู้

### ไฟล์ที่แก้บ่อย

| ไฟล์ | ทำหน้าที่อะไร | แก้เมื่อไหร่ |
|------|---------------|-------------|
| lib/core/seed/seed_data.dart | ข้อมูลร้านและสินค้าเริ่มต้น | เพิ่มสาขาใหม่หรือเพิ่มสินค้าใหม่ |
| lib/models/store_model.dart | โครงสร้างข้อมูลร้าน | เพิ่ม field ใหม่ให้ร้าน |
| lib/models/product_model.dart | โครงสร้างข้อมูลสินค้า | เพิ่ม field ใหม่ให้สินค้า |
| lib/services/firestore_service.dart | CRUD ทั้งหมด ร้าน สินค้า session payment | แก้ query หรือเพิ่มฟังก์ชัน |
| lib/features/checkin/checkin_screen.dart | หน้าสแกน QR เข้าร้าน | แก้ flow check-in |
| lib/features/scan/scan_screen.dart | หน้าสแกนบาร์โค้ดสินค้า | แก้ flow scan สินค้า |
| lib/features/payment/payment_screen.dart | หน้าจ่ายเงินผ่าน Stripe | แก้ payment flow |
| lib/services/session_provider.dart | เก็บ state ของ user store session ปัจจุบัน | แก้ state management |
| lib/services/cart_provider.dart | เก็บ state ของตะกร้าสินค้า | แก้ cart logic |
| lib/services/board_provider.dart | สั่ง ESP32 และดูสถานะบอร์ด | แก้คำสั่ง ESP32 |
| lib/services/board_command_service.dart | ส่งคำสั่งไป Firebase RTDB | แก้ format คำสั่ง |
| lib/core/constants/stripe_config.dart | Stripe API keys | ใส่ key Stripe ของคุณ |
| assets/store-stock.html | หน้า Web Admin จัดการร้านและสินค้า | แก้ระบบจัดการหลังบ้าน |
| assets/qr-barcode.html | สร้าง QR Code และ Barcode สำหรับพิมพ์ | เพิ่มสาขาหรือสินค้า |
| esp32_firmware/gate_controller/gate_controller.ino | โค้ด ESP32 ประตู | แก้ WiFi หรือ Firebase credentials |

### Data Flow ของระบบ

**flow การเข้าร้าน**

สแกน QR ที่ checkin_screen.dart ส่งไป firestore_service.dart เรียก getStoreByQrCode แล้วส่งไป session_provider.dart เรียก setStore และ setSession แล้วส่งไป board_provider.dart เรียก openGate แล้วส่งไป board_command_service.dart ที่เขียนคำสั่งลง Firebase RTDB แล้ว ESP32 รับคำสั่ง

**flow การสแกนสินค้า**

สแกนบาร์โค้ดที่ scan_screen.dart ส่งไป firestore_service.dart เรียก getProductByBarcode แล้วส่งไป cart_provider.dart เรียก addProduct

**flow การจ่ายเงิน**

กดจ่ายที่ payment_screen.dart ส่งไป stripe_service.dart เรียก Stripe API แล้วส่งไป firestore_service.dart เรียก createPayment และ createReceipt แล้วส่งไป board_provider.dart เรียก openGate เพื่อเปิดประตูครั้งที่ 2


## วิธีเชื่อมกับมือถือ Android

### เตรียมมือถือ (ทำครั้งเดียว)

1. เปิด Developer Options โดยไปที่ Settings แล้วเลือก About Phone แล้วกด Build Number 7 ครั้งติดจนขึ้นข้อความ You are now a developer
2. เปิด USB Debugging โดยไปที่ Settings แล้วเลือก Developer Options แล้วเปิด USB Debugging
3. ต่อสาย USB จากมือถือเข้าคอมพิวเตอร์ แล้วกด Allow ตอนมือถือถามอนุญาต USB Debugging แล้วกด Always allow from this computer

### ตรวจสอบว่าเชื่อมต่อได้

```bash
flutter devices
```

ต้องเห็นมือถือของคุณในรายการ เช่น Samsung Galaxy A54 (mobile) android-arm64 Android 14

### รันแอปบนมือถือ (Development Mode)

```bash
cd reeb_jai_app
flutter pub get
flutter run
```

แอปจะติดตั้งบนมือถือโดยตรง Hot Reload ใช้ได้โดยกด r ใน terminal และ Hot Restart โดยกด R

### Build APK

```bash
flutter build apk --debug
```

ไฟล์ APK จะอยู่ที่ build/app/outputs/flutter-apk/app-debug.apk

สำหรับ release build

```bash
flutter build apk --release
```

ไฟล์จะอยู่ที่ build/app/outputs/flutter-apk/app-release.apk

### ติดตั้ง APK บนมือถือ

วิธีที่ 1 ส่งผ่าน USB

```bash
flutter install
```

วิธีที่ 2 ส่งไฟล์ APK ผ่าน LINE หรือ Email หรือ Drive แล้วเปิดไฟล์บนมือถือแล้วกด Install ถ้ามือถือบล็อคให้ไปที่ Settings แล้วเลือก Install unknown apps แล้วอนุญาต

### ให้สิทธิ์กล้อง

ตอนเปิดแอปครั้งแรก กด Allow ตอนแอปขอสิทธิ์กล้อง สำหรับสแกน QR Code และ Barcode


## Project Structure

```
reeb_jai_app/
  lib/
    main.dart                             Entry point และ Stripe init
    firebase_options.dart                 Firebase config (auto-generated)
    core/
      constants/
        app_colors.dart                   สี theme ของแอป
        app_routes.dart                   ชื่อ route ทุกหน้า
        stripe_config.dart                Stripe API keys (ต้องใส่เอง)
      firestore/
        firestore_collections.dart        ชื่อ collection ทั้งหมด
      seed/
        seed_data.dart                    ข้อมูลร้านและสินค้าเริ่มต้น (ต้องแก้ตอนเพิ่มสาขาหรือสินค้า)
    models/
      user_model.dart                     โครงสร้างข้อมูลผู้ใช้
      store_model.dart                    โครงสร้างข้อมูลร้าน
      product_model.dart                  โครงสร้างข้อมูลสินค้า
      session_model.dart                  โครงสร้างข้อมูล session
      cart_item_model.dart                โครงสร้างข้อมูลสินค้าในตะกร้า
      payment_model.dart                  โครงสร้างข้อมูล payment
      receipt_model.dart                  โครงสร้างข้อมูลใบเสร็จ
      board_command_model.dart            โครงสร้างคำสั่ง ESP32
    services/
      firestore_service.dart              CRUD ทั้งหมด ร้าน สินค้า session payment
      stripe_service.dart                 ชำระเงินผ่าน Stripe
      session_provider.dart               เก็บ state ของ user store session
      cart_provider.dart                  เก็บ state ของตะกร้าสินค้า
      board_provider.dart                 สั่ง ESP32 และดูสถานะ
      board_command_service.dart          ส่งคำสั่งไป Firebase RTDB
      ble_service.dart                    เชื่อมต่อ Bluetooth Low Energy
    features/
      welcome/welcome_screen.dart         หน้าแรกของแอป
      register/register_screen.dart       หน้าลงทะเบียน
      checkin/
        checkin_screen.dart               หน้าสแกน QR เข้าร้าน
        checkin_success_screen.dart        หน้าแจ้งผลเข้าร้านสำเร็จ
      scan/scan_screen.dart               หน้าสแกนบาร์โค้ดสินค้า
      cart/cart_screen.dart                หน้าตะกร้าสินค้า
      payment/payment_screen.dart         หน้าจ่ายเงินผ่าน Stripe
      receipt/receipt_screen.dart          หน้าแสดงใบเสร็จ
      shared/
        qr_scanner_screen.dart            กล้องสแกน QR และ Barcode (ใช้ร่วมกัน)
  esp32_firmware/
    gate_controller/gate_controller.ino   โค้ด ESP32 ประตู (ตัวเดียว)
    shelf_controller/                     ไม่ใช้งาน เก็บไว้เป็น reference
    WIRING_REFERENCE.md                   คู่มือการต่อสายอุปกรณ์
  assets/
    index.html                            หน้ารวมเมนูหลักของ Web Admin
    store-stock.html                      หน้า Web Admin จัดการร้านและสินค้า
    qr-barcode.html                       สร้าง QR Code และ Barcode สำหรับพิมพ์
    fix-store-ids.html                    แก้ไข store IDs
    payments.html                         ดูข้อมูล payment
    logo_reebjai.png                      โลโก้แอป
  pubspec.yaml                            Dependencies ของ Flutter
```


## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Mobile App | Flutter + Dart | 3.x |
| Web Admin | HTML5 + JavaScript + CSS | Standalone Web App |
| State Management | Provider | 6.1.x |
| Database | Cloud Firestore | 6.1.x |
| Realtime | Firebase Realtime DB | 12.1.x |
| Payment | Stripe (flutter_stripe) | 11.3.x |
| Scanner | mobile_scanner | 6.0.x |
| BLE | flutter_blue_plus | 1.35.x |
| Hardware | ESP32 DevKit v1 | 1 ตัว (gate only) |
| ESP32 IDE | Arduino IDE | 2.x |


## License

This project is licensed under the MIT License. See the LICENSE file for details.

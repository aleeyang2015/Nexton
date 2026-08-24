# Attendance Clock-In / Clock-Out — Flutter Integration Guide

เอกสารสำหรับทีม Flutter เพื่อ implement ฟีเจอร์ **ลงเวลาเข้า-ออกงาน (Clock-In / Clock-Out)** ของ Nexton HRM
รวมถึง endpoint ที่เกี่ยวข้อง (check-in logs, attendance records, summary, field requests) พร้อม **กติกาการทำงาน (rules)** และ **การ handle error ให้ครบทุกกรณี**

> Base URL (dev): `https://api.nexton.work` หรือ tenant subdomain เช่น `https://<slug>.nexton.work`
> ทุก endpoint ในเอกสารนี้ต่อท้ายด้วย prefix: **`/api/v1/core_hr`**
> ต้องแนบ `Authorization: Bearer <access_token>` ทุก request (ยกเว้น device-webhook)

---

## สารบัญ

1. [หลักการทำงานโดยรวม (Overview)](#1-overview)
2. [รูปแบบ Response มาตรฐาน](#2-response-envelope)
3. [POST /attendance/clock-in](#3-clock-in)
4. [POST /attendance/clock-out](#4-clock-out)
5. [ตารางรหัส Error ทั้งหมด](#5-error-codes)
6. [Endpoint ที่เกี่ยวข้อง (ประวัติ/สรุป)](#6-related-endpoints)
7. [Rules สำคัญที่ฝั่ง Flutter ต้อง handle](#7-flutter-rules)
8. [ตัวอย่างโค้ด Flutter (Dart)](#8-flutter-code)

---

## 1. Overview

การลงเวลาแบ่งเป็น 3 วิธี (`method`):

| method | คำอธิบาย | ต้องส่ง field เพิ่ม |
|--------|----------|---------------------|
| `gps` | ลงเวลาด้วยพิกัด GPS (geofence) | `latitude`, `longitude` (บังคับ) |
| `wifi` | ลงเวลาด้วยการเช็ค WiFi BSSID | `wifi_bssid` (บังคับ) |
| `field` | งานภาคสนาม (ต้องรออนุมัติจากหัวหน้า) | `field_work_reason` (บังคับ) |

**Flow การทำงานของ clock-in/out (สำคัญมาก):**

1. API ตรวจสอบ **สิทธิ์/พนักงาน** — ต้องมี employee record ผูกกับ user
2. ตรวจว่า **พนักงานถูก assign กะ (shift)** หรือยัง — ถ้าไม่มี → ปฏิเสธ
3. ตรวจ **session** ที่ punch นี้ตกอยู่ (กะสามารถแบ่งเป็นหลายช่วง เช่น เช้า 08:00–12:00, บ่าย 13:30–17:30) — ป้องกันการลงเวลาซ้ำ
4. ตรวจ **location** (GPS geofence / WiFi BSSID) → ได้ผลเป็น `verified` / `rejected` / `pending`
5. บันทึก check-in log **แบบ synchronous** (ตอบกลับทันทีว่าได้รับหรือไม่)
6. ถ้า `verified` → คำนวณ daily record + ผลสาย/ตรงเวลา ให้ทันที

> ⚠️ **สำคัญ:** การได้ HTTP 200 **ไม่ได้แปลว่าลงเวลาสำเร็จเสมอไป** — ต้องอ่าน field `status` ใน response body ด้วย
> - `status = "verified"` → ลงเวลาสำเร็จ (อยู่ในพื้นที่/WiFi ที่กำหนด)
> - `status = "rejected"` → บันทึกแล้วแต่ **ไม่ผ่านการตรวจสอบตำแหน่ง** (เช่นอยู่นอก geofence) — แสดงเตือนผู้ใช้
> - `status = "pending"` → ตรวจสอบไม่ได้ชั่วคราว (เช่น DB error) — บันทึกไว้ก่อน

---

## 2. Response Envelope

**สำเร็จ (Success):**
```json
{
  "success": true,
  "data": { ... },
  "meta": { ... }
}
```

**ผิดพลาด (Error):**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "ข้อความอธิบาย",
    "details": { "key": "value" }
  }
}
```

- ตอน error `data` จะ **ไม่มี** (ถูกตัดออกด้วย `omitempty`)
- `error.details` เป็น optional — บาง error จะแนบข้อมูลเพิ่ม เช่น `next_session_start`, `earliest_checkout`
- เฉพาะ **422 `VALIDATION_ERROR`** และ **409 `DUPLICATE`** จะมี key `message` + `errors` (`{field: [msgs]}`) เพิ่มที่ระดับ top-level ด้วย (Laravel style)

---

## 3. Clock-In

### `POST /api/v1/core_hr/attendance/clock-in`

**Auth:** Bearer token (พนักงานลงเวลาให้ตัวเองเท่านั้น — employee_id resolve จาก JWT ไม่รับจาก body)
**Rate limit:** มี rate limiter สำหรับ mobile clock-in (key ตาม user) — ถ้าโดน limit จะได้ **429**

### Request Body

```json
{
  "method": "gps",
  "latitude": 17.9757,
  "longitude": 102.6331,
  "gps_accuracy": 12.5,
  "is_mock_location": false,
  "wifi_ssid": "Office-WiFi",
  "wifi_bssid": "a4:2b:b0:11:22:33",
  "device_id": "flutter-android-xxxx",
  "photo_url": "https://.../selfie.jpg",
  "field_work_reason": "ไปพบลูกค้าที่ site A",
  "notes": "หมายเหตุเพิ่มเติม"
}
```

| Field | Type | บังคับ | หมายเหตุ |
|-------|------|--------|----------|
| `method` | string | ✅ | ต้องเป็น `gps` \| `wifi` \| `field` เท่านั้น |
| `latitude` | number | เมื่อ `method=gps` | พิกัดละติจูด |
| `longitude` | number | เมื่อ `method=gps` | พิกัดลองจิจูด |
| `gps_accuracy` | number | ไม่ | ความแม่นยำ GPS (เมตร) — ควรส่งเพื่อ audit |
| `is_mock_location` | bool | ไม่ | **ถ้า `true` → ถูกปฏิเสธทันที (403)** ต้องตรวจ mock location ฝั่ง Flutter |
| `wifi_ssid` | string | ไม่ | ชื่อ WiFi (ใช้ประกอบ) |
| `wifi_bssid` | string | เมื่อ `method=wifi` | MAC address ของ AP |
| `device_id` | string | ไม่ | id เครื่อง |
| `photo_url` | string | ไม่ | selfie ตอนลงเวลา (ต้อง upload ก่อนแล้วส่ง URL) |
| `field_work_reason` | string | เมื่อ `method=field` | เหตุผลงานภาคสนาม |
| `notes` | string | ไม่ | หมายเหตุ — **ใช้ยืนยันการออกก่อนเวลา** (ดู clock-out) |

### Response — สำเร็จ (200)

```json
{
  "success": true,
  "data": {
    "checkin_id": "uuid",
    "status": "verified",
    "verification_status": "verified",
    "message": "Clock-in successful",
    "rejection_reason": "",
    "location_name": "สำนักงานใหญ่",
    "distance_from_center": 23.4,
    "timestamp": "2026-08-24T01:15:00Z",
    "is_late": false,
    "late_minutes": 0,
    "attendance_status": "present",
    "session_order": 0,
    "session_label": "08:00–12:00"
  }
}
```

| Field | คำอธิบาย |
|-------|----------|
| `checkin_id` | UUID ของ log นี้ |
| `status` / `verification_status` | `verified` \| `rejected` \| `pending` |
| `message` | ข้อความอธิบายผล |
| `rejection_reason` | เหตุผลถ้าถูก reject: `outside_geofence`, `missing_coordinates`, `unknown_wifi`, `missing_bssid` |
| `location_name` | ชื่อสถานที่ที่ตรวจเจอ (ถ้า verified) |
| `distance_from_center` | ระยะห่างจากจุดศูนย์กลาง geofence (เมตร) |
| `timestamp` | เวลาลงเวลา (UTC, RFC3339) |
| `is_late` | มาสายไหม (เฉพาะ clock-in ที่ verified) |
| `late_minutes` | สายกี่นาที |
| `attendance_status` | `present` (ตรงเวลา) \| `late` \| `absent` |
| `session_order` | ลำดับ session (0-based) ที่ punch นี้ตกอยู่ |
| `session_label` | ป้ายช่วงเวลา session เช่น `08:00–12:00` |

> `is_late`/`late_minutes`/`attendance_status` และ `session_*` เป็น optional — จะมีเมื่อมีการตั้งค่า shift เท่านั้น

---

## 4. Clock-Out

### `POST /api/v1/core_hr/attendance/clock-out`

Request body **โครงสร้างเหมือน clock-in ทุกอย่าง** (ใช้ `ClockInRequest` เดียวกัน)
Response ก็ใช้โครงสร้างเดียวกัน แต่ **ไม่มี** `is_late` / `late_minutes` / `attendance_status` (คำนวณเฉพาะตอน clock-in)

### กติกาเพิ่มเติมของ Clock-Out (rules)

1. ต้อง **clock-in ของ session นั้นก่อน** — ถ้ายังไม่เข้า → `SESSION_NOT_STARTED` (409)
2. **ห้าม clock-out ซ้ำ** session ที่ปิดไปแล้ว → `SESSION_ALREADY_CHECKED_OUT` (409)
3. **ออกสายเกินหน้าต่าง** (เกิน end + late_checkout_minutes) → `AFTER_CHECKOUT_WINDOW` (409)
4. **ออกก่อนเวลา** (ก่อน end − early_exit_grace) และ **ไม่ได้ใส่ `notes`** → `EARLY_CHECKOUT_REQUIRES_REASON` (409)
   - ✅ วิธีแก้: ให้ผู้ใช้กรอกเหตุผลใน `notes` แล้วส่งใหม่ → ระบบจะบันทึกการออกก่อนเวลาให้

---

## 5. Error Codes

> ทุก error อ่านจาก `error.code` เป็นหลัก (อย่า hardcode เทียบข้อความ `message` เพราะเปลี่ยนได้)

### 5.1 Validation / Auth (ก่อนถึง logic session)

| HTTP | code | สาเหตุ | การ handle ฝั่ง Flutter |
|------|------|--------|--------------------------|
| 401 | `UNAUTHORIZED` | ไม่มี/ token หมดอายุ | เด้งไปหน้า login / refresh token |
| 400 | `INVALID_REQUEST` | body parse ไม่ได้ (JSON ผิด) | ตรวจ payload |
| 422 | `VALIDATION_ERROR` | field ไม่ผ่าน validate (เช่น `method` ไม่ใช่ gps/wifi/field) | แสดง error ราย field จาก `errors` |
| 400 | `VALIDATION_ERROR` | `gps` แต่ไม่มี lat/lng / `wifi` แต่ไม่มี bssid / `field` แต่ไม่มี reason | บังคับกรอกก่อนส่ง |
| 403 | `MOCK_LOCATION_DETECTED` | `is_mock_location=true` | แจ้งผู้ใช้ว่าปิด fake GPS ก่อน |
| 400 | `EMPLOYEE_NOT_FOUND` | user ไม่มี employee record ผูก | แจ้งให้ติดต่อ HR |
| 503 | `TENANT_UNAVAILABLE` | tenant DB ไม่พร้อม | retry / แจ้ง error ระบบ |

### 5.2 Shift / Session (409 Conflict — business rules)

| code | เกิดตอน | details ที่แนบมา | ข้อความแนะนำผู้ใช้ |
|------|---------|-------------------|---------------------|
| `NO_SHIFT_ASSIGNED` | in/out | `employee_id` | "ยังไม่ได้กำหนดกะการทำงาน กรุณาติดต่อ HR" |
| `OUTSIDE_SHIFT_HOURS` | in | `last_shift_end` | "หมดเวลาลงเวลาเข้าแล้ว (กะสุดท้ายจบ {last_shift_end})" |
| `OVERNIGHT_SESSION_DONE` | in | `ended_at`, `next_starts` | "คุณทำกะข้ามคืนที่จบ {ended_at} ไปแล้ว รอบถัดไปเริ่ม {next_starts}" |
| `SESSION_ALREADY_STARTED` | in | `session_label`, `session_order`, `next_session_*` | "ลงเวลาเข้า session {label} ไปแล้ว กด clock-out แทน" |
| `SESSION_ALREADY_COMPLETED` | in | เหมือนบน | "session {label} มีทั้งเข้า-ออกครบแล้ว" |
| `SESSION_ALREADY_CHECKED_OUT` | out | `session_label`, `session_order` | "ออกงาน session {label} ไปแล้ว" |
| `SESSION_NOT_STARTED` | out | `session_label`, `session_order` | "ยังไม่ได้ลงเวลาเข้า session {label} เลย" |
| `AFTER_CHECKOUT_WINDOW` | out | `session_label`, `latest_checkout` | "เลยเวลาออกงานแล้ว (ได้ถึง {latest_checkout})" |
| `EARLY_CHECKOUT_REQUIRES_REASON` | out | `session_label`, `earliest_checkout` | "จะออกก่อน {earliest_checkout} ต้องกรอกเหตุผล" → เปิด dialog ให้กรอก `notes` แล้วยิงซ้ำ |

### 5.3 System

| HTTP | code | การ handle |
|------|------|-----------|
| 429 | (rate limit) | "ลงเวลาบ่อยเกินไป กรุณารอสักครู่" — แสดง cooldown |
| 500 | `INTERNAL_ERROR` | "ระบบขัดข้อง กรุณาลองใหม่" + ปุ่ม retry |

> **หมายเหตุ session_order**: เป็น 0-based ใน 409 details แต่ใน `SessionResponse` ของ record จะเป็นค่า order ที่ backend คำนวณ — ใช้ `session_label` แสดงผลจะปลอดภัยกว่า

---

## 6. Related Endpoints

### 6.1 ประวัติการลงเวลา (check-in logs) ของฉัน
`GET /api/v1/core_hr/attendance/checkins/my?start_date=2026-08-01&end_date=2026-08-31&page=1&per_page=20`

คืน list ของ `CheckinLogResponse` (raw log ทุกครั้งที่ punch รวมที่ rejected) แบบ paginated

### 6.2 บันทึกรายวัน (attendance records) ของฉัน
`GET /api/v1/core_hr/attendance/records/my`

Query params:
- `start_date`, `end_date` (YYYY-MM-DD)
- `status` (filter)
- **โหมด offset:** `page`, `per_page` (default per_page=20, max=100)
- **โหมด keyset (แนะนำสำหรับ infinite scroll):** ส่ง `limit=20` (+ `cursor=<next_cursor>` สำหรับหน้าถัดไป)
  - response `meta` จะมี `has_more` และ `next_cursor`
  - `cursor` ผิด → 400 `VALIDATION_ERROR` "invalid cursor"

แต่ละ record มี `sessions[]` (แยกช่วงเช้า/บ่าย) พร้อม `clock_in`, `clock_out`, `is_late`, `is_early_exit`, `work_hours`, `status`

### 6.3 สรุปการมาทำงานของฉัน
`GET /api/v1/core_hr/attendance/records/summary/my?start_date=2026-08-01&end_date=2026-08-31`

- **บังคับ** ส่ง `start_date` + `end_date` ไม่งั้น 400 `VALIDATION_ERROR`
- คืน `AttendanceSummaryResponse`: `present_days`, `late_days`, `absent_days`, `total_work_hours`, `average_clock_in`, ฯลฯ

### 6.4 คำขอ field work ของฉัน
`GET /api/v1/core_hr/attendance/field-requests/my?page=1&per_page=20`
คืน check-in logs ที่ `method=field` (ดูสถานะอนุมัติจาก `approval_status`: `pending` / `approved` / `rejected`)

---

## 7. Flutter Rules

กติกาที่ฝั่ง Flutter **ต้อง** จัดการ (ลด error ที่ยิงไป backend โดยไม่จำเป็น):

1. **ตรวจ Mock Location ก่อนส่งเสมอ** — ใช้ package (เช่น `safe_device` / platform channel) เช็ค แล้ว set `is_mock_location`
   ถ้าตรวจเจอ ควร block ตั้งแต่ฝั่ง client + set flag ให้ backend รู้ (backend จะ 403)
2. **ขอ location permission + เปิด GPS** ให้เรียบร้อยก่อนโหมด `gps` — ถ้าไม่มี lat/lng อย่าเพิ่งยิง
3. **ส่ง `gps_accuracy` เสมอ** เพื่อ audit และช่วย debug กรณี geofence พลาด
4. **จับสถานะปุ่มเข้า/ออก** — ถ้าเพิ่ง clock-in แล้ว ให้ disable ปุ่ม clock-in และ enable clock-out (แต่ยังต้องพึ่ง 409 จาก backend เป็นความจริงสุดท้าย)
5. **อ่าน `status` ใน 200 response** — `rejected` ต้องแสดง warning (สีเหลือง/แดง) ว่า "บันทึกแล้วแต่ไม่ผ่านการตรวจตำแหน่ง"
6. **จัดการ `EARLY_CHECKOUT_REQUIRES_REASON` เป็น flow พิเศษ** — เปิด dialog ให้กรอกเหตุผล → ยิง clock-out ซ้ำพร้อม `notes`
7. **แสดง `error.details`** ให้เป็นประโยชน์ (เช่น `next_session_start`, `latest_checkout`) แทนข้อความ generic
8. **Idempotency ฝั่ง UX** — กันกดรัว (debounce) เพราะ backend มี session guard แต่ก็ควรกันซ้ำที่ client
9. **Timezone** — `timestamp` เป็น UTC (RFC3339) ให้แปลงเป็น local ก่อนแสดง
10. **429** — ทำ cooldown/หน่วงปุ่ม อย่ายิงซ้ำถี่

### แนวทางแมป error → UX

```
401 UNAUTHORIZED               → refresh token / logout
403 MOCK_LOCATION_DETECTED     → dialog "กรุณาปิด Fake GPS"
400 EMPLOYEE_NOT_FOUND         → dialog "บัญชียังไม่ผูกกับพนักงาน ติดต่อ HR"
409 NO_SHIFT_ASSIGNED          → dialog "ยังไม่มีกะ ติดต่อ HR"
409 SESSION_ALREADY_*          → toast ข้อความจาก backend (มีบอก session ถัดไป)
409 SESSION_NOT_STARTED        → toast "ยังไม่ได้ลงเวลาเข้า"
409 EARLY_CHECKOUT_REQUIRES_.. → dialog กรอกเหตุผล → retry พร้อม notes
409 AFTER_CHECKOUT_WINDOW      → toast "เลยเวลาออกงาน"
409 OUTSIDE_SHIFT_HOURS        → toast "หมดเวลาลงเวลาเข้า"
429                            → snackbar + cooldown
500 INTERNAL_ERROR / 503       → snackbar + ปุ่ม retry
```

---

## 8. Flutter Code

### 8.1 Model (Dart)

```dart
class ClockRequest {
  final String method; // 'gps' | 'wifi' | 'field'
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;
  final bool isMockLocation;
  final String? wifiSsid;
  final String? wifiBssid;
  final String? deviceId;
  final String? photoUrl;
  final String? fieldWorkReason;
  final String? notes;

  ClockRequest({
    required this.method,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.isMockLocation = false,
    this.wifiSsid,
    this.wifiBssid,
    this.deviceId,
    this.photoUrl,
    this.fieldWorkReason,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (gpsAccuracy != null) 'gps_accuracy': gpsAccuracy,
        'is_mock_location': isMockLocation,
        if (wifiSsid != null) 'wifi_ssid': wifiSsid,
        if (wifiBssid != null) 'wifi_bssid': wifiBssid,
        if (deviceId != null) 'device_id': deviceId,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (fieldWorkReason != null) 'field_work_reason': fieldWorkReason,
        if (notes != null) 'notes': notes,
      };
}

class ClockResponse {
  final String checkinId;
  final String status; // verified | rejected | pending
  final String message;
  final String? rejectionReason;
  final String? locationName;
  final double? distanceFromCenter;
  final DateTime timestamp;
  final bool? isLate;
  final int? lateMinutes;
  final String? attendanceStatus;
  final int? sessionOrder;
  final String? sessionLabel;

  bool get isVerified => status == 'verified';

  ClockResponse.fromJson(Map<String, dynamic> j)
      : checkinId = j['checkin_id'],
        status = j['status'],
        message = j['message'] ?? '',
        rejectionReason = j['rejection_reason'],
        locationName = j['location_name'],
        distanceFromCenter = (j['distance_from_center'] as num?)?.toDouble(),
        timestamp = DateTime.parse(j['timestamp']),
        isLate = j['is_late'],
        lateMinutes = j['late_minutes'],
        attendanceStatus = j['attendance_status'],
        sessionOrder = j['session_order'],
        sessionLabel = j['session_label'];
}

/// error ที่ map มาจาก envelope { success:false, error:{ code, message, details } }
class ApiException implements Exception {
  final int httpStatus;
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  ApiException(this.httpStatus, this.code, this.message, this.details);
}
```

### 8.2 Service call + error mapping

```dart
Future<ClockResponse> clockIn(ClockRequest req) => _punch('/attendance/clock-in', req);
Future<ClockResponse> clockOut(ClockRequest req) => _punch('/attendance/clock-out', req);

Future<ClockResponse> _punch(String path, ClockRequest req) async {
  final res = await dio.post(
    '/api/v1/core_hr$path',
    data: req.toJson(),
    options: Options(
      headers: {'Authorization': 'Bearer $accessToken'},
      // ให้ Dio ไม่ throw เอง เพื่อ map envelope ด้วยตัวเรา
      validateStatus: (_) => true,
    ),
  );

  final body = res.data as Map<String, dynamic>;
  if (res.statusCode == 200 && body['success'] == true) {
    return ClockResponse.fromJson(body['data']);
  }

  // rate limit อาจไม่คืน envelope มาตรฐาน
  if (res.statusCode == 429) {
    throw ApiException(429, 'RATE_LIMITED', 'ลงเวลาบ่อยเกินไป กรุณารอสักครู่', null);
  }

  final err = (body['error'] as Map<String, dynamic>?) ?? {};
  throw ApiException(
    res.statusCode ?? 0,
    err['code'] ?? 'UNKNOWN',
    err['message'] ?? 'เกิดข้อผิดพลาด',
    err['details'] as Map<String, dynamic>?,
  );
}
```

### 8.3 การจัดการ error ที่ UI

```dart
Future<void> onClockOutPressed(ClockRequest req) async {
  try {
    final r = await attendanceService.clockOut(req);
    if (r.isVerified) {
      showSuccess('ออกงานสำเร็จ (${r.sessionLabel ?? ''})');
    } else {
      // status = rejected / pending
      showWarning('บันทึกแล้วแต่ไม่ผ่านการตรวจตำแหน่ง (${r.rejectionReason ?? ''})');
    }
  } on ApiException catch (e) {
    switch (e.code) {
      case 'EARLY_CHECKOUT_REQUIRES_REASON':
        final reason = await askEarlyCheckoutReason(e.details?['earliest_checkout']);
        if (reason != null && reason.isNotEmpty) {
          // ยิงซ้ำพร้อมเหตุผล
          await onClockOutPressed(req.copyWith(notes: reason));
        }
        break;
      case 'MOCK_LOCATION_DETECTED':
        showDialogMsg('กรุณาปิด Fake GPS แล้วลองใหม่');
        break;
      case 'NO_SHIFT_ASSIGNED':
      case 'EMPLOYEE_NOT_FOUND':
        showDialogMsg(e.message); // มีคำแนะนำติดต่อ HR อยู่แล้ว
        break;
      case 'UNAUTHORIZED':
        await authController.refreshOrLogout();
        break;
      default:
        // SESSION_*, AFTER_CHECKOUT_WINDOW, OUTSIDE_SHIFT_HOURS, RATE_LIMITED ฯลฯ
        showToast(e.message);
    }
  }
}
```

---

## Checklist ก่อน Production

- [ ] เช็ค mock location และ set `is_mock_location`
- [ ] ขอ permission location/กล้อง (ถ้ามี selfie) ครบ
- [ ] แยก UI ปุ่ม clock-in / clock-out ตามสถานะปัจจุบัน (ดึงจาก `records/my` ล่าสุด)
- [ ] handle ครบทุก error code ในตาราง §5
- [ ] flow early-checkout (กรอกเหตุผล → retry)
- [ ] อ่าน `status` แยกจาก HTTP 200
- [ ] debounce ปุ่ม + handle 429
- [ ] แปลง timestamp UTC → local
- [ ] แสดงประวัติจาก `records/my` (keyset) + summary

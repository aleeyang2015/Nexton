# Attendance Correction Requests API — Flutter Integration Guide

คู่มือ API สำหรับฟีเจอร์ **"ลืมสแกน" (Attendance Correction Request)** — พนักงานยื่นคำขอแก้ไข/เพิ่มการสแกนเข้า-ออกย้อนหลัง แล้วผ่าน workflow อนุมัติหลายขั้น (หัวหน้าแผนก → HR) เมื่ออนุมัติครบระบบจะบันทึก punch จริงและคำนวณเวลาทำงานของวันนั้นใหม่

> โมดูล Core HR — ทุก endpoint อยู่ใต้ `"/api/v1/core_hr"`

---

## 1. Base URL & Headers

| | ค่า |
|---|---|
| Base URL (prod) | `https://api.nexton.work/api/v1` |
| Base URL (dev)  | `http://localhost:8081/api/v1` |
| Prefix ของฟีเจอร์นี้ | `/core_hr/attendance/correction-requests` |

**Headers ทุก request:**
```
Content-Type: application/json
Authorization: Bearer <access_token>
```
> **Dev เท่านั้น:** ถ้าเรียกผ่าน `localhost` ต้องแนบ `X-Tenant-Slug: <company-slug>` เพื่อบอก tenant (บน production ระบบอ่าน tenant จาก subdomain อัตโนมัติ เช่น `thenice.nexton.work` → ไม่ต้องส่ง header นี้)

> ผู้ใช้ที่ login ต้อง **ผูกกับ employee** (มี employee record) ไม่งั้นได้ `400 EMPLOYEE_NOT_FOUND`

---

## 2. Response Envelope (มาตรฐานทุก endpoint)

**สำเร็จ (single object):**
```json
{ "success": true, "data": { ... }, "error": null }
```

**สำเร็จ (list + offset pagination):**
```json
{
  "success": true,
  "data": [ ... ],
  "meta": { "page": 1, "per_page": 20, "total": 42, "total_pages": 3 }
}
```

**สำเร็จ (list + cursor pagination — เมื่อส่ง `?limit=`):**
```json
{
  "success": true,
  "data": [ ... ],
  "meta": { "per_page": 20, "has_more": true, "next_cursor": "eyJ...base64..." }
}
```

**ผิดพลาด:**
```json
{
  "success": false,
  "error": { "code": "VALIDATION_ERROR", "message": "Validation failed", "details": { "reason": "this field is required" } }
}
```
> **หมายเหตุ:** เฉพาะ `422 VALIDATION_ERROR` และ `409 DUPLICATE` จะมี key เพิ่ม `message` (string) + `errors` (`{field: [msg]}}`) ที่ระดับ top-level ด้วย เพื่อให้ form อ่าน `errors[field]` ตรงๆ ได้

---

## 3. Enums (ค่าคงที่)

### correction_type — ประเภทการแก้ไข
| ค่า | ความหมาย | ต้องส่งเวลา |
|-----|----------|-------------|
| `missing_check_in`  | ลืมสแกนเข้า  | `requested_clock_in` (เว้นได้ถ้าเลือก shift → ใช้เวลาเริ่มกะ) |
| `missing_check_out` | ลืมสแกนออก  | `requested_clock_out` |
| `both`              | ลืมทั้งเข้าและออก | ทั้งสอง |
| `wrong_time`        | เวลาผิด ขอแก้ | อย่างน้อยหนึ่ง |

### status — สถานะคำขอ
| ค่า | ความหมาย |
|-----|----------|
| `pending`   | รออนุมัติ |
| `approved`  | อนุมัติครบทุกขั้น (บันทึก punch แล้ว) |
| `rejected`  | ถูกปฏิเสธ (ขั้นใดขั้นหนึ่ง) |
| `cancelled` | เจ้าของยกเลิกเอง |

### step_role — บทบาทผู้อนุมัติในแต่ละขั้น
`dept_head` (หัวหน้าแผนก) · `hr` (ฝ่ายบุคคล) · `specific` (บุคคลเจาะจง)

### step status — สถานะแต่ละขั้น
`waiting` (ยังไม่ถึงคิว) · `pending` (กำลังรอขั้นนี้) · `approved` · `rejected`

---

## 4. Endpoints

| # | Method | Path | ใคร | Pagination |
|---|--------|------|-----|-----------|
| 1 | POST | `/correction-requests` | พนักงาน (ยื่นคำขอ) | — |
| 2 | GET  | `/correction-requests/my` | คำขอของฉัน | offset **+ cursor** |
| 3 | GET  | `/correction-requests/team` | หัวหน้าแผนก (คำขอของทีม) | offset |
| 4 | GET  | `/correction-requests/my-approvals` | รายการที่ฉันต้องอนุมัติ/เคยอนุมัติ | offset **+ cursor** |
| 5 | GET  | `/correction-requests/all` | HR (ทั้งบริษัท) — ต้องมีสิทธิ์ | offset |
| 6 | GET  | `/correction-requests/:id` | รายละเอียด 1 ใบ | — |
| 7 | PUT  | `/correction-requests/:id/approve` | ผู้อนุมัติ (อนุมัติขั้นปัจจุบัน) | — |
| 8 | PUT  | `/correction-requests/:id/reject` | ผู้อนุมัติ (ปฏิเสธ) | — |
| 9 | PUT  | `/correction-requests/:id/cancel` | เจ้าของ (ยกเลิก) | — |

**สิทธิ์ (permission):**
- `/all` ต้องมี `corehr:attendanceRecord:manage` (HR)
- ที่เหลือ authenticated ธรรมดา — การอนุมัติ gate ในโค้ด: ขั้น `dept_head`/`specific` ต้องเป็น approver ที่ระบุ, ขั้น `hr` ต้องมีสิทธิ์ `corehr:attendanceRecord:manage`; **ห้ามอนุมัติคำขอตัวเอง**

---

### 4.1 POST `/correction-requests` — ยื่นคำขอ

**Body:**
```json
{
  "request_date": "2026-09-28",
  "shift_detail_id": "a877e932-ae25-44d2-885a-704430dfa36a",
  "session_order": 1,
  "correction_type": "missing_check_in",
  "requested_clock_in": "08:05",
  "requested_clock_out": "",
  "reason": "ลืมสแกนตอนเช้า ประชุมนอกสถานที่",
  "attachment_url": "https://.../proof.jpg"
}
```

| field | ชนิด | บังคับ | หมายเหตุ |
|-------|------|--------|----------|
| `request_date` | string `YYYY-MM-DD` | ✅ | วันที่ต้องการแก้ |
| `correction_type` | enum | ✅ | ดูตารางด้านบน |
| `requested_clock_in` | string `HH:MM` | ตาม type | เว้นได้ถ้าเลือก shift (ใช้เวลาเริ่มกะ) |
| `requested_clock_out` | string `HH:MM` | ตาม type | เว้นได้ถ้าเลือก shift (ใช้เวลาเลิกกะ) |
| `shift_detail_id` | uuid | ❌ | กะที่ต้องการแก้ (ช่วยเติมเวลา default + ตรวจว่าเวลาอยู่ในกรอบกะ) |
| `session_order` | int | ❌ | ลำดับ session ในวัน (กะแยกเช้า/บ่าย) default 0 |
| `reason` | string | ✅ | เหตุผล |
| `attachment_url` | string | ❌ | ลิงก์รูปแนบ (จาก `/uploads`) |

**Response `201`:** object `CorrectionRequest` (ดู §5) — `status = "pending"`, มี `steps` ที่ generate จาก workflow

**Errors:**
| HTTP | code | เมื่อไหร่ |
|------|------|----------|
| 422 | `VALIDATION_ERROR` | field ผิด format / ขาดเวลาที่ type ต้องการ / เวลาอยู่นอกกรอบกะ |
| 409 | `DUPLICATE` | มีคำขอ pending/approved ของวัน+กะเดียวกันอยู่แล้ว |
| 400 | `EMPLOYEE_NOT_FOUND` | user ไม่ได้ผูก employee |

---

### 4.2 GET `/correction-requests/my` — คำขอของฉัน

**Query params (optional):**
| param | ตัวอย่าง | หมายเหตุ |
|-------|---------|----------|
| `status` | `pending` | กรองสถานะ (เว้น = ทุกสถานะ) |
| `month` | `2026-09` | กรองเดือนของ `request_date` |
| `page` / `per_page` | `1` / `20` | offset mode (default 1/20, max 100) |
| `limit` | `20` | **cursor mode** (ถ้าส่ง `limit` จะใช้ cursor แทน offset) |
| `cursor` | `<next_cursor>` | ต่อหน้า (คู่กับ `limit`) |

**Response:** array ของ `CorrectionRequest` + `meta` (offset หรือ cursor ตามโหมด)

> **Flutter infinite scroll:** ใช้ cursor mode — ยิงครั้งแรก `?limit=20` เก็บ `meta.next_cursor` แล้วหน้าถัดไป `?limit=20&cursor=<next_cursor>` จนกว่า `meta.has_more == false`

---

### 4.3 GET `/correction-requests/team` — คำขอของทีม (หัวหน้าแผนก)

คืนคำขอของสมาชิกในแผนกที่ผู้เรียกเป็นหัวหน้า (`departments.head_employee_id`) — **ว่างถ้าไม่ใช่หัวหน้า**
Query: `status`, `month`, `page`, `per_page` (offset only)

---

### 4.4 GET `/correction-requests/my-approvals` — รายการที่ฉันเกี่ยวข้องในฐานะผู้อนุมัติ

คืนคำขอที่ **รอฉันอนุมัติ** + ที่ **ฉันเคยอนุมัติ/ปฏิเสธ**
Query: `status` (`pending` = เฉพาะที่รอฉัน, `approved`/`rejected` = ที่ฉันเคยทำ), `month`, `page`/`per_page`, **หรือ** `limit`/`cursor` (cursor mode)

---

### 4.5 GET `/correction-requests/all` — ทั้งบริษัท (HR)

ต้องมีสิทธิ์ `corehr:attendanceRecord:manage` (ไม่งั้น `403`)
Query: `employee_id`, `department_id`, `status`, `month`, `page`, `per_page`

---

### 4.6 GET `/correction-requests/:id` — รายละเอียด 1 ใบ

เห็นได้เฉพาะ: เจ้าของ / ผู้อนุมัติในสาย / HR — คนอื่นได้ `404` (ไม่รั่วว่ามีอยู่)
**Response:** object `CorrectionRequest` เต็ม (รวม `steps` + `attendance_record` ถ้าอนุมัติแล้ว)

---

### 4.7 PUT `/correction-requests/:id/approve` — อนุมัติขั้นปัจจุบัน

**Body (optional):**
```json
{ "step_id": "139001d4-...", "note": "อนุมัติ" }
```
- `step_id` (optional): ถ้าส่งต้องตรงกับขั้นที่กำลัง pending — กัน race (ถ้าไม่ตรง → `409 STEP_CHANGED`)
- `note` (optional): คอมเมนต์ผู้อนุมัติ

**พฤติกรรม:** อนุมัติขั้นปัจจุบัน → ถ้ายังมีขั้นถัดไป เลื่อนไปขั้นนั้น (`status` ยัง `pending`) / ถ้าเป็นขั้นสุดท้าย → `status = approved` + **บันทึก punch จริง** และ recompute วันนั้น
**Response:** object `CorrectionRequest` ล่าสุด

---

### 4.8 PUT `/correction-requests/:id/reject` — ปฏิเสธ

**Body:**
```json
{ "note": "เหตุผลไม่เพียงพอ", "step_id": "139001d4-..." }
```
- `note` **บังคับ** (ไม่งั้น `422`)
- ปฏิเสธขั้นใดขั้นหนึ่ง = จบทั้งคำขอ (`status = rejected`)

---

### 4.9 PUT `/correction-requests/:id/cancel` — ยกเลิก (เจ้าของ)

ยกเลิกได้เฉพาะคำขอ **ของตัวเอง** ที่ยัง `pending` — ไม่งั้น `409 CANNOT_CANCEL`
Body: ไม่มี

---

## 5. Response Schema — `CorrectionRequest`

```json
{
  "id": "d29b...",
  "employee": {
    "id": "ce86925d-...",
    "name": "Alex Vang",
    "employee_number": "EMP-001",
    "department": { "id": "868f...", "name": "IT Development", "name_lo": "ພະແນກ ພັດທະນາ" }
  },
  "employee_id": "ce86925d-...",
  "request_date": "2026-09-28",
  "session_order": 1,
  "shift_detail_id": "a877e932-...",
  "shift_detail": {
    "id": "a877e932-...", "name": "Morning", "name_lo": "ກະເຊົ້າ", "sort_order": 1,
    "start_time": "08:00", "end_time": "12:00", "break_minutes": 60, "working_hours": 8,
    "late_grace_minutes": 15, "early_exit_grace_minutes": 15, "overtime_eligible": true,
    "shift": { "id": "0635...", "name": "Regular Office Hours", "name_lo": "ເວລາວຽກປົກກະຕິ", "code": "REG" }
  },
  "correction_type": "missing_check_in",
  "requested_clock_in": "08:05",
  "requested_clock_out": null,
  "reason": "ลืมสแกนตอนเช้า",
  "attachment_url": null,
  "status": "pending",
  "current_step_no": 1,
  "attendance_record_id": null,
  "attendance_record": null,
  "created_at": "2026-09-28 09:15:02",
  "updated_at": "2026-09-28 09:15:02",
  "steps": [
    {
      "id": "1390...", "step_no": 1, "step_role": "dept_head",
      "approver": { "id": "aa11...", "name": "Boss Namgnai" },
      "status": "pending", "note": null, "acted_at": null, "created_at": "2026-09-28 09:15:02"
    },
    {
      "id": "1391...", "step_no": 2, "step_role": "hr",
      "approver": null, "status": "waiting", "note": null, "acted_at": null, "created_at": "2026-09-28 09:15:02"
    }
  ]
}
```

**`attendance_record`** (null จนกว่าจะอนุมัติ; หลังอนุมัติจะมี):
```json
{
  "id": "...", "date": "2026-09-28", "clock_in": "2026-09-28 08:05:00", "clock_out": "2026-09-28 17:02:00",
  "status": "present", "work_hours": 8, "is_late": false, "late_minutes": 0,
  "is_early_exit": false, "early_exit_minutes": 0, "source": "manual", "is_manual_correction": true,
  "session": { /* SessionResponse ของ segment ที่แก้ */ }
}
```

> **รูปแบบเวลา:** `request_date` = `YYYY-MM-DD`; `requested_clock_in/out` = `HH:MM`; `created_at`/`clock_in` ฯลฯ = `YYYY-MM-DD HH:MM:SS` (เวลาท้องถิ่น)

---

## 6. Error Codes (รวม)

| HTTP | code | ความหมาย |
|------|------|----------|
| 401 | `MISSING_TOKEN` / `UNAUTHORIZED` | ไม่มี/token ไม่ถูก |
| 400 | `EMPLOYEE_NOT_FOUND` | user ไม่ได้ผูก employee |
| 422 | `VALIDATION_ERROR` | body/field ผิด |
| 409 | `DUPLICATE` | คำขอวัน+กะซ้ำ |
| 409 | `NOT_PENDING` | คำขอไม่ได้อยู่สถานะรออนุมัติ |
| 409 | `STEP_CHANGED` | `step_id` ไม่ตรงขั้นปัจจุบัน |
| 403 | `NOT_APPROVER` | ไม่มีสิทธิ์อนุมัติขั้นนี้ / พยายามอนุมัติคำขอตัวเอง |
| 409 | `CANNOT_CANCEL` | ยกเลิกได้เฉพาะคำขอตัวเองที่ยัง pending |
| 404 | `NOT_FOUND` | ไม่พบ / ไม่มีสิทธิ์เห็น |
| 403 | `FORBIDDEN` (module/permission) | ไม่มีสิทธิ์ `corehr:attendanceRecord:manage` (`/all`) |

---

## 7. Dart / Flutter Models

```dart
// enums ---------------------------------------------------------------
enum CorrectionType { missingCheckIn, missingCheckOut, both, wrongTime }
enum CorrectionStatus { pending, approved, rejected, cancelled }
enum StepRole { deptHead, hr, specific }
enum StepStatus { waiting, pending, approved, rejected }

String correctionTypeToApi(CorrectionType t) => switch (t) {
  CorrectionType.missingCheckIn  => 'missing_check_in',
  CorrectionType.missingCheckOut => 'missing_check_out',
  CorrectionType.both            => 'both',
  CorrectionType.wrongTime       => 'wrong_time',
};

// models --------------------------------------------------------------
class DepartmentRef {
  final String id;
  final String? name;
  final String? nameLo;
  DepartmentRef({required this.id, this.name, this.nameLo});
  factory DepartmentRef.fromJson(Map<String, dynamic> j) =>
      DepartmentRef(id: j['id'], name: j['name'], nameLo: j['name_lo']);
}

class CorrectionEmployee {
  final String id;
  final String? name;
  final String? employeeNumber;
  final DepartmentRef? department;
  CorrectionEmployee({required this.id, this.name, this.employeeNumber, this.department});
  factory CorrectionEmployee.fromJson(Map<String, dynamic> j) => CorrectionEmployee(
        id: j['id'],
        name: j['name'],
        employeeNumber: j['employee_number'],
        department: j['department'] == null ? null : DepartmentRef.fromJson(j['department']),
      );
}

class CorrectionStep {
  final String id;
  final int stepNo;
  final String stepRole;   // dept_head | hr | specific
  final String status;     // waiting | pending | approved | rejected
  final String? note;
  final String? approverId;
  final String? approverName;
  final String? actedAt;
  final String createdAt;
  CorrectionStep({
    required this.id, required this.stepNo, required this.stepRole, required this.status,
    this.note, this.approverId, this.approverName, this.actedAt, required this.createdAt,
  });
  factory CorrectionStep.fromJson(Map<String, dynamic> j) => CorrectionStep(
        id: j['id'],
        stepNo: j['step_no'],
        stepRole: j['step_role'],
        status: j['status'],
        note: j['note'],
        approverId: j['approver']?['id'],
        approverName: j['approver']?['name'],
        actedAt: j['acted_at'],
        createdAt: j['created_at'],
      );
}

class CorrectionRequest {
  final String id;
  final CorrectionEmployee employee;
  final String employeeId;
  final String requestDate;          // YYYY-MM-DD
  final int sessionOrder;
  final String? shiftDetailId;
  final String correctionType;
  final String? requestedClockIn;    // HH:MM
  final String? requestedClockOut;   // HH:MM
  final String reason;
  final String? attachmentUrl;
  final String status;               // pending | approved | rejected | cancelled
  final int currentStepNo;
  final String? attendanceRecordId;
  final String createdAt;
  final String updatedAt;
  final List<CorrectionStep> steps;

  CorrectionRequest({
    required this.id, required this.employee, required this.employeeId,
    required this.requestDate, required this.sessionOrder, this.shiftDetailId,
    required this.correctionType, this.requestedClockIn, this.requestedClockOut,
    required this.reason, this.attachmentUrl, required this.status,
    required this.currentStepNo, this.attendanceRecordId,
    required this.createdAt, required this.updatedAt, required this.steps,
  });

  factory CorrectionRequest.fromJson(Map<String, dynamic> j) => CorrectionRequest(
        id: j['id'],
        employee: CorrectionEmployee.fromJson(j['employee']),
        employeeId: j['employee_id'],
        requestDate: j['request_date'],
        sessionOrder: j['session_order'] ?? 0,
        shiftDetailId: j['shift_detail_id'],
        correctionType: j['correction_type'],
        requestedClockIn: j['requested_clock_in'],
        requestedClockOut: j['requested_clock_out'],
        reason: j['reason'],
        attachmentUrl: j['attachment_url'],
        status: j['status'],
        currentStepNo: j['current_step_no'] ?? 1,
        attendanceRecordId: j['attendance_record_id'],
        createdAt: j['created_at'],
        updatedAt: j['updated_at'],
        steps: (j['steps'] as List? ?? []).map((e) => CorrectionStep.fromJson(e)).toList(),
      );
}

// paged result (cursor) ----------------------------------------------
class CursorPage<T> {
  final List<T> items;
  final bool hasMore;
  final String? nextCursor;
  CursorPage({required this.items, required this.hasMore, this.nextCursor});
}
```

---

## 8. Dio Service (ตัวอย่างพร้อมใช้)

```dart
import 'package:dio/dio.dart';

class CorrectionApi {
  final Dio _dio;
  CorrectionApi(this._dio);
  // สมมติ _dio.options.baseUrl = 'http://localhost:8081/api/v1'
  // และมี interceptor แนบ Authorization + (dev) X-Tenant-Slug ให้แล้ว

  static const _base = '/core_hr/attendance/correction-requests';

  /// 1) ยื่นคำขอ
  Future<CorrectionRequest> create({
    required String requestDate,            // YYYY-MM-DD
    required CorrectionType type,
    String? requestedClockIn,               // HH:MM
    String? requestedClockOut,              // HH:MM
    String? shiftDetailId,
    int sessionOrder = 0,
    required String reason,
    String? attachmentUrl,
  }) async {
    final res = await _dio.post(_base, data: {
      'request_date': requestDate,
      'correction_type': correctionTypeToApi(type),
      if (requestedClockIn != null) 'requested_clock_in': requestedClockIn,
      if (requestedClockOut != null) 'requested_clock_out': requestedClockOut,
      if (shiftDetailId != null) 'shift_detail_id': shiftDetailId,
      'session_order': sessionOrder,
      'reason': reason,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    });
    return CorrectionRequest.fromJson(res.data['data']);
  }

  /// 2) คำขอของฉัน (cursor / infinite scroll)
  Future<CursorPage<CorrectionRequest>> myRequests({
    int limit = 20,
    String? cursor,
    String? status,     // pending | approved | rejected | cancelled
    String? month,      // YYYY-MM
  }) async {
    final res = await _dio.get('$_base/my', queryParameters: {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (status != null) 'status': status,
      if (month != null) 'month': month,
    });
    final data = (res.data['data'] as List).map((e) => CorrectionRequest.fromJson(e)).toList();
    final meta = res.data['meta'] ?? {};
    return CursorPage(items: data, hasMore: meta['has_more'] ?? false, nextCursor: meta['next_cursor']);
  }

  /// 4) รายการที่ฉันต้องอนุมัติ (cursor)
  Future<CursorPage<CorrectionRequest>> myApprovals({
    int limit = 20, String? cursor, String status = 'pending', String? month,
  }) async {
    final res = await _dio.get('$_base/my-approvals', queryParameters: {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      'status': status,
      if (month != null) 'month': month,
    });
    final data = (res.data['data'] as List).map((e) => CorrectionRequest.fromJson(e)).toList();
    final meta = res.data['meta'] ?? {};
    return CursorPage(items: data, hasMore: meta['has_more'] ?? false, nextCursor: meta['next_cursor']);
  }

  /// 3) คำขอของทีม (หัวหน้าแผนก) — offset
  Future<List<CorrectionRequest>> teamRequests({int page = 1, int perPage = 20, String? status, String? month}) async {
    final res = await _dio.get('$_base/team', queryParameters: {
      'page': page, 'per_page': perPage,
      if (status != null) 'status': status, if (month != null) 'month': month,
    });
    return (res.data['data'] as List).map((e) => CorrectionRequest.fromJson(e)).toList();
  }

  /// 6) รายละเอียด 1 ใบ
  Future<CorrectionRequest> get(String id) async {
    final res = await _dio.get('$_base/$id');
    return CorrectionRequest.fromJson(res.data['data']);
  }

  /// 7) อนุมัติ
  Future<CorrectionRequest> approve(String id, {String? stepId, String? note}) async {
    final res = await _dio.put('$_base/$id/approve', data: {
      if (stepId != null) 'step_id': stepId,
      if (note != null) 'note': note,
    });
    return CorrectionRequest.fromJson(res.data['data']);
  }

  /// 8) ปฏิเสธ (note บังคับ)
  Future<CorrectionRequest> reject(String id, {required String note, String? stepId}) async {
    final res = await _dio.put('$_base/$id/reject', data: {
      'note': note,
      if (stepId != null) 'step_id': stepId,
    });
    return CorrectionRequest.fromJson(res.data['data']);
  }

  /// 9) ยกเลิก (เจ้าของ)
  Future<CorrectionRequest> cancel(String id) async {
    final res = await _dio.put('$_base/$id/cancel');
    return CorrectionRequest.fromJson(res.data['data']);
  }
}
```

**ตัวอย่าง error handling:**
```dart
try {
  await api.create(requestDate: '2026-09-28', type: CorrectionType.missingCheckIn,
      requestedClockIn: '08:05', reason: 'ลืมสแกน');
} on DioException catch (e) {
  final err = e.response?.data?['error'];
  final code = err?['code'];          // เช่น DUPLICATE, VALIDATION_ERROR
  final message = err?['message'];
  // 422/409 มี e.response?.data?['errors'] = { field: [msg] } ให้ map ขึ้น form ได้
}
```

---

## 9. Flow สรุป (สำหรับ UI)

```
พนักงาน
  └─ POST /correction-requests           → status: pending (สร้าง steps ตาม workflow)
        │
        ├─ หัวหน้าแผนก: GET /my-approvals?status=pending → PUT /:id/approve
        │      → เลื่อนไปขั้น HR (ยัง pending)
        │
        ├─ HR: GET /my-approvals?status=pending → PUT /:id/approve
        │      → ขั้นสุดท้าย → status: approved + บันทึก punch จริง + recompute วัน
        │
        ├─ ผู้อนุมัติคนใด PUT /:id/reject (note บังคับ) → status: rejected (จบ)
        └─ เจ้าของ PUT /:id/cancel (ตอนยัง pending) → status: cancelled
```

**Tips การทำ UI:**
- แสดง timeline การอนุมัติจาก `steps[]` (เรียงตาม `step_no`) — ขั้นที่ `status == "pending"` คือขั้นที่กำลังรอ
- ปุ่ม "ยกเลิก" โชว์เฉพาะ `status == pending` และเป็นคำขอของ user เอง
- ปุ่ม "อนุมัติ/ปฏิเสธ" โชว์จาก `/my-approvals?status=pending` (backend การันตีว่าเห็นเฉพาะที่ตัวเองอนุมัติได้)
- ส่ง `step_id` (จากขั้นที่ `pending`) ตอน approve/reject เพื่อกัน race — ถ้าได้ `409 STEP_CHANGED` ให้ refresh แล้วลองใหม่
```

> ⚠️ ระบบ **สแกนนอกพื้นที่ (offsite-requests)** มีโครง API เหมือนกันเกือบทั้งหมด (create/my/my-approvals/all/:id/approve/reject/cancel + cursor) ต่างที่ field ของ body เป็นพิกัด+รูป — ถ้าต้องการเอกสารชุดนั้นด้วยบอกได้

# Off-site Scan Requests API (ການ​ສະແກນ​ນອກ​ພື້ນ​ທີ່)

เอกสาร API สำหรับ **Off-site Scan Requests** (เมนู "สแกนนอกพื้นที่" / "scan outside area") ใช้สำหรับ implement ใน Flutter mobile app

> **Context:** เมื่อพนักงานกด clock-in/clock-out ด้วย GPS แล้วตำแหน่งอยู่นอกทุก geofence (นอกพื้นที่บริษัท) พนักงานสามารถยื่นคำขอสแกนนอกพื้นที่ โดยแนบ **รูปถ่าย + เหตุผล + พิกัด**
> - พนักงานที่มีสิทธิ์ `can_work_offsite` → ระบบ **อนุมัติอัตโนมัติ** และบันทึก punch ทันที (`status = "approved"`)
> - พนักงานที่ไม่มีสิทธิ์ → คำขอจะ **pending** รอ HR อนุมัติ เมื่ออนุมัติขั้นสุดท้ายจึงจะบันทึก punch

---

## 1. ข้อมูลพื้นฐาน (Base Info)

| หัวข้อ | รายละเอียด |
|--------|-----------|
| Base URL | `https://api.nexton.work/api/v1/core_hr` (prod) |
| Module prefix | `/attendance` |
| Authentication | `Authorization: Bearer <access_token>` (ทุก endpoint ต้องมี) |
| Content-Type | `application/json` |
| `employee_id` | ดึงจาก JWT เสมอ — **ห้ามส่งมาใน body** |
| Timezone | เวลาทั้งหมดเป็น tenant-local wall clock, format `"2006-01-02 15:04:05"` **ไม่มี timezone suffix** |

### Response Envelope (รูปแบบมาตรฐาน)

**สำเร็จ (single object):**
```json
{ "success": true, "data": { ... } }
```

**สำเร็จ (list + offset pagination):**
```json
{
  "success": true,
  "data": [ ... ],
  "meta": { "page": 1, "per_page": 20, "total": 150, "total_pages": 8 }
}
```

**สำเร็จ (list + cursor/keyset pagination — ส่ง `?limit=`):**
```json
{
  "success": true,
  "data": [ ... ],
  "meta": { "per_page": 20, "has_more": true, "next_cursor": "<opaque-string>" }
}
```

**ผิดพลาด (error ทั่วไป):**
```json
{
  "success": false,
  "error": {
    "code": "SESSION_ALREADY_STARTED",
    "message": "You have already clocked in for the morning session; clock out instead.",
    "details": { "session_label": "morning", "session_order": 1 }
  }
}
```
> บน error นั้น key `data` จะ **ถูกตัดออก** (ไม่ใช่ `null`)
> `error.details` เป็น optional — มีเฉพาะบาง error code (ดูตาราง error ด้านล่าง)

**ผิดพลาด (422 VALIDATION_ERROR — มี key พิเศษสำหรับ form):**
```json
{
  "success": false,
  "error": { "code": "VALIDATION_ERROR", "message": "Validation failed", "details": { "method": "..." } },
  "message": "method is a required field",
  "errors": { "method": ["method is a required field"] }
}
```
> **เฉพาะ 422 `VALIDATION_ERROR`** (และ 409 `DUPLICATE`) เท่านั้นที่จะมี top-level `message` (string) และ `errors` (`{ field: string[] }`) เพิ่มเข้ามา เพื่อให้ form frontend อ่าน `errors[field]` ได้ตรงๆ

---

## 2. Endpoints (ภาพรวม)

| Method | Path | คำอธิบาย | สิทธิ์ |
|--------|------|----------|--------|
| POST | `/attendance/offsite-requests` | ยื่นคำขอสแกนนอกพื้นที่ | พนักงานที่ login |
| GET | `/attendance/offsite-requests/my` | รายการคำขอของตัวเอง | พนักงานที่ login |
| GET | `/attendance/offsite-requests/my-approvals` | รายการที่ตัวเองต้องอนุมัติ/เคยอนุมัติ | พนักงานที่ login (เป็น approver/HR) |
| GET | `/attendance/offsite-requests/:id` | ดูคำขอรายการเดียว | เจ้าของ / approver / HR |
| PUT | `/attendance/offsite-requests/:id/approve` | อนุมัติ step ปัจจุบัน | approver ของ step / HR |
| PUT | `/attendance/offsite-requests/:id/reject` | ปฏิเสธ step ปัจจุบัน | approver ของ step / HR |
| PUT | `/attendance/offsite-requests/:id/cancel` | ยกเลิกคำขอของตัวเอง (pending เท่านั้น) | เจ้าของคำขอ |

---

## 3. POST `/attendance/offsite-requests` — ยื่นคำขอ

สร้างคำขอสแกนนอกพื้นที่ สำหรับพนักงานที่ login อยู่ (เวลา scan ถูกกำหนดฝั่ง server ตอนยื่น ไม่รับจาก client)

### Request Body

```json
{
  "method": "check_in",
  "latitude": 17.9757,
  "longitude": 102.6331,
  "reason": "ออกพบลูกค้านอกสถานที่",
  "attachments": {
    "url": "https://cdn.nexton.work/uploads/abc.jpg",
    "file_name": "abc.jpg",
    "original_name": "photo.jpg",
    "content_type": "image/jpeg",
    "size": 204800
  }
}
```

### Field Validation

| Field | Type | Required | Rule | หมายเหตุ |
|-------|------|----------|------|----------|
| `method` | string | ✅ | ต้องเป็น `"check_in"` หรือ `"check_out"` | ทิศทางของการ punch |
| `latitude` | number | ✅ | ต้องไม่ null | พิกัดตำแหน่งที่สแกน |
| `longitude` | number | ✅ | ต้องไม่ null | พิกัดตำแหน่งที่สแกน |
| `reason` | string | ✅ | ต้องไม่ว่าง | เหตุผลที่สแกนนอกพื้นที่ |
| `attachments` | object | ✅ | ต้องมี `url` + `file_name` ไม่ว่าง | รูปถ่าย (บังคับ) |
| `attachments.url` | string | ✅ | ไม่ว่าง | URL ไฟล์ที่ upload ไว้แล้ว |
| `attachments.file_name` | string | ✅ | ไม่ว่าง | ชื่อไฟล์ |
| `attachments.original_name` | string | ❌ | — | metadata |
| `attachments.content_type` | string | ❌ | — | metadata |
| `attachments.size` | int | ❌ | — | metadata (bytes) |

> **หมายเหตุสำหรับ Flutter:**
> 1. ต้อง upload รูปก่อน (ผ่าน upload endpoint แยก) แล้วเอา response object มาใส่ใน `attachments` ตรงๆ
> 2. `attachments` validate 2 ชั้น: validator (`required`) + ตรวจซ้ำใน handler ว่า `url` และ `file_name` ไม่ว่าง → ถ้าขาดจะได้ 422
> 3. field คือ `attachments` (พหูพจน์) แต่ค่าเป็น **object เดียว** ไม่ใช่ array

### Response — `201 Created`

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "employee": {
      "id": "uuid",
      "name": "สมชาย ใจดี",
      "employee_number": "EMP-001",
      "department": { "id": "uuid", "name": "Sales", "name_lo": "ຝ່າຍຂາຍ" }
    },
    "employee_id": "uuid",
    "method": "check_in",
    "latitude": 17.9757,
    "longitude": 102.6331,
    "scan_timestamp": "2026-10-02 08:15:00",
    "scan_date": "2026-10-02",
    "session_order": 1,
    "shift_detail_id": "uuid",
    "shift_detail": {
      "id": "uuid", "name": "Morning", "name_lo": null, "sort_order": 1,
      "start_time": "08:00", "end_time": "12:00", "break_minutes": 0,
      "working_hours": 4, "late_grace_minutes": 15, "early_exit_grace_minutes": 10,
      "overtime_eligible": false,
      "shift": { "id": "uuid", "name": "Standard", "name_lo": null, "code": "STD" }
    },
    "attachment": {
      "url": "https://cdn.nexton.work/uploads/abc.jpg",
      "file_name": "abc.jpg",
      "original_name": "photo.jpg",
      "content_type": "image/jpeg",
      "size": 204800
    },
    "reason": "ออกพบลูกค้านอกสถานที่",
    "status": "approved",
    "current_step_no": 1,
    "attendance_record_id": "uuid",
    "created_at": "2026-10-02 08:15:00",
    "updated_at": "2026-10-02 08:15:00",
    "steps": [
      {
        "id": "uuid", "step_no": 1, "step_role": "hr",
        "approver": null, "status": "approved",
        "note": "Auto-approved (can_work_offsite)",
        "acted_at": "2026-10-02 08:15:00", "created_at": "2026-10-02 08:15:00"
      }
    ]
  }
}
```

> - `status` จะเป็น `"approved"` ทันที (ถ้ามี `can_work_offsite`) หรือ `"pending"` (ถ้าต้องรอ HR)
> - `shift_detail` / `shift_detail_id` จะเป็น `null` เมื่อวันที่สแกนไม่มี shift กำหนดไว้
> - `attendance_record_id` จะมีค่าเมื่อ punch ถูกบันทึกแล้ว (auto-approve)

### Error Cases ของ POST (สำคัญมากสำหรับ Flutter)

การสแกนนอกพื้นที่ถูก gate ด้วยกฎ session เดียวกับ clock-in/out ปกติ → handle error เหล่านี้ให้ครบ:

| HTTP | code | เกิดเมื่อ | details keys |
|------|------|----------|--------------|
| 401 | `UNAUTHORIZED` | ไม่มี token / token ไม่ valid | — |
| 400 | `INVALID_REQUEST` | body parse ไม่ได้ (JSON พัง) | — |
| 422 | `VALIDATION_ERROR` | field ไม่ผ่าน validate หรือ attachment ขาด url/file_name | `errors[field]` |
| 400 | `EMPLOYEE_NOT_FOUND` | user ที่ login ไม่มี employee record ผูกอยู่ | — |
| 409 | `OFFSITE_REQUEST_EXISTS` | มีคำขอของ session + ทิศทางเดียวกันในวันนี้ ที่ pending/approved อยู่แล้ว | `session_order`, `method` |
| 409 | `OUTSIDE_SHIFT_HOURS` | check_in หลัง shift สุดท้ายของวันจบแล้ว | `last_shift_end` |
| 409 | `OVERNIGHT_SESSION_DONE` | check_in ในช่วงหลัง overnight session ที่ทำไปแล้ว | `ended_at`, `next_starts` |
| 409 | `SESSION_ALREADY_STARTED` | check_in แต่ session นี้ clock-in ไปแล้ว | `session_label`, `session_order`, (+`next_session_*`) |
| 409 | `SESSION_ALREADY_CHECKED_OUT` | check_out แต่ session นี้ clock-out ไปแล้ว | `session_label`, `session_order` |
| 409 | `SESSION_ALREADY_COMPLETED` | session มีทั้ง in และ out แล้ว | `session_label`, `session_order` |
| 409 | `TOO_EARLY_CHECKIN` | check_in ก่อนเวลาเปิด (start − early_checkin) | `session_label`, `session_order`, `clock_in_opens` |
| 409 | `SESSION_NOT_STARTED` | check_out แต่ยังไม่ได้ clock-in ของ session นั้น | `session_label`, `session_order` |
| 409 | `AFTER_CHECKOUT_WINDOW` | check_out หลัง end + late_checkout | `session_label`, `latest_checkout` |
| 500 | `INTERNAL_ERROR` | punch บันทึกไม่สำเร็จ (auto-approve) / DB error | — |

> **TOO_EARLY_CHECKIN:** แสดง `details.clock_in_opens` (เช่น `"07:45"`) ให้ user รู้ว่าให้มาสแกนตอนไหน
> **OFFSITE_REQUEST_EXISTS:** บอก user ว่ามีคำขอค้างอยู่แล้ว ให้รอผล อย่าสแกนซ้ำ

---

## 4. GET `/attendance/offsite-requests/my` — คำขอของตัวเอง

### Query Params

| Param | Type | Default | คำอธิบาย |
|-------|------|---------|----------|
| `status` | string | (ทั้งหมด) | filter สถานะ: `pending` / `approved` / `rejected` / `cancelled`; `""` หรือ `all` = ทุกสถานะ |
| `month` | string | (ทั้งหมด) | filter เดือนของ scan, format `YYYY-MM` (เช่น `2026-10`) |
| **Offset mode:** | | | |
| `page` | int | 1 | หน้าที่ (เมื่อไม่ส่ง `limit`) |
| `per_page` | int | 20 | จำนวนต่อหน้า (max 100) |
| **Cursor mode (แนะนำสำหรับ infinite scroll):** | | | |
| `limit` | int | — | **ส่ง `limit` = เปิด cursor mode** จำนวนต่อหน้า (ต้อง > 0) |
| `cursor` | string | — | `next_cursor` จากหน้าก่อน (ไม่ส่ง = หน้าแรก) |

> **Flutter — เลือก pagination mode:**
> - **Infinite scroll:** ใช้ `?limit=20` → response meta จะมี `has_more` + `next_cursor` ส่ง `next_cursor` ต่อในหน้าถัดไป
> - **Paged table:** ใช้ `?page=1&per_page=20` → response meta มี `total` + `total_pages`
> - ห้ามผสม — ถ้ามี `limit` ระบบจะ ignore `page`/`per_page`

### Response — `200 OK`
`data` เป็น array ของ `OffsiteRequestResponse` (shape เดียวกับ POST response) + `meta`

### Errors
| HTTP | code | เกิดเมื่อ |
|------|------|----------|
| 401 | `UNAUTHORIZED` | ไม่มี token |
| 400 | `VALIDATION_ERROR` | `limit` ไม่ใช่จำนวนเต็มบวก / `cursor` พัง / `month` format ผิด |
| 400 | `EMPLOYEE_NOT_FOUND` | user ไม่มี employee record |
| 500 | `INTERNAL_ERROR` | DB error |

---

## 5. GET `/attendance/offsite-requests/my-approvals` — รายการที่ต้องอนุมัติ

คืนคำขอทุกรายการที่ผู้ใช้เกี่ยวข้องในฐานะ approver — ทั้งที่รอ action และที่เคย action ไปแล้ว
Query params / pagination / errors **เหมือน `/my` ทุกอย่าง** (รองรับทั้ง offset และ cursor mode, filter `status` + `month`)

> HR (มีสิทธิ์ `corehr:attendanceCorrection:manage`) จะเห็นคำขอที่รอ HR step ด้วย

---

## 6. GET `/attendance/offsite-requests/:id` — ดูรายการเดียว

### Response — `200 OK`
`data` = `OffsiteRequestResponse` (shape เดียวกับ POST) รวม `steps[]` ทั้งหมด

### Visibility (ใครดูได้)
มองเห็นได้เฉพาะ: **เจ้าของคำขอ**, **approver ในสาย approval**, หรือ **HR** — คนอื่นได้ `404` (ไม่เปิดเผยว่ามี record อยู่จริง)

### Errors
| HTTP | code | เกิดเมื่อ |
|------|------|----------|
| 401 | `UNAUTHORIZED` | ไม่มี token |
| 404 | `NOT_FOUND` | ไม่พบ หรือไม่มีสิทธิ์ดู |
| 500 | `INTERNAL_ERROR` | DB error |

---

## 7. PUT `/attendance/offsite-requests/:id/approve` — อนุมัติ

อนุมัติ step ปัจจุบัน (เลื่อนไป step ถัดไป หรือ finalize) เมื่ออนุมัติขั้นสุดท้าย → บันทึก punch นอกพื้นที่

### Request Body
```json
{ "step_id": "uuid", "note": "เห็นชอบ" }
```
| Field | Type | Required | คำอธิบาย |
|-------|------|----------|----------|
| `step_id` | string | ❌ | ถ้าส่งมา ต้องตรงกับ step ที่ pending อยู่ ไม่งั้นได้ `STEP_CHANGED` (กัน race เมื่อคำขอเลื่อน step ไปแล้ว) |
| `note` | string | ❌ | ความเห็นผู้อนุมัติ |

> **แนะนำให้ Flutter ส่ง `step_id` เสมอ** (เอาจาก step ที่ `status == "pending"` ใน steps[]) เพื่อกันการอนุมัติผิด step

### Response — `200 OK`
`data` = `OffsiteRequestResponse` (สถานะล่าสุดหลังอนุมัติ)

### Errors
| HTTP | code | เกิดเมื่อ | details |
|------|------|----------|---------|
| 401 | `UNAUTHORIZED` | ไม่มี token | — |
| 404 | `NOT_FOUND` | ไม่พบคำขอ | — |
| 409 | `NOT_PENDING` | คำขอไม่ได้อยู่สถานะรออนุมัติแล้ว | — |
| 409 | `STEP_CHANGED` | `step_id` ที่ส่งไม่ตรงกับ step ปัจจุบัน | — |
| 403 | `NOT_APPROVER` | ไม่ใช่ผู้อนุมัติของ step นี้ / อนุมัติคำขอตัวเองไม่ได้ / เคยอนุมัติ step อื่นไปแล้ว | — |
| 409 | `TOO_EARLY_CHECKIN` | อนุมัติแล้วแต่ punch เร็วเกินไป (rollback) | `session_label`, `session_order`, `clock_in_opens` |
| 500 | `INTERNAL_ERROR` | punch เขียนไม่สำเร็จ / DB error | — |

---

## 8. PUT `/attendance/offsite-requests/:id/reject` — ปฏิเสธ

ปฏิเสธ step ปัจจุบัน → จบคำขอ (status = `rejected`)

### Request Body
```json
{ "step_id": "uuid", "note": "เหตุผลไม่เพียงพอ" }
```
| Field | Type | Required | คำอธิบาย |
|-------|------|----------|----------|
| `step_id` | string | ❌ | เหมือน approve |
| `note` | string | ✅ | **บังคับ** — เหตุผลการปฏิเสธ (ว่างไม่ได้) |

### Response — `200 OK`
`data` = `OffsiteRequestResponse` (status = `rejected`)

### Errors
| HTTP | code | เกิดเมื่อ |
|------|------|----------|
| 401 | `UNAUTHORIZED` | ไม่มี token |
| 422 | `VALIDATION_ERROR` | `note` ว่าง (message: "note (rejection reason) is required") |
| 404 | `NOT_FOUND` | ไม่พบคำขอ |
| 409 | `NOT_PENDING` | คำขอไม่ได้อยู่สถานะรออนุมัติ |
| 409 | `STEP_CHANGED` | `step_id` ไม่ตรง step ปัจจุบัน |
| 403 | `NOT_APPROVER` | ไม่ใช่ผู้อนุมัติ / ปฏิเสธคำขอตัวเองไม่ได้ |
| 500 | `INTERNAL_ERROR` | DB error |

---

## 9. PUT `/attendance/offsite-requests/:id/cancel` — ยกเลิก

เจ้าของคำขอถอนคำขอ **ที่ยัง pending** ของตัวเอง

### Request Body
ไม่ต้องส่ง body

### Response — `200 OK`
`data` = `OffsiteRequestResponse` (status = `cancelled`)

### Errors
| HTTP | code | เกิดเมื่อ |
|------|------|----------|
| 401 | `UNAUTHORIZED` | ไม่มี token |
| 400 | `EMPLOYEE_NOT_FOUND` | user ไม่มี employee record |
| 409 | `CANNOT_CANCEL` | ไม่ใช่คำขอของตัวเอง หรือไม่ได้อยู่สถานะ pending |
| 404 | `NOT_FOUND` | ไม่พบคำขอหลังยกเลิก (rare) |
| 500 | `INTERNAL_ERROR` | DB error |

---

## 10. Data Models (สำหรับสร้าง Dart class)

### `OffsiteRequestResponse`
| field | type | nullable | note |
|-------|------|----------|------|
| `id` | String | ✗ | |
| `employee` | OffsiteEmployee | ✗ | |
| `employee_id` | String | ✗ | ซ้ำกับ employee.id เพื่อความสะดวก |
| `method` | String | ✗ | `check_in` / `check_out` |
| `latitude` | double | ✓ | |
| `longitude` | double | ✓ | |
| `scan_timestamp` | String (datetime) | ✗ | `yyyy-MM-dd HH:mm:ss` |
| `scan_date` | String | ✗ | `yyyy-MM-dd` วันทำงาน tenant-local |
| `session_order` | int | ✗ | |
| `shift_detail_id` | String | ✓ | |
| `shift_detail` | ShiftDetailRef | ✓ | null เมื่อไม่ตรง shift |
| `attachment` | OffsiteAttachment | ✗ | |
| `reason` | String | ✗ | |
| `status` | String | ✗ | `pending`/`approved`/`rejected`/`cancelled` |
| `current_step_no` | int | ✗ | |
| `attendance_record_id` | String | ✓ | มีค่าเมื่อ punch บันทึกแล้ว |
| `created_at` | String (datetime) | ✗ | |
| `updated_at` | String (datetime) | ✗ | |
| `steps` | List\<OffsiteStep\> | ✗ | |

### `OffsiteStep`
| field | type | nullable | note |
|-------|------|----------|------|
| `id` | String | ✗ | |
| `step_no` | int | ✗ | |
| `step_role` | String | ✗ | `dept_head` / `hr` / `specific` |
| `approver` | OffsiteStepApprover | ✓ | null จนกว่าจะ act / HR step ที่ยังไม่ระบุคน |
| `status` | String | ✗ | `waiting` / `pending` / `approved` / `rejected` |
| `note` | String | ✓ | |
| `acted_at` | String (datetime) | ✓ | |
| `created_at` | String (datetime) | ✗ | |

### `OffsiteStepApprover`
| field | type | nullable |
|-------|------|----------|
| `id` | String | ✗ |
| `name` | String | ✓ |

### `OffsiteEmployee`
| field | type | nullable |
|-------|------|----------|
| `id` | String | ✗ |
| `name` | String | ✓ |
| `employee_number` | String | ✓ |
| `department` | DepartmentRef | ✓ |

### `OffsiteAttachment` (response)
| field | type | nullable |
|-------|------|----------|
| `url` | String | ✗ |
| `file_name` | String | ✗ |
| `original_name` | String | ✓ |
| `content_type` | String | ✓ |
| `size` | int | ✓ |

### `ShiftDetailRef`
| field | type | nullable | note |
|-------|------|----------|------|
| `id` | String | ✗ | |
| `name` | String | ✓ | |
| `name_lo` | String | ✓ | ชื่อภาษาลาว |
| `sort_order` | int | ✓ | ลำดับ segment (1-based) |
| `start_time` | String | ✓ | `"08:00"` |
| `end_time` | String | ✓ | `"12:00"` |
| `break_minutes` | int | ✓ | |
| `working_hours` | double | ✓ | |
| `late_grace_minutes` | int | ✓ | |
| `early_exit_grace_minutes` | int | ✓ | |
| `overtime_eligible` | bool | ✓ | |
| `shift` | ShiftRef | ✓ | |

### `ShiftRef` / `DepartmentRef`
| field | type | nullable |
|-------|------|----------|
| `id` | String | ✗ |
| `name` | String | ✓ |
| `name_lo` | String | ✓ |
| `code` (ShiftRef only) | String | ✓ |

---

## 11. แนวทาง Flutter: Error Handling

### 11.1 โครงสร้าง parse error กลาง
```dart
class ApiException implements Exception {
  final int status;
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final Map<String, List<String>>? fieldErrors; // จาก 422

  ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.details,
    this.fieldErrors,
  });

  factory ApiException.fromResponse(int status, Map<String, dynamic> body) {
    final error = body['error'] as Map<String, dynamic>?;
    Map<String, List<String>>? fieldErrors;
    if (body['errors'] is Map) {
      fieldErrors = (body['errors'] as Map).map(
        (k, v) => MapEntry(k as String, List<String>.from(v as List)),
      );
    }
    return ApiException(
      status: status,
      code: error?['code'] as String? ?? 'UNKNOWN',
      message: (body['message'] as String?) ??
               error?['message'] as String? ?? 'เกิดข้อผิดพลาด',
      details: error?['details'] as Map<String, dynamic>?,
      fieldErrors: fieldErrors,
    );
  }
}
```

### 11.2 Validate ฝั่ง client ก่อนยิง POST (กัน 422)
```dart
String? validateOffsiteRequest({
  required String method,
  required double? lat,
  required double? lng,
  required String reason,
  required Map<String, dynamic>? attachment,
}) {
  if (method != 'check_in' && method != 'check_out') return 'กรุณาเลือกประเภทการสแกน';
  if (lat == null || lng == null) return 'ไม่พบตำแหน่ง GPS กรุณาเปิด Location';
  if (reason.trim().isEmpty) return 'กรุณาระบุเหตุผล';
  if (attachment == null ||
      (attachment['url'] as String?)?.isEmpty != false ||
      (attachment['file_name'] as String?)?.isEmpty != false) {
    return 'กรุณาแนบรูปถ่าย';
  }
  return null; // ผ่าน
}
```

### 11.3 แมป error code → ข้อความ/การกระทำ
```dart
String userMessage(ApiException e) {
  switch (e.code) {
    case 'OFFSITE_REQUEST_EXISTS':
      return 'คุณมีคำขอสแกนนอกพื้นที่ของช่วงนี้อยู่แล้ว กรุณารอผลการอนุมัติ';
    case 'TOO_EARLY_CHECKIN':
      final opens = e.details?['clock_in_opens'];
      return 'ยังไม่ถึงเวลาเช็คอิน จะเปิดให้สแกนเวลา $opens';
    case 'AFTER_CHECKOUT_WINDOW':
      return 'เลยเวลาเช็คเอาท์แล้ว (ถึง ${e.details?['latest_checkout']})';
    case 'SESSION_ALREADY_STARTED':
      return 'คุณเช็คอินช่วงนี้ไปแล้ว กรุณาเช็คเอาท์แทน';
    case 'SESSION_ALREADY_CHECKED_OUT':
    case 'SESSION_ALREADY_COMPLETED':
      return 'ช่วงเวลานี้บันทึกครบแล้ว';
    case 'SESSION_NOT_STARTED':
      return 'ยังไม่ได้เช็คอินช่วงนี้ กรุณาเช็คอินก่อน';
    case 'OUTSIDE_SHIFT_HOURS':
      return 'เลยเวลางานของวันนี้แล้ว (กะสุดท้ายจบ ${e.details?['last_shift_end']})';
    case 'OVERNIGHT_SESSION_DONE':
      return 'คุณทำกะข้ามคืนนี้ไปแล้ว';
    case 'NOT_APPROVER':
      return 'คุณไม่มีสิทธิ์ดำเนินการกับคำขอนี้';
    case 'NOT_PENDING':
      return 'คำขอนี้ถูกดำเนินการไปแล้ว';
    case 'STEP_CHANGED':
      return 'คำขอนี้เปลี่ยนขั้นตอนการอนุมัติแล้ว กรุณารีเฟรช';
    case 'CANNOT_CANCEL':
      return 'ยกเลิกได้เฉพาะคำขอของตัวเองที่ยังรออนุมัติ';
    case 'EMPLOYEE_NOT_FOUND':
      return 'ไม่พบข้อมูลพนักงานของบัญชีนี้ กรุณาติดต่อ HR';
    case 'UNAUTHORIZED':
      return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'; // + redirect login
    case 'VALIDATION_ERROR':
      return e.fieldErrors?.values.first.first ?? e.message;
    default:
      return e.message;
  }
}
```

### 11.4 ข้อควรระวัง
- `scan_timestamp`, `created_at` ฯลฯ เป็น **local time ไม่มี timezone** → parse ด้วย `DateFormat('yyyy-MM-dd HH:mm:ss').parse(str)` อย่าใช้ `DateTime.parse` ที่คาด ISO-8601 (จะได้ UTC ผิด)
- `latitude`/`longitude` อาจกลับมา `null` ใน response → เผื่อ nullable
- cursor mode: เก็บ `next_cursor` และยิง `?limit=&cursor=` ต่อ หยุดเมื่อ `has_more == false`
- 409 บน POST ไม่ใช่ "ระบบพัง" แต่คือ "business rule ปฏิเสธ" → แสดงข้อความจาก `userMessage()` ไม่ใช่ error สีแดงแบบ crash

---

## 12. Flow Diagram (ย่อ)

```
[พนักงานกด clock-in นอกพื้นที่]
        │
        ▼
POST /attendance/offsite-requests  (method + lat/lng + reason + attachment)
        │
   ┌────┴─────────────────────────┐
   │ มี can_work_offsite?          │
   ├──────────────┬───────────────┤
   ▼ ใช่           ▼ ไม่
status=approved   status=pending
punch บันทึกทันที   รอ HR / dept_head
                   │
                   ▼
            PUT :id/approve (approver)
                   │
          ┌────────┴────────┐
          ▼ final approve    ▼ reject
     punch บันทึก         status=rejected
     status=approved
```

---

*เอกสารนี้อ้างอิงจาก source: `internal/modules/corehr/attendance/offsite_request_handler.go`, `offsite_request_types.go`, `offsite_types.go`, `types.go`, `handler.go`*

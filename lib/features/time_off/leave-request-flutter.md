# Leave Request & Approval — Frontend Integration Guide

เอกสารสำหรับ implement **การขอลาพัก (leave request)** และ **การอนุมัติแบบหลายขั้น (multi-step approval)** บน frontend (มือถือ/เว็บ)

- **Base URL:** `/api/v1/core_hr`
- **Auth:** ทุก endpoint ในเอกสารนี้ต้องส่ง `Authorization: Bearer <access_token>`
- **Content-Type:** `application/json`
- **Tenant:** ระบุ tenant ผ่าน subdomain (`thenice.nexton.work`) หรือ (dev เท่านั้น) header `X-Tenant-Slug: <slug>`

---

## 1. Response envelope (รูปแบบมาตรฐาน)

**สำเร็จ (single object)** — `200 OK` / `201 Created`
```json
{ "success": true, "data": { /* ... */ } }
```

**สำเร็จ (list + offset pagination)** — `200 OK`
```json
{
  "success": true,
  "data": [ /* ... */ ],
  "meta": { "page": 1, "per_page": 20, "total": 42, "total_pages": 3 }
}
```

**สำเร็จ (list + keyset/cursor pagination)** — `200 OK` (เมื่อส่ง `?limit=`)
```json
{
  "success": true,
  "data": [ /* ... */ ],
  "meta": { "per_page": 10, "has_more": true, "next_cursor": "MjAyNi0wOC0yOFQ..." }
}
```

**Error** — status ตามชนิด error
```json
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "..." } }
```

> **หมายเหตุ:** เฉพาะ `422 VALIDATION_ERROR` และ `409 DUPLICATE` จะมี key เพิ่ม `message` และ `errors: { field: [".."] }` ระดับบนสุด (Laravel-style) สำหรับผูกกับ form ได้ตรง ๆ

---

## 2. โครงสร้างการอนุมัติ (Approval Workflow)

ใบลา 1 ใบ = มี **หลาย step** (`steps[]`) เรียงตามลำดับ อนุมัติ **ทีละขั้น**

### ลำดับ step เริ่มต้น (default)
1. **`dept_head`** — หัวหน้าแผนกของผู้ขอ (ดึงจาก `employees.reports_to`)
2. **`hr`** — ฝ่าย HR (คนที่มีสิทธิ์ `corehr:leaveRequest:manage`)

> ถ้าผู้ขอ**ไม่มีหัวหน้าแผนก** → ข้าม step `dept_head` เหลือแค่ `hr` (HR-only)
> ลำดับนี้ **ตั้งค่าได้ต่อ tenant** (ตาราง `approval_workflows`) — อาจมี 1, 2 หรือ 3 ขั้น โดยไม่ต้องแก้โค้ด

### สถานะของ step (`steps[].status`)
| ค่า | ความหมาย |
|---|---|
| `waiting` | ยังไม่ถึงคิว (step ก่อนหน้ายังไม่อนุมัติ) |
| `pending` | **ถึงคิวแล้ว รออนุมัติ** ← step ปัจจุบัน |
| `approved` | ขั้นนี้อนุมัติแล้ว |
| `rejected` | ขั้นนี้ปฏิเสธ (ทำให้ทั้งใบ = rejected) |

### สถานะของทั้งใบ (`status`)
| ค่า | ความหมาย |
|---|---|
| `pending` | กำลังรออนุมัติ (มี step ที่ `pending` อยู่) |
| `approved` | อนุมัติครบทุกขั้นแล้ว |
| `rejected` | ถูกปฏิเสธที่ขั้นใดขั้นหนึ่ง |
| `cancelled` | ผู้ขอ/HR ยกเลิก |

### กฎการอนุมัติ (สำคัญมากสำหรับ frontend)
- **อนุมัติเรียงขั้นเท่านั้น** — HR อนุมัติก่อนหัวหน้าแผนกไม่ได้ (step `hr` จะกลายเป็น `pending` ก็ต่อเมื่อ `dept_head` อนุมัติแล้ว)
- **step `dept_head`:** เฉพาะ**หัวหน้าที่ถูก assign**เท่านั้นที่กดได้ (HR override ไม่ได้ในขั้นนี้)
- **step `hr`:** เฉพาะคนที่มีสิทธิ์ `corehr:leaveRequest:manage`
- **ห้ามอนุมัติใบของตัวเอง** เสมอ
- **ปฏิเสธ (reject) ที่ขั้นไหนก็ได้** → ทั้งใบกลายเป็น `rejected` ทันที
- **อนุมัติขั้นสุดท้าย** → ทั้งใบ `approved` และ**หักโควตาวันลา**จริง

### balance เปลี่ยนตอนไหน
| เหตุการณ์ | ผลต่อ balance |
|---|---|
| สร้างใบลา (submit) | `pending_days += X`, `remaining_days -= X` (จอง) |
| อนุมัติครบทุกขั้น | ย้ายจาก pending → `used_days += X` |
| ปฏิเสธ | คืนโควตา (`pending_days -= X`, `remaining_days += X`) |
| ยกเลิกตอน pending | คืนโควตา (เหมือน reject) |
| ยกเลิกตอน approved | คืน `used_days -= X`, `remaining_days += X` |

---

## 3. Endpoints

### 3.1 `GET /leave/balances/my` — โควตาวันลาของฉัน
ใช้แสดงโควตาก่อนเปิดฟอร์มขอลา

**Query:** `year` (optional, default = ปีปัจจุบัน)

**Response `200`:**
```json
{
  "success": true,
  "data": [
    {
      "id": "…", "employee_id": "…",
      "leave_type_id": "705c…", "leave_type_name": "Annual Leave", "leave_type_code": "ANNUAL",
      "year": 2026,
      "total_days": 15, "used_days": 3, "pending_days": 2,
      "remaining_days": 10, "carried_forward_days": 0,
      "created_at": "…", "updated_at": "…"
    }
  ]
}
```
> `remaining_days` = จำนวนที่ขอลาได้จริง (ควรใช้ตัวนี้ validate ฝั่ง frontend ก่อนส่ง)

---

### 3.2 `GET /leave/types` — รายการประเภทการลา (dropdown)
ใช้เติม dropdown "ประเภทการลา" ในฟอร์ม

**Response `200`:** array ของ `LeaveTypeResponse` — field ที่ frontend ใช้บ่อย:
```json
{
  "id": "705c…", "name": "Annual Leave", "name_lo": "ພັກປະຈຳປີ", "code": "ANNUAL",
  "color": "#4CAF50",
  "max_days_per_request": 10, "max_consecutive_days": 5,
  "min_notice_days": 3, "allow_half_day": true,
  "requires_attachment": false, "allow_negative_balance": false,
  "is_paid": true, "is_active": true
}
```
> ใช้ `allow_half_day`, `requires_attachment`, `max_days_per_request` เพื่อคุม UI ของฟอร์ม

---

### 3.3 `POST /leave/requests` — สร้างใบขอลา
สิทธิ์: พนักงานที่ล็อกอิน (ผูกกับ employee record) — ระบบดึง employee id จาก JWT เอง

**Request body:**
```json
{
  "leave_type_id": "705c5a79-…",        // required
  "dates": ["2026-09-01", "2026-09-03"], // เลือกวันแบบไม่ต่อเนื่องได้
  "duration_type": "full_day",           // full_day | first_half | second_half
  "return_date": "2026-09-04",           // optional
  "reason": "ไปธุระต่างจังหวัด",           // optional
  "attachments": [                       // optional
    { "url": "https://…/file.jpg", "file_name": "mc.jpg", "content_type": "image/jpeg", "size": 12345 }
  ]
}
```

**เลือกวันได้ 2 แบบ (ต้องมีอย่างใดอย่างหนึ่ง):**
1. **`dates[]`** — ระบุวันที่ต้องการลาแบบเจาะจง (ไม่ต่อเนื่องได้) → `total_days = จำนวนวันใน dates` (นับทุกวันที่ส่งมา ไม่ตัดเสาร์-อาทิตย์)
2. **`start_date` + `end_date`** — ช่วงต่อเนื่อง → `total_days` = จำนวนวันในช่วง **หักวันหยุดสุดสัปดาห์** (ตาม `company_profile.weekend_days`, default เสาร์-อาทิตย์)

**Half-day:** ตั้ง `duration_type` = `first_half`/`second_half` → ต้องเลือก **1 วันเท่านั้น** → `total_days = 0.5`

**Attachments** รับได้ 3 แบบ: object เต็ม, URL string เดี่ยว, หรือ array ผสม

**Response `201 Created`:** object `LeaveRequestResponse` (ดูโครงสร้างข้อ 3.6)

**Validation & Errors:**
| Status | code | เมื่อไหร่ |
|---|---|---|
| `422` | `VALIDATION_ERROR` | `leave_type_id` ว่าง / `duration_type` ไม่ใช่ค่าที่กำหนด |
| `400` | `VALIDATION_ERROR` | ไม่ส่งทั้ง `dates` และ `start_date/end_date` / วันที่ format ผิด / `end_date` ก่อน `start_date` / half-day เลือกเกิน 1 วัน / `return_date` ไม่ถูกต้องหรือไม่หลัง `end_date` / เลือกแล้วได้ 0 วัน |
| `409` | `PENDING_REQUEST_EXISTS` | มีใบลาที่ยังรออนุมัติค้างอยู่ (ต้องรอให้ใบเดิมจบก่อน) |
| `409` | `OVERLAPPING_LEAVE` | วันที่เลือกทับกับใบลาเดิม (pending/approved) |
| `422` | `INSUFFICIENT_BALANCE` | โควตาคงเหลือไม่พอ (เฉพาะประเภทที่ `allow_negative_balance=false`) |
| `400` | `EMPLOYEE_NOT_FOUND` | user ที่ล็อกอินไม่ได้ผูกกับ employee |

---

### 3.4 `PUT /leave/requests/:id` — แก้ไขใบขอลา
แก้ได้เฉพาะใบที่ **`status = pending`** เท่านั้น
สิทธิ์: เจ้าของใบ หรือ HR (`corehr:leaveRequest:manage`)

**Request body** (ทุก field เป็น optional — ส่งเฉพาะที่จะเปลี่ยน):
```json
{
  "leave_type_id": "…",
  "dates": ["2026-09-02"],          // หรือ start_date + end_date
  "start_date": "…", "end_date": "…",
  "duration_type": "full_day",
  "return_date": "2026-09-05",
  "reason": "…",
  "attachments": [ /* … */ ]         // ส่งมา = แทนที่ทั้งหมด; ไม่ส่ง key = คงเดิม
}
```
> ถ้าเปลี่ยนวัน (`dates` หรือ `start_date+end_date`) ระบบจะ recompute `total_days` และปรับ balance ที่จองไว้ให้อัตโนมัติ

**Response `200`:** `LeaveRequestResponse` ที่อัปเดตแล้ว

**Errors:**
| Status | code | เมื่อไหร่ |
|---|---|---|
| `404` | `NOT_FOUND` | id ไม่ใช่ UUID / ไม่พบใบ / ไม่ใช่เจ้าของ (และไม่ใช่ HR) |
| `400` | `INVALID_STATUS` | ใบไม่ได้อยู่สถานะ `pending` |
| `400` | `VALIDATION_ERROR` | date/return_date/half-day/zero-day ไม่ผ่าน (เหมือน create) |
| `409` | `OVERLAPPING_LEAVE` | วันใหม่ทับใบลาอื่น |
| `422` | `INSUFFICIENT_BALANCE` | เพิ่มจำนวนวันแล้วโควตาไม่พอ |

---

### 3.5 `PUT /leave/requests/:id/cancel` — ยกเลิกใบขอลา
สิทธิ์: เจ้าของใบ หรือ HR
ยกเลิกได้เมื่อ `status` = `pending` **หรือ** `approved` (คืนโควตาให้อัตโนมัติ)

**Request body:** ไม่มี (ไม่ต้องส่ง)

**Response `200`:** `LeaveRequestResponse` (status = `cancelled`)

**Errors:**
| Status | code | เมื่อไหร่ |
|---|---|---|
| `404` | `NOT_FOUND` | ไม่พบใบ |
| `403` | `FORBIDDEN` | ไม่ใช่เจ้าของใบ (และไม่ใช่ HR) |
| `400` | `INVALID_STATUS` | ใบไม่ได้อยู่ `pending`/`approved` (เช่น rejected/cancelled แล้ว) |

---

### 3.6 `GET /leave/requests/my` — ใบลาของฉัน (list)
สิทธิ์: พนักงานที่ล็อกอิน (เห็นเฉพาะของตัวเอง)

**Query params (filter รวมกันได้):**
| param | ความหมาย | หมายเหตุ |
|---|---|---|
| `leave_type_id` | กรองตามประเภท | ใส่ **UUID** หรือ `all` = ทุกประเภท |
| `status` | `pending`/`approved`/`rejected`/`cancelled` | หรือ `all` = ทุกสถานะ |
| `start_date` | ใบลาที่ `start_date >= ค่านี้` | `YYYY-MM-DD` |
| `end_date` | ใบลาที่ `end_date <= ค่านี้` | `YYYY-MM-DD` |
| `year` | ปีของ `start_date` | |
| `limit` | เปิด **keyset mode** (infinite scroll) | ตัวเลข > 0 |
| `cursor` | token หน้าถัดไป (จาก `meta.next_cursor`) | keyset เท่านั้น |
| `page`, `per_page` | offset mode (default) | |

> **สองโหมด pagination:** ส่ง `?limit=10` → keyset (มือถือ scroll), ไม่ส่ง → offset (`?page=&per_page=`)
> เรียงใหม่สุดก่อนเสมอ (`created_at DESC`)

**Response (keyset):**
```json
{
  "success": true,
  "data": [ /* LeaveRequestResponse[] */ ],
  "meta": { "per_page": 10, "has_more": true, "next_cursor": "…" }
}
```

**โครงสร้าง `LeaveRequestResponse`:**
```json
{
  "id": "29de3e8c-…",
  "employee": {
    "id": "9ef7…", "name": "Sandy Vang",
    "employee_number": "EMP-002", "department_name": "IT Development"
  },
  "leave_type": { "id": "705c…", "name": "Annual Leave", "code": "ANNUAL", "color": "#4CAF50" },
  "start_date": "2026-08-24",
  "end_date": "2026-08-26",
  "request_days": ["2026-08-24", "2026-08-25", "2026-08-26"],
  "return_date": "2026-08-27",
  "total_days": 3,
  "duration_type": "full_day",
  "reason": "ไปธุระ",
  "status": "pending",
  "current_step_no": 1,
  "steps": [
    {
      "id": "…", "step_no": 1, "step_role": "dept_head",
      "approver": { "id": "ce86…", "name": "Alex Vang" },
      "status": "pending", "note": null,
      "created_at": "…", "updated_at": "…"
    },
    {
      "id": "…", "step_no": 2, "step_role": "hr",
      "approver": null,
      "status": "waiting", "note": null,
      "created_at": "…", "updated_at": "…"
    }
  ],
  "attachments": [
    { "id": "…", "file_name": "mc.jpg", "original_name": "mc.jpg",
      "url": "https://…", "content_type": "image/jpeg", "size": 12345, "created_at": "…" }
  ],
  "created_at": "…", "updated_at": "…"
}
```
> `current_step_no` = ลำดับ step ที่กำลัง `pending` — ใช้ highlight ใน UI timeline ได้

---

### 3.7 `GET /leave/requests/:id` — รายละเอียดใบลา
สิทธิ์: เจ้าของใบ / ผู้อนุมัติที่ถูก assign ในใบนี้ / HR
> คนอื่นจะได้ `404 NOT_FOUND` (จงใจ ไม่ใช่ 403 เพื่อไม่ให้เดา id ได้)

**Response `200`:** `LeaveRequestResponse` (โครงเดียวกับ 3.6)

**Errors:** `404 NOT_FOUND` (id ไม่ใช่ UUID / ไม่พบ / ไม่มีสิทธิ์ดู)

---

### 3.8 `GET /leave/requests/my-approvals` — ใบลาที่ฉันต้องอนุมัติ / เคยอนุมัติ
สำหรับ**ผู้อนุมัติ** (หัวหน้าแผนก / HR) — คืนใบลาที่:
- **รอฉันอนุมัติ** (step `dept_head` ที่ assign ให้ฉันและ pending, หรือ step `hr` ที่ pending เมื่อฉันเป็น HR)
- **ฉันเคยกด**ไปแล้ว (approved/rejected)

> ไม่มี permission gate ที่ระดับ route — query scope ตามตัวผู้เรียกเอง (คนที่ไม่ใช่ผู้อนุมัติจะได้ list ว่าง)

**Query params:**
| param | ความหมาย |
|---|---|
| `status` | กรองตามสถานะของ**ทั้งใบ** (`pending`/`approved`/`rejected`/`cancelled`) หรือ `all`/ไม่ส่ง = ทุกสถานะ |
| `limit` + `cursor` | keyset mode (เรียง `updated_at DESC`) |
| `page`, `per_page` | offset mode (default) |

**Response:** list ของ `LeaveRequestResponse` (โครงเดียวกับ 3.6)

> **Flow แนะนำ:** หน้า "รออนุมัติ" → เรียก `?status=pending`; หน้า "ประวัติ" → `?status=approved` หรือ `?status=rejected`

---

### 3.9 `PUT /leave/requests/:id/approve` — อนุมัติ (step ปัจจุบัน)
สิทธิ์: ผู้อนุมัติของ **step ที่กำลัง pending** เท่านั้น (ดูกฎในข้อ 2)

**Request body:**
```json
{
  "approver_note": "อนุมัติ",   // optional
  "step_id": "…"               // optional — ดูหมายเหตุ concurrency
}
```
> **`step_id` (แนะนำให้ส่ง):** ควรส่ง id ของ step ที่กำลัง pending (จาก `steps[]`) เพื่อกันการกดชนกัน ถ้ามีคนอื่นเลื่อน step ไปแล้วจะได้ `409 STEP_CHANGED` ให้ refresh

**พฤติกรรม:**
- อนุมัติ **step ปัจจุบัน** → ถ้ายังมี step ถัดไป, step นั้นกลายเป็น `pending`; ทั้งใบยังคง `pending`
- อนุมัติ **step สุดท้าย** → ทั้งใบ `approved` + หักโควตาจริง + ส่ง notification

**Response `200`:** `LeaveRequestResponse` (อัปเดตแล้ว)

**Errors:**
| Status | code | เมื่อไหร่ |
|---|---|---|
| `404` | `NOT_FOUND` | ไม่พบใบ |
| `400` | `INVALID_STATUS` | ใบไม่ได้อยู่ `pending` |
| `409` | `STEP_CHANGED` | `step_id` ที่ส่งมาไม่ใช่ step ปัจจุบันแล้ว |
| `403` | `NOT_APPROVER` | ไม่ใช่ผู้อนุมัติของ step นี้ / พยายามอนุมัติใบตัวเอง |

---

### 3.10 `PUT /leave/requests/:id/reject` — ปฏิเสธ
สิทธิ์: เหมือน approve (ผู้อนุมัติของ step ปัจจุบัน)
ปฏิเสธที่ขั้นไหนก็ได้ → ทั้งใบ `rejected` ทันที + คืนโควตา

**Request body:**
```json
{
  "reason": "เอกสารไม่ครบ",     // required
  "approver_note": "…",         // optional
  "step_id": "…"                // optional (เหมือน approve)
}
```

**Response `200`:** `LeaveRequestResponse` (status = `rejected`, step ที่ปฏิเสธมี `note` = reason)

**Errors:**
| Status | code | เมื่อไหร่ |
|---|---|---|
| `422` | `VALIDATION_ERROR` | `reason` ว่าง |
| `404` | `NOT_FOUND` | ไม่พบใบ |
| `400` | `INVALID_STATUS` | ใบไม่ได้อยู่ `pending` |
| `409` | `STEP_CHANGED` | `step_id` ไม่ใช่ step ปัจจุบัน |
| `403` | `NOT_APPROVER` | ไม่ใช่ผู้อนุมัติของ step นี้ / ใบตัวเอง |

---

## 4. ตารางรวม Error codes
| code | HTTP | ความหมาย |
|---|---|---|
| `VALIDATION_ERROR` | 400 / 422 | ข้อมูลไม่ผ่าน validation (422 = schema, 400 = business rule เรื่องวันที่) |
| `INVALID_STATUS` | 400 | ทำ action กับใบที่สถานะไม่ถูกต้อง |
| `PENDING_REQUEST_EXISTS` | 409 | มีใบลาค้างรออนุมัติอยู่แล้ว |
| `OVERLAPPING_LEAVE` | 409 | วันที่ทับกับใบลาเดิม |
| `STEP_CHANGED` | 409 | step ปัจจุบันเปลี่ยนไปแล้ว (กดชนกัน) |
| `INSUFFICIENT_BALANCE` | 422 | โควตาคงเหลือไม่พอ |
| `NOT_APPROVER` | 403 | ไม่มีสิทธิ์อนุมัติ step นี้ / อนุมัติใบตัวเอง |
| `FORBIDDEN` | 403 | ยกเลิกใบที่ไม่ใช่ของตัวเอง |
| `NOT_FOUND` | 404 | ไม่พบใบ / ไม่มีสิทธิ์เข้าถึง |
| `EMPLOYEE_NOT_FOUND` | 400 | user ล็อกอินไม่ผูกกับ employee |
| `UNAUTHORIZED` / `MISSING_TOKEN` | 401 | ไม่มี/ไม่ถูกต้อง token |
| `TENANT_UNAVAILABLE` | 503 | resolve tenant DB ไม่ได้ |

---

## 5. State machine (สรุปวงจรใบลา)

```
                 submit
                   │
                   ▼
              ┌─────────┐   reject (ขั้นใดก็ได้)   ┌──────────┐
              │ pending │ ───────────────────────▶ │ rejected │
              └─────────┘                          └──────────┘
               │   │  │
     approve   │   │  │  cancel
   (ขั้นสุดท้าย) │   │  └───────────────────────┐
               │   │ approve (ขั้นกลาง)         ▼
               │   └──▶ pending (step ถัดไป)  ┌───────────┐
               ▼                              │ cancelled │
          ┌──────────┐        cancel          └───────────┘
          │ approved │ ─────────────────────────────▲
          └──────────┘                               │
               └───────────────────────────────────┘
```

- `pending → approved` : อนุมัติครบทุก step
- `pending → rejected` : reject ที่ step ใดก็ได้
- `pending → cancelled` : เจ้าของ/HR ยกเลิก
- `approved → cancelled` : ยกเลิกหลังอนุมัติแล้ว (คืนโควตา)
- `rejected` / `cancelled` = สถานะสุดท้าย (แก้ไข/ยกเลิกต่อไม่ได้)

---

## 6. Flow แนะนำสำหรับ frontend

**ฝั่งพนักงาน (ขอลา):**
1. เปิดฟอร์ม → `GET /leave/types` (dropdown) + `GET /leave/balances/my` (โชว์โควตา)
2. Validate ฝั่ง client: `total_days <= remaining_days`, half-day ต้องเลือก 1 วัน, ถ้า `requires_attachment=true` ต้องแนบไฟล์
3. `POST /leave/requests` → จับ error `PENDING_REQUEST_EXISTS` / `OVERLAPPING_LEAVE` / `INSUFFICIENT_BALANCE` แสดงข้อความให้ผู้ใช้
4. หน้า "ใบลาของฉัน" → `GET /leave/requests/my` (keyset `?limit=`); แตะเข้าไปดู timeline จาก `steps[]`
5. แก้ไข/ยกเลิกได้เฉพาะตอน `pending` (cancel ได้ถึง `approved`)

**ฝั่งผู้อนุมัติ:**
1. Badge "รออนุมัติ" → `GET /leave/requests/my-approvals?status=pending`
2. หน้ารายละเอียด → หา step ที่ `status="pending"` เก็บ `step.id`
3. กดอนุมัติ → `PUT /:id/approve` พร้อม `step_id`; กดปฏิเสธ → `PUT /:id/reject` พร้อม `reason` + `step_id`
4. เจอ `409 STEP_CHANGED` → refresh ใบแล้วให้กดใหม่
5. หน้า "ประวัติ" → `my-approvals?status=approved` / `?status=rejected`

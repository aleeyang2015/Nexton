# Auth / Login API — Flutter Integration Guide

คู่มือ API สำหรับ **การเข้าสู่ระบบ (Login)** + **ต่ออายุ token (Refresh)** — ใช้ JWT (access + refresh token) แยก secret ตาม audience (tenant / admin)

---

## 1. Base URL & Headers

| | ค่า |
|---|---|
| Base URL (prod) | `https://api.nexton.work/api/v1` |
| Base URL (dev)  | `http://localhost:8081/api/v1` |

**Headers:**
```
Content-Type: application/json
```
> **Dev เท่านั้น:** บน `localhost` ต้องแนบ `X-Tenant-Slug: <company-slug>` เพื่อบอกว่า login เข้า tenant ไหน (เช่น `X-Tenant-Slug: nexton-demo`)
> **Prod:** ระบบอ่าน tenant จาก subdomain อัตโนมัติ (เช่น `thenice.nexton.work` → tenant = `thenice`) — **ไม่ต้องส่ง** header นี้

---

## 2. POST `/auth/login` — เข้าสู่ระบบ

### Request Body
```json
{
  "email": "user@company.com",
  "password": "P@ssw0rd123"
}
```
| field | ชนิด | กติกา |
|-------|------|-------|
| `email` | string | บังคับ, ต้องเป็นอีเมล |
| `password` | string | บังคับ, อย่างน้อย 8 ตัว |

### Response `200`
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_at": 1790000000,
    "must_change_password": false,
    "roles": ["employee"],
    "is_department_head": false
  }
}
```

| field | ชนิด | ความหมาย |
|-------|------|----------|
| `access_token` | string (JWT) | token สำหรับเรียก API (แนบ `Authorization: Bearer`) |
| `refresh_token` | string (JWT) | ใช้ขอ access token ใหม่เมื่อหมดอายุ |
| `expires_at` | int (unix epoch วินาที) | เวลาหมดอายุของ access_token |
| `must_change_password` | bool | `true` = บังคับเปลี่ยนรหัสก่อนใช้งาน (โชว์หน้าเปลี่ยนรหัส) |
| `roles` | string[] | role keys ของ user เช่น `["employee"]`, `["hr_manager"]`, `["superadmin"]` |
| `is_department_head` | bool | `true` = user เป็นหัวหน้าแผนก (โชว์เมนูอนุมัติของทีมได้) |

### Errors
| HTTP | code | สาเหตุ | การจัดการใน UI |
|------|------|--------|----------------|
| 401 | `INVALID_CREDENTIALS` | อีเมล/รหัสผิด | แจ้ง "อีเมลหรือรหัสผ่านไม่ถูกต้อง" |
| 403 | `USER_INACTIVE` | บัญชีถูกปิดใช้งาน | แจ้งติดต่อ HR/admin |
| 429 | `TOO_MANY_LOGIN_ATTEMPTS` | ลองผิดถี่เกินไป | อ่าน header `Retry-After` (วินาที) แล้ว disable ปุ่มชั่วคราว |
| 422 | `VALIDATION_ERROR` | body ผิด format (อีเมลไม่ถูก / รหัสสั้น) | โชว์ error ใต้ field (มี key `errors`) |
| 400 | `INVALID_REQUEST` | body ไม่ใช่ JSON | — |
| 400 | `SUBDOMAIN_REQUIRED` | strict mode: login ไม่ได้ระบุ tenant (เฉพาะ prod บาง host) | ให้ login ผ่าน subdomain บริษัท |
| 500 | `INTERNAL_ERROR` | error ฝั่ง server | แจ้งลองใหม่ |

**ตัวอย่าง error body:**
```json
{ "success": false, "error": { "code": "INVALID_CREDENTIALS", "message": "Invalid email or password" } }
```
> `422 VALIDATION_ERROR` จะมี key เพิ่ม `errors: { "email": ["must be a valid email address"] }` ให้ map ขึ้น form ได้

---

## 3. POST `/auth/refresh` — ต่ออายุ token

เมื่อ `access_token` หมดอายุ (401 `INVALID_TOKEN`/`TOKEN_EXPIRED`) ให้ใช้ `refresh_token` ขอคู่ใหม่

### Request Body
```json
{ "refresh_token": "eyJhbGci..." }
```
> **Dev:** แนบ `X-Tenant-Slug` เหมือน login

### Response `200`
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...ใหม่...",
    "refresh_token": "eyJ...ใหม่...",
    "expires_at": 1790000900
  }
}
```
> ได้ **refresh_token ใหม่ทุกครั้ง** (rotation) — ให้เก็บทับตัวเก่าเสมอ
> ถ้า refresh ล้มเหลว (`401`) = ต้อง login ใหม่

---

## 4. โครงสร้าง JWT (access_token payload)

ถ้าต้องอ่านข้อมูลจาก token ฝั่ง client (เช่น `jwt_decode`) จะได้:
```json
{
  "user_id": "ee6f0143-6350-4532-9b7d-a1bbe64c1e35",
  "tenant_id": "2e4ad2bf-179d-409f-8f36-227e00e83290",
  "email": "user@company.com",
  "modules": ["core_hr", "payroll", "recruitment", "..."],
  "roles": ["employee"],
  "permissions": ["corehr:employee:view", "..."],
  "sid": "session-uuid",
  "aud": "nexton.tenant",
  "exp": 1790000000,
  "iat": 1789999100
}
```
| claim | ใช้ทำอะไร |
|-------|-----------|
| `modules` | โมดูลที่ tenant เปิดใช้ — ซ่อน/โชว์เมนูตามนี้ |
| `roles` | บทบาท (เหมือน `roles` ใน login response) |
| `permissions` | สิทธิ์ละเอียด — gate ปุ่ม/หน้าได้ |
| `exp` | หมดอายุ (unix sec) — เทียบเวลาก่อนเรียก API แล้ว refresh ล่วงหน้าได้ |

> **ไม่จำเป็นต้อง decode** ก็ได้ — ใช้ `roles` / `is_department_head` จาก login response ตรงๆ ก็พอสำหรับ UI ทั่วไป

---

## 5. Token Lifecycle

| | ค่า default (dev) | prod |
|---|---|---|
| Access token TTL | `15m` | `720h` (ตาม env) |
| Refresh token TTL | `168h` (7 วัน) | `720h` |

**Flow แนะนำในแอป:**
```
login → เก็บ access_token + refresh_token + expires_at (secure storage)
   │
   ├─ ทุก request แนบ Authorization: Bearer <access_token>
   │
   ├─ ถ้า 401 (token หมด) → POST /auth/refresh ด้วย refresh_token
   │      ├─ สำเร็จ → เก็บคู่ใหม่ แล้ว retry request เดิม
   │      └─ ล้มเหลว → ล้าง token → เด้งหน้า login
   │
   └─ ถ้า must_change_password == true → บังคับหน้าเปลี่ยนรหัสก่อน
```

> เก็บ token ด้วย **`flutter_secure_storage`** (ไม่ใช่ SharedPreferences ธรรมดา)

---

## 6. Dart / Flutter Models

```dart
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;            // unix seconds
  final bool mustChangePassword;
  final List<String> roles;
  final bool isDepartmentHead;

  LoginResult({
    required this.accessToken, required this.refreshToken, required this.expiresAt,
    required this.mustChangePassword, required this.roles, required this.isDepartmentHead,
  });

  factory LoginResult.fromJson(Map<String, dynamic> j) => LoginResult(
        accessToken: j['access_token'],
        refreshToken: j['refresh_token'],
        expiresAt: j['expires_at'] ?? 0,
        mustChangePassword: j['must_change_password'] ?? false,
        roles: (j['roles'] as List? ?? []).map((e) => e.toString()).toList(),
        isDepartmentHead: j['is_department_head'] ?? false,
      );

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;
}

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  TokenPair({required this.accessToken, required this.refreshToken, required this.expiresAt});
  factory TokenPair.fromJson(Map<String, dynamic> j) => TokenPair(
        accessToken: j['access_token'], refreshToken: j['refresh_token'], expiresAt: j['expires_at'] ?? 0,
      );
}

class ApiException implements Exception {
  final int status;
  final String code;
  final String message;
  final int? retryAfterSeconds; // จาก header ตอน 429
  ApiException(this.status, this.code, this.message, {this.retryAfterSeconds});
  @override
  String toString() => '[$status] $code: $message';
}
```

---

## 7. Auth Service (Dio) + Token Storage

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  final _s = const FlutterSecureStorage();
  Future<void> save(String access, String refresh, int expiresAt) async {
    await _s.write(key: 'access_token', value: access);
    await _s.write(key: 'refresh_token', value: refresh);
    await _s.write(key: 'expires_at', value: '$expiresAt');
  }
  Future<String?> get accessToken => _s.read(key: 'access_token');
  Future<String?> get refreshToken => _s.read(key: 'refresh_token');
  Future<void> clear() async => _s.deleteAll();
}

class AuthApi {
  final Dio _dio;
  final TokenStore _store;
  // ตัวอย่าง dev: _dio.options = BaseOptions(
  //   baseUrl: 'http://localhost:8081/api/v1',
  //   headers: {'X-Tenant-Slug': 'nexton-demo'},  // dev only
  // );
  AuthApi(this._dio, this._store);

  /// login
  Future<LoginResult> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      final result = LoginResult.fromJson(res.data['data']);
      await _store.save(result.accessToken, result.refreshToken, result.expiresAt);
      return result;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// refresh (คืน token คู่ใหม่ + เก็บทับ)
  Future<TokenPair> refresh() async {
    final rt = await _store.refreshToken;
    if (rt == null) throw ApiException(401, 'NO_REFRESH_TOKEN', 'no refresh token');
    try {
      final res = await _dio.post('/auth/refresh', data: {'refresh_token': rt});
      final pair = TokenPair.fromJson(res.data['data']);
      await _store.save(pair.accessToken, pair.refreshToken, pair.expiresAt);
      return pair;
    } on DioException catch (e) {
      await _store.clear();      // refresh พัง → ต้อง login ใหม่
      throw _mapError(e);
    }
  }

  Future<void> logout() async => _store.clear();

  ApiException _mapError(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final err = e.response?.data is Map ? e.response!.data['error'] : null;
    final retry = int.tryParse(e.response?.headers.value('retry-after') ?? '');
    return ApiException(
      status,
      err?['code'] ?? 'NETWORK_ERROR',
      err?['message'] ?? e.message ?? 'unknown error',
      retryAfterSeconds: retry,
    );
  }
}
```

---

## 8. Dio Interceptor — แนบ token + auto-refresh อัตโนมัติ

```dart
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenStore store;
  final AuthApi auth;
  final void Function() onSessionExpired; // เด้งไปหน้า login
  bool _refreshing = false;

  AuthInterceptor(this.dio, this.store, this.auth, this.onSessionExpired);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // ไม่แนบ token ให้ endpoint login/refresh
    if (!options.path.contains('/auth/login') && !options.path.contains('/auth/refresh')) {
      final token = await store.accessToken;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final isAuthCall = err.requestOptions.path.contains('/auth/');
    if (is401 && !isAuthCall && !_refreshing) {
      _refreshing = true;
      try {
        await auth.refresh();                 // ขอ token ใหม่
        _refreshing = false;
        // retry request เดิมด้วย token ใหม่
        final token = await store.accessToken;
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $token';
        final clone = await dio.fetch(opts);
        return handler.resolve(clone);
      } catch (_) {
        _refreshing = false;
        onSessionExpired();                   // refresh พัง → login ใหม่
      }
    }
    handler.next(err);
  }
}

// การตั้งค่า:
// final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8081/api/v1',
//     headers: {'X-Tenant-Slug': 'nexton-demo'})); // dev only
// dio.interceptors.add(AuthInterceptor(dio, store, authApi, () => goToLogin()));
```

---

## 9. ตัวอย่างการใช้ในหน้า Login

```dart
Future<void> onLoginPressed(String email, String password) async {
  try {
    final result = await authApi.login(email, password);

    if (result.mustChangePassword) {
      goToChangePassword();
      return;
    }
    // เก็บ roles / is_department_head ไว้ตัดสิน UI
    appState.roles = result.roles;
    appState.isDepartmentHead = result.isDepartmentHead;
    goToHome();

  } on ApiException catch (e) {
    switch (e.code) {
      case 'INVALID_CREDENTIALS':
        showError('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
        break;
      case 'USER_INACTIVE':
        showError('บัญชีถูกปิดใช้งาน กรุณาติดต่อ HR');
        break;
      case 'TOO_MANY_LOGIN_ATTEMPTS':
        showError('พยายามเข้าสู่ระบบบ่อยเกินไป ลองใหม่ใน ${e.retryAfterSeconds ?? 60} วินาที');
        break;
      case 'VALIDATION_ERROR':
        showError('กรุณากรอกอีเมลและรหัสผ่านให้ถูกต้อง (รหัสอย่างน้อย 8 ตัว)');
        break;
      default:
        showError(e.message);
    }
  }
}
```

---

## 10. Checklist สำหรับ Dev

- [ ] Dev: ตั้ง base URL = `http://localhost:8081/api/v1` + header `X-Tenant-Slug`
- [ ] เก็บ token ด้วย `flutter_secure_storage`
- [ ] ใส่ `AuthInterceptor` (แนบ Bearer + auto-refresh 401)
- [ ] เก็บ `refresh_token` **ใหม่ทุกครั้ง** ที่ refresh (rotation)
- [ ] เช็ค `must_change_password` หลัง login
- [ ] ใช้ `roles` / `is_department_head` ตัดสินการโชว์เมนู (เช่น เมนูอนุมัติ ให้หัวหน้าแผนก/HR)
- [ ] logout = ล้าง token ใน secure storage
```

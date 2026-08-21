# Authentication

> **Status:** ✅ Connected · 4 endpoints · Source: `src/store/auth.ts`, `src/services/api.ts`, `src/features/auth/` · Backend: `internal/server/server.go` (`mountAuthRoutes`, ~L253), `internal/platform/auth/*`

Authentication is **not** react-query backed. It lives in the Zustand store `useAuthStore` (`@/store/auth`), which owns the session state machine, calls the four endpoints below through the axios singleton (`@/services/api`), and persists identity to SecureStore. The two screens under `src/features/auth/` (`LoginScreen`, `ChangePasswordScreen`) do client-side validation only and delegate every network call to the store.

On the backend these four routes are a dedicated group at `/api/v1/auth`, registered by `mountAuthRoutes` in `internal/server/server.go`. `/login` and `/refresh` are **public** (no JWT middleware on the route); `/me` and `/change-password` each attach `JWTMiddlewareForService(authService, JWTAudienceAdmin, JWTAudienceTenant)` — so both accept **either** an admin-audience or a tenant-audience access token. There is **no** `/auth/logout` and **no** `/auth/forgot-password` in the group (verified against the route registration).

*All JSON values below are illustrative (Lao HR context); every key is a real json tag from a backend struct or a real app TS field. Fields the backend returns but the app never reads are marked **backend-only**.*

---

## Backend reconciliation notes

Concrete places where the live backend differs from what this doc previously claimed (all verified against `internal/server/server.go` + `internal/platform/auth/*` + `pkg/httputil/response.go`):

- **`X-Tenant-Slug` is a DEV-ONLY override, not the production tenant mechanism.** `internal/platform/tenant/subdomain.go` only reads the `X-Tenant-Slug` header when `cfg.App.Env == "development"` (`devTenantOverrideHeader`). In production the tenant is the **leftmost label of the Host header** (`extractSlug`). The app sends `X-Tenant-Slug` from `EXPO_PUBLIC_TENANT_SLUG`, but that header is ignored by a production server. The previous doc implied `X-Tenant-Slug` was the normal tenant carrier — it is not.
- **`api.nexton.work` is a RESERVED host that bypasses tenant resolution.** `subdomain.go` treats `api` (and `admin`) as reserved: no tenant ref is set, so `GetResolvedTenantID(c)` returns `""`. That has two consequences on `/auth/login` (see below): under `TenantStrictMode` the login is **rejected 400 `SUBDOMAIN_REQUIRED`**; otherwise the login mints an **admin-audience** token (not a tenant-audience one). The app's base URL is exactly this reserved host — confirm the production build points at a tenant subdomain before multi-tenant rollout.
- **Login response also carries `expires_at` (backend-only).** `auth.LoginResponse` (service.go) is `{ access_token, refresh_token, expires_at, must_change_password }`. The app's `LoginPayload` reads only three of those and drops `expires_at` (a Unix-seconds access-token expiry). Not an error — just an unused field.
- **Refresh response also carries `expires_at` (backend-only).** `auth.TokenPair` (claims.go) is `{ access_token, refresh_token, expires_at }`. The app's `RefreshPayload` ignores `expires_at`.
- **`/auth/me` does NOT return `profile_photo_url`, `department_name`, or `position_title`.** The handler returns a fixed map of exactly `{ id, user_id, tenant_id, email, first_name, last_name, roles, modules, permissions, employee_id }` (server.go ~L406). The app's `User` type declares `profile_photo_url?`, `department_name?`, `position_title?`, but `/auth/me` never populates them — they are always `undefined` from this call. Those richer fields live on the Core HR employee record (`GET /core_hr/employees/:id`), not on the auth profile.
- **`/auth/me` returns a duplicate `user_id` (backend-only).** The map carries both `id` and `user_id` set to the same `claims.UserID`; the app reads only `id`.
- **`/auth/me` `roles`/`permissions`/`modules` come from the JWT claims, not a fresh DB read.** They are baked into the access token at login/refresh (`getUserAccess` → `user_roles → role_permissions`; `getUserModules` → subscription). A role/permission/module change is **not** reflected by `/auth/me` until the next `/auth/refresh` or re-login. Only `first_name`, `last_name`, and `employee_id` are re-queried live from the DB per `/me` call.
- **`/auth/me` `employee_id` is nullable and back-filled.** It is a Go `*string` (serialized as `null` when the user row has no `employee_id`). The handler additionally resolves it via `employees.work_email == claims.email` in the tenant DB when the users-table column is empty. This confirms the backend's own mobile endpoint reference (`docs/api/mobile-app-endpoints.md` §2, §7) that `id` (= `user_id`) ≠ `employee_id` — the app maps only `id`, so any employee-scoped call keyed on `user.id` uses the wrong identifier.
- **The backend confirms plural `roles` / `permissions`** — `UserClaims` (claims.go) and the `/auth/me` map both use plural arrays; there is no singular `role` field on the wire. (The backend's own `docs/api/auth.md` is **stale** — it shows singular `role`, its login-response example omits `must_change_password`, and its `/me` example omits `user_id`, `permissions`, and `employee_id`. Note its `/me` example *does* still include `first_name`/`last_name`, so those are not among the omissions. The newer `docs/api/mobile-app-endpoints.md` §2 already lists the correct plural `roles[]`/`permissions[]` + `user_id` + `employee_id`. Trust the code, not the stale `auth.md`.)
- **Login is throttled (429).** `POST /auth/login` runs a Redis sliding-window limiter keyed by client IP before it even reads the body: **5 failed attempts per 15-minute window**, and the 6th is rejected **429 `TOO_MANY_LOGIN_ATTEMPTS`** with a `Retry-After` header (`internal/platform/auth/throttle.go`). Only `INVALID_CREDENTIALS` bumps the counter; a successful login resets it. The app's `isAuthFailure` covers 400/401/403/422 but **not 429**, so a throttled response is classified `network` (the app keeps the typed password) and its message surfaces via `parseErrorMessage`.
- **Wrong current password on change-password → 400 `PASSWORD_MISMATCH`** (not 401/403). The app's `isAuthFailure` includes 400, so this is correctly treated as an auth failure and shown under the current-password field.
- **`new_password` `strongpassword` rule == "min 8 chars".** Despite the name, `validateStrongPassword` (`pkg/validator/validator.go`) only enforces `len >= 8` — no complexity requirement today (its failure message is literally "Password must be at least 8 characters."). This matches the app's client-side `MIN_PASSWORD_LENGTH = 8`, so a password that passes the client check will not be rejected by the backend length rule. (The backend's own `docs/api/mobile-app-endpoints.md` §2 mislabels this as "length + complexity" — also stale.)
- **Login/refresh also set an HttpOnly `nexton_access_token` cookie (backend-only).** `writeAccessTokenCookie` mirrors the access token into a cookie for SSR/edge frontends. The mobile app ignores cookies and uses the JSON tokens + SecureStore.
- **Standard envelope has no `error: null` / `meta` on plain success.** `APIResponse` uses `omitempty` on `data`, `error`, and `meta` (`pkg/httputil/response.go`), so a success body is just `{ "success": true, "data": … }` and an error body is `{ "success": false, "error": { code, message, details? } }`. A 422 additionally carries top-level `message` and `errors: { field: [msg] }` (Laravel-style). (The backend's own `docs/api/mobile-app-endpoints.md` §1 shows `"error": null` + a `meta` block on the success example — that too is stale; `omitempty` drops both keys.)

---

## Auth state machine (context)

`useAuthStore.status: AuthStatus` (`src/store/auth.ts`) drives which navigator the root `_layout.tsx` mounts:

| Status | Meaning | How it's reached |
|---|---|---|
| `bootstrapping` | Initial cold-start state; splash held | Store default; resolved by `bootstrap()` |
| `unauthenticated` | No valid session → `(auth)` login stack | No token at bootstrap, or any teardown (`logout`/`forceLogout`) |
| `authenticated` | Full session → `(tabs)` app | `/auth/me` succeeds after login/bootstrap; `must_change_password === false` |
| `must_change_password` | Logged in but forced to `(auth)/change-password` | `POST /auth/login` returns `must_change_password: true` |

Store actions: `bootstrap`, `login`, `fetchMe`, `changePassword`, `clearLoginError`, `logout`, `forceLogout`. There is **no `persist` middleware** — the source of truth is SecureStore + the network. A perf-only copy of the user is written to the SecureStore key `cached_user` (via `setCachedUser`) for optimistic cold-start render.

Two error classifiers shared across the store (`src/store/auth.ts`):

- `parseErrorMessage(err)` → `'Network slow, please retry'` (Axios `ECONNABORTED`), `'No internet connection'` (no response + `Network Error`), else the first server message string it can find, else `'Something went wrong'`.
- `isAuthFailure(err)` → `true` for HTTP **400 / 401 / 403 / 422** (credential failures vs. transport failures). **Note:** the backend's login throttle returns **429**, which this classifier treats as `network`, not `auth`.

---

## POST /auth/login

**Purpose:** Exchange email + password for an access/refresh token pair, then load the profile. Called by `useAuthStore.login(rawEmail, password)`. Backend handler: `mountAuthRoutes` login closure (`server.go` ~L254) → `auth.Service.Login` (`service.go` L158).

**Headers**

```http
POST /auth/login HTTP/1.1
Content-Type: application/json
X-Tenant-Slug: nexton-vientiane   # app default (EXPO_PUBLIC_TENANT_SLUG) — DEV-ONLY on the backend; ignored in prod
```

No bearer is required (the route has no JWT middleware). Login is **not** exempted from the app's request interceptor, so if a stale cached access token happens to exist it would be attached as `Authorization: Bearer …`; the backend `/login` handler ignores it. On a normal fresh login none exists.

> **Tenant / audience selection (backend).** The handler reads `tenant.GetResolvedTenantID(c)`:
> - **Resolved tenant** (request hit `<company>.nexton.work`, or dev `X-Tenant-Slug`) → user lookup is scoped to that tenant and a **tenant-audience** token is minted.
> - **No resolved tenant** (reserved host `api.`/`admin.`, or bare host) → under `TenantStrictMode` the request is rejected **400 `SUBDOMAIN_REQUIRED`**; otherwise the lookup falls back to email-only and an **admin-audience** token is minted.

**Request** — the store trims + lowercases the email before sending (`rawEmail.trim().toLowerCase()`). Backend validation: `email` is `required,email`; `password` is `required,min=8`.

```json
{
  "email": "somphone.vilaysone@nexton.la",
  "password": "••••••••"
}
```

**Response** — HTTP **200**, envelope unwrapped by `unwrap<LoginPayload>(res.data)` (tolerates a flat body too). The backend struct is `auth.LoginResponse`:

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9…",
    "refresh_token": "def50200a1b2c3d4…",
    "expires_at": 1773504662,
    "must_change_password": false
  }
}
```

`expires_at` (Unix seconds, access-token expiry) is **backend-only** — the app does not read it.

```go
// internal/platform/auth/service.go
type LoginResponse struct {
	AccessToken        string `json:"access_token"`
	RefreshToken       string `json:"refresh_token"`
	ExpiresAt          int64  `json:"expires_at"`          // backend-only; app ignores
	MustChangePassword bool   `json:"must_change_password"`
}
```

**Client type** (`src/store/auth.ts`, local `interface LoginPayload`):

```ts
interface LoginPayload {
  access_token: string;
  refresh_token: string;
  must_change_password: boolean;
  // NOTE: backend also returns `expires_at: number` — not modelled here.
}
```

**Hook & caching / flow** (store action, no react-query):

1. `unwrap` the payload; if `access_token` or `refresh_token` is not a `string`, throw `Error('Login response missing tokens')`.
2. `await Promise.all([setAccessToken, setRefreshToken])` — both tokens are written; a local `tokensWritten` flag flips to `true`.
3. `await fetchMe()` (see below) — loads and caches the `User`.
4. `set({ status: must_change_password ? 'must_change_password' : 'authenticated', isSubmitting: false })`.

**Errors** (backend codes → app handling):

| Status | `error.code` | When (backend) |
|---|---|---|
| 400 | `INVALID_REQUEST` | Malformed JSON body |
| 422 | `VALIDATION_ERROR` | Missing/invalid `email`, or `password` shorter than 8 |
| 400 | `SUBDOMAIN_REQUIRED` | `TenantStrictMode` on and no tenant resolved from host |
| 401 | `INVALID_CREDENTIALS` | Wrong email/password (also increments the login throttle) |
| 403 | `USER_INACTIVE` | Account `is_active = false` |
| 429 | `TOO_MANY_LOGIN_ATTEMPTS` | ≥5 failed attempts from this IP in 15 min; carries `Retry-After` |
| 500 | `INTERNAL_ERROR` | Module/DB error minting the token |

On any thrown error the app:

- If `tokensWritten` was already `true` (the failure was in the post-token-write `/auth/me` step), `clearTokens()` runs so a half-completed login can't auto-authenticate on the next bootstrap.
- Fires a Warning haptic; sets `loginError = parseErrorMessage(err)` and `loginErrorKind = isAuthFailure(err) ? 'auth' : 'network'`.
- `LoginScreen` reacts to a **new** `loginError` transition: fires a Warning haptic and, only when `loginErrorKind === 'auth'`, clears the password field (network blips — **and 429 throttles** — preserve it). `canSubmit` requires non-empty email + password and `!isSubmitting`.

**Backend quirks:** The store treats the login as atomic — writing tokens but failing `/auth/me` is rolled back via `clearTokens()`, so there is no "authenticated with no profile" state. `must_change_password` is read **only** from this response, never from `/auth/me`. Backend side effects on success: `users.last_login_at = NOW()`, a Redis session record is created when a session store is wired (so an admin can revoke the session), and an HttpOnly `nexton_access_token` cookie is set (ignored by the app).

---

## GET /auth/me

**Purpose:** Load / revalidate the current user. Called by `useAuthStore.fetchMe(signal?)` from three places: `bootstrap()`, `login()` (after token write), and foreground revalidation (`useAuthRevalidateOnForeground` in `src/app/_layout.tsx`, which only fires when `status === 'authenticated'`). The path constant `ME_PATH = '/auth/me'` in `src/services/api.ts` is also used by the 401 interceptor. Backend handler: `server.go` ~L368, gated by `JWTMiddlewareForService(admin, tenant)`.

**Headers**

```http
GET /auth/me HTTP/1.1
Content-Type: application/json
Authorization: Bearer <access_token>   # attached by the request interceptor; must be an ACCESS token
X-Tenant-Slug: nexton-vientiane        # dev-only override; ignored in prod
```

The middleware requires a Bearer access token (`claims.Subject == "access"`) whose `aud` is admin **or** tenant, and — when the token carries a `sid` and a Redis session store is wired — that the session has not been revoked (else `401 SESSION_EXPIRED`).

**Request:** no body. `bootstrap()` passes an `AbortSignal` from a 5s `AbortController` (`BOOTSTRAP_TIMEOUT_MS = 5000`) **only** on the no-cached-user path; the optimistic (cached-user present) path and `login()`/foreground calls pass no signal.

**Response** — HTTP **200**, unwrapped by `unwrap<User>(res.data)`. The backend returns a fixed map (there is no `/me` response struct — it's assembled inline):

```json
{
  "success": true,
  "data": {
    "id": "cce14a0e-baef-47b7-9338-8237b9e03739",
    "user_id": "cce14a0e-baef-47b7-9338-8237b9e03739",
    "tenant_id": "cbc6553a-ac89-47f2-93ee-01d1c7167cfe",
    "email": "somphone.vilaysone@nexton.la",
    "first_name": "Somphone",
    "last_name": "Vilaysone",
    "roles": ["employee", "team_lead"],
    "modules": ["core_hr", "payroll", "recruitment"],
    "permissions": ["corehr:employee:read", "corehr:leaveRequest:create"],
    "employee_id": "b3f1…-employees-uuid"
  }
}
```

- `user_id` is a **backend-only** duplicate of `id`; the app reads only `id`.
- `roles`, `permissions`, `modules` are lifted from the **JWT claims** (baked at login/refresh), not re-queried per call.
- `first_name`, `last_name`, `employee_id` **are** re-queried live from the DB. `employee_id` is nullable (`null` when the user row has none and the `work_email` fallback finds no employee).
- **Not present:** `profile_photo_url`, `department_name`, `position_title` — the app's `User` type declares them but `/auth/me` never sends them.

**Client type** (`src/store/auth.ts`, exported `interface User`):

```ts
export interface User {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  // The live API returns plural `roles: string[]` and `permissions: string[]`,
  // NOT the singular `role: string` originally documented.
  roles: string[];
  permissions: string[];
  tenant_id: string;
  modules: string[];
  employee_id?: string | null;
  // ⚠ Backend `/auth/me` does NOT return the three fields below — they are always
  // `undefined` from this call. They live on the Core HR employee record instead.
  profile_photo_url?: string;
  department_name?: string;
  position_title?: string;
}
```

> **Plural `roles` / `permissions` arrays confirmed against the backend** (`UserClaims` + the `/auth/me` map). There is no singular `role` field. The backend also returns `user_id` (ignored by the app).

**Caching:** on success `set({ user })` and, fire-and-forget, `setCachedUser(user)` serializes the profile to the SecureStore key `cached_user` for the next cold-start's optimistic render. A cache miss next launch is harmless — bootstrap falls back to a blocking fetch.

**Errors:**

- If the unwrapped body has no string `id`, `fetchMe` throws `Error('Profile response missing id')`.
- Backend auth failures surface as `401` with `error.code` one of `MISSING_TOKEN`, `INVALID_TOKEN_FORMAT`, `INVALID_TOKEN`, `INVALID_TOKEN_TYPE`, `SESSION_EXPIRED`, or `UNAUTHORIZED`.
- A `401` is handled by the response interceptor: one refresh + retry cycle. A **second** `401` on `/auth/me` specifically triggers `forceLogout()` (this is the canonical "is my session valid" check); a second 401 on any other path propagates as a query error instead of killing the session (see `conventions.md` for the full mutex/retry rules).
- In `bootstrap()`, a non-auth failure (e.g. offline) does **not** evict a user holding valid tokens — the optimistic cached identity is kept and revalidation retries on next resume. Only `isAuthFailure(err)` triggers `forceLogout()`.

---

## POST /auth/refresh

**Purpose:** Rotate an expired access token using the stored refresh token. Called by `doRefresh()` inside the response interceptor's refresh mutex (`src/services/api.ts`). Not called directly by any screen or store action. Backend handler: `server.go` ~L330 → `auth.Service.RefreshToken` (`service.go` L288). The route is **public** (no JWT middleware); the refresh token itself is the credential.

**Headers**

```http
POST /auth/refresh HTTP/1.1
Content-Type: application/json
X-Tenant-Slug: nexton-vientiane   # dev-only override; ignored in prod
```

> **This is the ONLY request the app does not give a bearer.** The request interceptor detects `url.endsWith('/auth/refresh')` and returns the config before attaching `Authorization`. `X-Tenant-Slug` still rides because it is an axios **default** header, not injected by the interceptor. (The backend route wouldn't require the bearer anyway.)

**Request** — the refresh token is read from SecureStore (`getRefreshToken()`); if absent, `doRefresh` clears tokens and returns `null` without calling the endpoint. Backend validation: `refresh_token` is `required`.

```json
{ "refresh_token": "def50200a1b2c3d4…" }
```

**Response** — HTTP **200**, parsed by `unwrapRefresh(res.data)`, which tolerates both `{ data: {…} }` and a flat body and requires both token fields to be strings. Backend struct is `auth.TokenPair`:

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1Ni…(rotated)…",
    "refresh_token": "def50200e5f6a7b8…(rotated)…",
    "expires_at": 1773505562
  }
}
```

`expires_at` is **backend-only** — the app ignores it.

```go
// internal/platform/auth/claims.go
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresAt    int64  `json:"expires_at"`   // backend-only; app ignores
}
```

**Client type** (`src/services/api.ts`, local `interface RefreshPayload`):

```ts
interface RefreshPayload {
  access_token: string;
  refresh_token: string;
  // NOTE: backend also returns `expires_at: number` — not modelled here.
}
```

**Hook & caching:** on success both rotated tokens are persisted (`setAccessToken`, `setRefreshToken`) and the new access token is returned to retry the original request. Concurrency is guarded by a **module-scope refresh mutex** (`refreshPromise`) — parallel 401s share one in-flight refresh. Full details in `conventions.md`.

**Errors:** the backend returns `401 INVALID_TOKEN` (parse failure, wrong subject, expired, unknown user) or `403 USER_INACTIVE`; malformed/empty bodies give `400 INVALID_REQUEST` / `422 VALIDATION_ERROR`. Any thrown error, or an unexpected shape from `unwrapRefresh`, results in `clearTokens()` + `null` return, which makes the interceptor call `forceLogout()`. If the refresh endpoint itself returns `401`, the interceptor short-circuits straight to `forceLogout()` (no retry loop).

> **Backend quirk — refresh tokens die on password change.** `RefreshToken` rejects any refresh token whose `iat` predates the user's `password_set_at` (`service.go` L327). Because `PUT /auth/change-password` (and admin password reset) stamp `password_set_at = NOW()`, every outstanding refresh token is invalidated the moment a password changes — the next refresh returns `401 INVALID_TOKEN` and the app force-logs-out. A fresh access + refresh pair is only minted by the change-password call's own follow-up, not by this endpoint.

---

## PUT /auth/change-password

**Purpose:** Set a new password (used for the forced first-login change and voluntary changes). Called by `useAuthStore.changePassword(currentPassword, newPassword)`; the UI is `ChangePasswordScreen`. Backend handler: `server.go` ~L420 (JWT-gated, admin or tenant aud) → `auth.Service.ChangePassword` (`service.go` L771).

**Headers**

```http
PUT /auth/change-password HTTP/1.1
Content-Type: application/json
Authorization: Bearer <access_token>
X-Tenant-Slug: nexton-vientiane   # dev-only override; ignored in prod
```

**Request** — note snake_case keys. Backend struct `auth.ChangePasswordRequest`: `current_password` is `required`; `new_password` is `required,strongpassword` (= min 8 chars, no complexity rule today).

```json
{
  "current_password": "••••••••",
  "new_password": "••••••••••••"
}
```

**Response** — HTTP **200** with a message body; the store ignores it (any 2xx resolves):

```json
{ "success": true, "data": { "message": "Password changed successfully" } }
```

On success the store sets `status: 'authenticated'` and `changePassword` returns `null`. Backend side effects: `password_hash` updated, `must_change_password = false`, `password_set_at = NOW()` (which invalidates all outstanding refresh tokens — see the refresh quirk above).

**Hook & caching / flow** (store action):

- Success → `set({ status: 'authenticated' })`, return `null`. From `must_change_password`, this releases the user into the `(tabs)` app.
- Failure → the error is **not thrown**; `changePassword` returns `parseErrorMessage(err)` (a string) for the screen to display.

**Errors** (backend codes):

| Status | `error.code` | When |
|---|---|---|
| 400 | `INVALID_REQUEST` | Malformed JSON body |
| 422 | `VALIDATION_ERROR` | Missing `current_password`/`new_password`, or `new_password` shorter than 8 |
| 400 | `PASSWORD_MISMATCH` | `current_password` is incorrect |
| 404 | `NOT_FOUND` | User row not found for the token's `user_id` (rare) |
| 401 | (middleware) | Missing/invalid access token |
| 500 | `INTERNAL_ERROR` | Hashing/DB error |

Wrong current password is **400 `PASSWORD_MISMATCH`** (not 401/403); since `isAuthFailure` includes 400 this is still treated as an auth-class error by the app.

**Client-side validation** — `ChangePasswordScreen`'s module-level `validate(current, next, confirm)` runs before the call, short-circuiting in this exact order (`MIN_PASSWORD_LENGTH = 8`, which matches the backend's `strongpassword` length check):

| Order | Condition | Field / message key |
|---|---|---|
| 1 | `current.length === 0` | `current` → `auth.enterCurrentPassword` |
| 2 | `next.length < 8` | `next` → `auth.passwordMinLength` |
| 3 | `next === current` | `next` → `auth.newMustDiffer` |
| 4 | `confirm !== next` | `confirm` → `auth.passwordsDoNotMatch` |

`canSubmit` requires all three fields non-empty and `!isSubmitting`. A server-side error is surfaced under the **current-password** field (change-password failures are nearly always "current password wrong"). The screen also renders a "Sign out" action that calls `useAuthStore.logout()`.

> Note: the client rejects `next === current` (rule 3), but the backend does **not** enforce new-≠-old — it would accept re-setting the same password. The app's extra guard is stricter than the server.

---

## No `POST /auth/logout`

There is **no logout endpoint** (verified against `mountAuthRoutes` — only `/login`, `/refresh`, `/me`, `/change-password` are registered). Both `logout()` (user-initiated) and `forceLogout()` (interceptor-forced) share one implementation and clear session state locally:

- `clearTokens()` — deletes `access_token`, `refresh_token`, **and** `cached_user` from SecureStore (and nulls the in-memory access-token cache).
- `clearQueryCache()` — lazily imports `@/lib/queryClient` and calls `queryClient.clear()` so the next user on a shared device can't briefly see the previous user's data.
- Resets store state to `status: 'unauthenticated'`, `user: null`, and clears `loginError` / `loginErrorKind` / `isSubmitting`.

The refresh token is left to expire server-side on its own. (`logout()` simply delegates to `forceLogout()`.) A server-side session record, if one was created at login, is not deleted by the client — it lapses at the access TTL or when an admin revokes it.

## No `/auth/forgot-password`

Forgot-password has no endpoint (not in the auth group). `LoginScreen.onForgotPassword` opens a `mailto:` composer via `Linking.openURL('mailto:support@nexton.work?subject=Password%20reset')`; if no mail app is available it shows a toast (`auth.noMailApp`) instead.

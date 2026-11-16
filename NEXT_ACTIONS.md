# Next actions

Progress record for the 60 work items (issues #2 to #61) and the bugs reported after them. One issue, one
branch, one PR; work order decides what lands first. Update the row when its status changes.

Statuses: `NOT STARTED`, `IN PROGRESS`, `BLOCKED`, `IMPLEMENTED`, `PR OPEN`, `MERGED`.

Last updated: 2026-11-16.

## Baseline

| Step | Branch | Commit | PR | Tests | Status |
|---|---|---|---|---|---|
| Bring `clock-in-out-location` into `main` (merge commit) | `clock-in-out-location` | `197ff6c` | none: pushed to `main` directly on the owner's say, 2026-11-16 | 369 passed on the merged result | MERGED |
| Fix nine off-site tests left stale by `b64a77a` ("scan" became "clock-in") | `fix/offsite-test-strings` | `ae02169` | none: pushed to `main` directly on the owner's say, 2026-11-16 | `flutter test`: 369 passed, 0 failed | MERGED |

## Next

1. #13: open the PR from `13-leave-tests` and review it. #14 is next.
   What the #13 tests recorded about today's leave behaviour, for #14 to #19 to look at (none changed in #13):
   - the request body sends `attachments` as one object, not a list (#73's text says leave takes a list);
   - an unknown request status reads as pending, so the request looks editable and cancellable;
   - a decision that fails for a reason other than `STEP_CHANGED` does not reload the lists;
   - the decided list leaves out cancelled requests;
   - the approval timeline never shows the approver's name;
   - history and approvals fetch a single page of 100.
   Open points for the owner on #12: the profile page's green "Active" pill and the home header's online dot are
   hard-coded and still show beside "not linked to an employee"; the header allows the message two lines, which may
   cut the longer texts on a narrow phone (check on a device).
   For #12 to pick up: the profile page reads the same month summary and now shows "-" for its three stats when
   the load fails, with no message and no Retry of its own.
   To check on a phone for #11: the home card's seven tiles (two rows of four) on a narrow screen; the labels are
   in a tight column.
   Check on a phone before relying on #10: the record keys (`shift_detail`, `clock_in_method`,
   `clock_in_location_name`, `work_hours`) come from the issue's reading of the backend and could not be verified
   here. The same model feeds the home card.
   Owner decision on #9, 2026-11-16: `lib/features/auth/auth-login.md` and
   `lib/features/attendance/attendance-offsite-requests.md` stay; only the clock-in/out guide copy is deleted.
   Follow-up worth its own issue: about 77 code comments in the attendance feature cite section numbers (`§5.2`,
   `§7 rule 6`, …) of the deleted guide and now point at nothing.
   Owner decision on #8, 2026-11-16: leave it as merged. The "too early" wording stays as it was on `main`; refusals
   such as "session already started" show the app's text without the session or next start time; the off-site form
   still shows the server's English first. Still open: a Lao speaker should check `ruleClockOutBeforeClockIn`.
   Owner decision on #7, 2026-11-16: leave the night-shift rule as the issue has it. A night shift left open by a
   forgotten clock-out stays "current" all the next day; no cut-off is added.
   Still to try by hand for #4 and #5: on a phone against `nexton-demo` (the made-up host check; airplane mode and
   reopen; a password change that stays signed in).
2. Still to try by hand for #2: a release APK on a phone signs in with a `nexton-demo` login, and a plain debug run
   shows `nexton-demo.nexton.work` in the debug log.
3. Still to do by hand for #3: the lead makes the upload key and builds a release bundle with it; a phone install; the
   iOS simulator build.
4. #72 and #73 have a known root cause but no work order yet; the owner decides where they go.

Stale docs found while reviewing #2, outside its scope: `lib/features/auth/auth-login.md:11`,
`lib/features/attendance/attendance-offsite-requests.md:15` and `lib/features/home/attendance-clock-in-out-flutter.md:6`
still give `api.nexton.work` as the base URL, and `lib/features/auth/auth.md` still describes `X-Tenant-Slug:
nexton-vientiane` as sent by default.

## Blocked on the backend

Not to be built until the backend team confirms: #21 and #23 (payslip month), #35 (OT hours), #55 (unread
count), #56 (sign-out ends the session).

## Work items

| Order | Issue | Title | Branch | Commit | PR | Tests | Status |
|---|---|---|---|---|---|---|---|
| 1 | #2 | app: a store build reaches the network and signs in at app.nexton.work | `2-store-build-hosts` | `7af1adb` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 375 passed, 0 failed; debug and release APK build; release manifest has `INTERNET`; phone sign-in pending | MERGED |
| 2 | #3 | app: final app id next.on.hr.com and a real release key | `3-release-signing` | `e970e49` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 369 passed, 0 failed; debug APK builds; release APK without `key.properties` is debug-signed; release bundle with a throwaway key is signed by that key; the real upload key, a phone install and the iOS simulator build are pending | MERGED |
| 3 | #4 | errors: Lao text for sign-in, company, session and module codes (shared table) | `4-error-codes-lao` | `e83a896` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 418 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 4 | #5 | sign-in: no surprise sign-outs on weak signal, a server restart or after a password change | `5-no-surprise-sign-outs` | `42b4c2b` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 442 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 5 | #6 | sign-in: show how long to wait after too many tries, and send the email as typed | `6-login-wait-and-email` | `5861257` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 456 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 6 | #7 | attendance: home card and history read the right month | `7-attendance-right-day` | `4fdfd29` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 483 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 7 | #8 | attendance: a refused punch says why in Lao, with no useless Retry | `8-refused-punch-lao` | `1c4f9bd` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 514 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 8 | #9 | attendance: the card shows the weekday's own shift times, and GPS only | `9-weekday-shift-times-gps-only` | `df5a998` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 536 passed, 0 failed; debug APK builds; the issue grep finds nothing; not yet tried on a phone against `nexton-demo` | MERGED |
| 9 | #10 | attendance: history rows show the real shift, method, place and day status | `10-history-real-fields` | `a7012fb` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 552 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 10 | #11 | attendance: the month summary shows the server's numbers, and "not linked to an employee" | `11-month-summary-server-numbers` | `ce8b5cc` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 567 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 11 | #12 | profile: no made-up numbers, and a clear message when the profile cannot load | `12-profile-load-errors` | `84f308e` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 599 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 12 | #13 | leave: tests for what works today, and drop the old guide copy | `13-leave-tests` | `debd358` | to open | analyze: 1 warning already on `main`; `flutter test`: 726 passed, 0 failed; debug APK builds; tests only, no app behaviour changed | IMPLEMENTED |
| 13 | #14 | leave: the form offers only active types and checks the balance the server will charge | | | | | NOT STARTED |
| 14 | #15 | leave: company days off are skipped, not charged | | | | | NOT STARTED |
| 15 | #16 | leave: refusals show Lao text and the screen reloads | | | | | NOT STARTED |
| 16 | #17 | leave: the request page opens by id, stays fresh, and shows a cancelled request plainly | | | | | NOT STARTED |
| 17 | #18 | lists: load more as you scroll (leave history first) | | | | | NOT STARTED |
| 18 | #19 | approvals: leave lists keep what I decided, hide buttons on my own request, and load more | | | | | NOT STARTED |
| 19 | #20 | payslip: read real payslips from the server (data layer) | | | | | NOT STARTED |
| 20 | #21 | payslip: the salary list shows real payslips, paid and failed | | | | | BLOCKED: backend, payslip month |
| 21 | #22 | payslip: name, group and caption every payslip line | | | | | NOT STARTED |
| 22 | #23 | payslip: the payslip page opens by id and shows the real lines | | | | | BLOCKED: backend, payslip month |
| 23 | #24 | payslip: tap the OT line to see what each OT paid | | | | | NOT STARTED |
| 24 | #25 | payslip: open the PDF in the App and share it | | | | | NOT STARTED |
| 25 | #26 | payslip: the summary card shows the latest payslip | | | | | NOT STARTED |
| 26 | #27 | overtime: OT types and JSON reading (no screen yet) | | | | | NOT STARTED |
| 27 | #28 | overtime: OT calls, error codes and Lao text | | | | | NOT STARTED |
| 28 | #29 | overtime: my OT list, on its own tile | | | | | NOT STARTED |
| 29 | #30 | overtime: an OT request page that opens by id | | | | | NOT STARTED |
| 30 | #31 | overtime: ask for OT | | | | | NOT STARTED |
| 31 | #32 | overtime: edit or cancel my OT while it waits | | | | | NOT STARTED |
| 32 | #33 | overtime: see HR's OT posts for my department and join one | | | | | NOT STARTED |
| 33 | #34 | overtime: the clock button knows about an open OT session | | | | | NOT STARTED |
| 34 | #35 | attendance: show OT hours on the summary and history | | | | | BLOCKED: backend, OT hours |
| 35 | #36 | approvals: one Approvals place, only for department heads and HR (leave moves in) | | | | | NOT STARTED |
| 36 | #37 | approvals: open a leave request to see days, files, steps and notes before deciding | | | | | NOT STARTED |
| 37 | #38 | photos: take a photo with the camera and upload it (shared) | | | | | NOT STARTED |
| 38 | #39 | leave: attach a photo when the type needs a file, and open attached files | | | | | NOT STARTED |
| 39 | #40 | attendance: after a clock-in or clock-out refused for the area, scan outside the area with a photo and reason | | | | | NOT STARTED |
| 40 | #41 | attendance: the card shows a waiting off-site check-in, and clock-out goes as off-site too | | | | | NOT STARTED |
| 41 | #42 | attendance: my off-site requests — list, detail, cancel | | | | | NOT STARTED |
| 42 | #43 | attendance: "forgot to scan" — rules and sending (no screen) | | | | | NOT STARTED |
| 43 | #44 | attendance: "forgot to scan" form, from a history day or the menu | | | | | NOT STARTED |
| 44 | #45 | attendance: my "forgot to scan" requests — list, detail, cancel | | | | | NOT STARTED |
| 45 | #46 | approvals: off-site scans for heads and HR | | | | | NOT STARTED |
| 46 | #47 | approvals: "forgot to scan" requests for heads and HR | | | | | NOT STARTED |
| 47 | #48 | approvals: OT waiting and decided lists for heads | | | | | NOT STARTED |
| 48 | #49 | approvals: approve or reject OT, and cancel an approved OT before it starts | | | | | NOT STARTED |
| 49 | #50 | approvals: my team's leave and "forgot to scan" history (read-only) | | | | | NOT STARTED |
| 50 | #51 | push: Firebase set up for nexton.hr on Android and iOS | | | | | NOT STARTED |
| 51 | #52 | push: register this phone after sign-in, remove it before sign-out | | | | | NOT STARTED |
| 52 | #53 | push: tapping a push opens the right screen | | | | | NOT STARTED |
| 53 | #54 | notifications: the bell shows recent pushes | | | | | NOT STARTED |
| 54 | #55 | notifications: unread dots and a count on the bell | | | | | BLOCKED: backend, unread count |
| 55 | #56 | sign-in: signing out ends the session on the server | | | | | BLOCKED: backend, sign-out ends the session |
| 56 | #57 | app: ask for an update when this version is too old, and show maintenance | | | | | NOT STARTED |
| 57 | #58 | profile: see my personal information (read-only) | | | | | NOT STARTED |
| 58 | #59 | profile: change my own photo | | | | | NOT STARTED |
| 59 | #60 | sign-in: "forgot password" says ask HR, and "remember my email" works | | | | | NOT STARTED |
| 60 | #61 | app: hide what the company has not bought | | | | | NOT STARTED |

## Outside the work order

Parent issues (#62 to #66) group the items above. The rest were reported later and carry no work-order line.

| Issue | Title | Status |
|---|---|---|
| #62 | fixes: what is broken today, and what blocks the store release | parent issue |
| #63 | payslip: real payslips from the server | parent issue |
| #64 | overtime: ask, join and clock OT in the App (guide Parts 1–2) | parent issue |
| #65 | requests and approvals: off-site scans, forgot to scan, and one Approvals place | parent issue |
| #66 | extras: push, notifications, update, profile and sign-in | parent issue |
| #68 | leave approvals: refresh when the leave was already decided (INVALID_STATUS) | NOT STARTED |
| #69 | leave cancel: refresh when the leave was already decided (INVALID_STATUS) | NOT STARTED |
| #70 | leave approve: show "not enough days left" on 422 INSUFFICIENT_BALANCE | NOT STARTED |
| #71 | push: sign the phone off on logout (shared phones get the last user's messages) | NOT STARTED |
| #72 | payslip: the salary list stops at 10 payslips a year | NOT STARTED, priority bug |
| #73 | forgot to scan: a request with a photo is always refused (attachment_url must be a string) | NOT STARTED, priority bug |
| #74 | Leave edit: handle 409 LEAVE_CHANGED; type change now checked (backend #221) | NOT STARTED |

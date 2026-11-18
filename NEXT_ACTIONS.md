# Next actions

Progress record for the 60 work items (issues #2 to #61) and the bugs reported after them. One issue, one
branch, one PR; work order decides what lands first. Update the row when its status changes.

Statuses: `NOT STARTED`, `IN PROGRESS`, `BLOCKED`, `IMPLEMENTED`, `PR OPEN`, `MERGED`.

Last updated: 2026-11-18 (#59 merged, `08b8864`; next is #60, not started; #55 stays blocked on the backend). To resume, read `VERIFY_BEFORE_CONTINUING.md` first.

## Current status

State checked against GitHub and `origin` at the end of 2026-11-17.

| | |
|---|---|
| Last finished work order | 58 of 60: #59, profile: change my own photo |
| Next work order | **59 of 60: #60**, sign-in: "forgot password" says ask HR, and "remember my email" works. Not started, no branch, no plan shown yet. (#55 stays BLOCKED on Nexton-Backend#190.) |
| `origin/main` | `adad453` "Merge branch '51-push-setup' into main" (2026-11-18) |
| Local `main` | the same commit; nothing uncommitted, nothing staged, no untracked files, no stashes |
| Feature branches | `2-…` to `44-…` (no `35-…`: #35 is BLOCKED), `clock-in-out-location`, `fix/offsite-test-strings`, `meng`: each equal to its remote, none ahead. Every issue branch is contained in `origin/main` |
| This file | lives on branch `docs/next-actions` only (with `VERIFY_BEFORE_CONTINUING.md`). It is not on `main`; the owner has not asked for that |
| Gates on `main` at `56b6c75` | `flutter analyze lib test`: 1 warning, already on `main` before this work (`_ShiftHoursLine` unused, `attendance_status_card.dart`); `flutter test`: 1,944 passed, 0 failed; `flutter build apk --debug`: builds |
| Pull requests | none for any work item. GitHub has two PRs, both docs and both merged before this work: #1 and #67 |
| Issues on GitHub | all 73 are **open** (#2 to #75; #67 is a PR). Merge messages say `Refs #N`, not `Fixes #N`, so nothing closed by itself. Newest is #75 (docs), as at the start of the day |

How "MERGED" is used here: the issue's branch is contained in `origin/main` (checked with
`git merge-base --is-ancestor`) and the gates passed on the merge commit. It was pushed to `main` directly, as a
merge commit, on the owner's say; there is no pull request to point to, and the GitHub issue stays open until its
check on a phone is done. No issue has had that phone check yet.

### Finished on 2026-11-16

The baseline and work orders 1 to 22 (#2 to #23), each on its own branch, reviewed by a fresh reviewer and an
adversarial one (one reviewer for the tests-only #13), then merged to `main` with a merge commit. The rows under
"Work items" carry each branch, commits, merge commit and test count. Test count went from 369 (baseline) to
1,261.

| Area | Issues | What is on `main` now |
|---|---|---|
| App set-up | #2, #3 | store builds reach `app.nexton.work`; debug builds reach `nexton-demo`; release signing reads `key.properties` |
| Errors and sign-in | #4, #5, #6 | Lao text by error code; no surprise sign-outs; a wait after too many tries |
| Attendance | #7 to #11 | the right day and month; refusals in Lao; weekday shift times, GPS only; real history fields; the server's month summary |
| Profile | #12 | a clear message when the profile cannot load |
| Leave | #13 to #17 | tests; active types and the balance check; company days off; refusals reload; the request page by id |
| Lists and approvals | #18, #19 | load more on scroll (shared helper); "what I decided", own request without buttons |
| Payslip | #20 to #23 | the server's payslip as sent; the real list; line names, groups and captions; the payslip page by id |

### Finished on 2026-11-17

Work orders 23 to 43 (#24 to #44, but #35: BLOCKED on the backend's OT hours, re-checked twice, no "now live").
Each: plan, the owner's "go", its own branch from fresh `main`, tests first, gates, two fresh reviews (one
adversarial, with probes), the real findings fixed and mutation-checked, then merged to `main` on the owner's "push
issue N to main directly". Test count went from 1,261 to 1,944. Day log: `WORK_LOG.md` on this branch.

| Area | Issues | What is on `main` now |
|---|---|---|
| Payslip | #24 to #26 | OT items sheet; the PDF in the App with Share (`pdfx`, `share_plus` 12, owner-approved); the latest-payslip card |
| Overtime | #27 to #34 | OT models and calls; the OT list; the request page; ask, edit, cancel; HR's OT posts and join; the clock button knows an open OT |
| Approvals | #36, #37 | the Approvals place only for department heads and HR (`approver_access.dart`); the leave request's own approver page with Approve-with-note / Reject |
| Shared upload | #38 | `lib/core/upload/` (moved from time_off): 5,000,000-byte check, `folder`, refusals in Lao, `CapturePolicy`, `FileSourceSheet`, `UploadNotifier` |
| Leave files | #39 | several files on the form; `attachments` as a list (edit sends it only when changed); files open in the App (photo, PDF, Share); `core/widgets/pdf_file_view.dart`, `image_viewer.dart`, `core/files/temp_share_files.dart` |
| Off-site | #40 to #42 | the form only after a refused punch, camera only; the card sees a waiting off-site check-in (`domain/next_punch.dart`); "My requests" (`/attendance/requests`) with the off-site tab, paging, detail and cancel |
| Forgot to scan | #43, #44 | 30-day look-back; `domain/correction_rules.dart` (window, overnight, weekday rows); refusals in Lao; the form filled from a history day (`?date=&part=`) |

### Not finished

- **Phone checks on `nexton-demo`: none done, for any issue.** Every "Done when" box that needs a phone, two
  logins or the web portal is still open. This is the main thing between "MERGED" and closing an issue.
- **By hand, by the lead:** #2 a release APK signs in on a phone; #3 the real upload key, a release bundle, a
  phone install, the iOS simulator build.
- **Issues to close on GitHub** once checked: #2 to #44 but #35 (all still open). Also likely covered by merged work and
  only needing a check before closing: #68, #69, #70, #72, #74 (see "Outside the work order").
- **Priority bug #73** (forgot to scan with a photo is refused): root cause known, not scheduled.

### Waiting for the owner

1. **#51 merged** (`adad453`) on the owner's say, 2026-11-18. The designer's Nexton tray glyph replaces the
   placeholder `android/app/src/main/res/drawable/ic_stat_nexton.xml`.
   **#50 merged** (`79a134a`) on the owner's say, 2026-11-18. #48's OT tab has the per-page next-page counting fixed
   for #50 (one line); part of the open #48 question.
   **#49 merged** (`5960973`) on the owner's say, 2026-11-18.
   **#48 merged** (`fbeb16e`) on the owner's say, 2026-11-18. Two questions for the owner, unanswered: cap the automatic
   next-page fetch (an HR login that is also a head fetches every page on opening the OT tab), or `per_page=100`? And
   read OT wall clocks as Lao time (+07) for "waiting n h" (with #27's question)?
   **#47 merged** (`227a9b3`) on the owner's say, 2026-11-18. Item 11's direct link to
   `/attendance/time-correction/approvals` is settled (Approvals tab, behind the gate).
   **#46 merged** (`afedb4f`) on the owner's say, 2026-11-18. Check a real `my-approvals?status=pending` payload on
   `nexton-demo`: does a waiting dept-head step carry `approver.id` (an employee id)?
   **#45 merged** (`0aa9eb1`) on the owner's say, 2026-11-18. Check on `nexton-demo` whether the detail carries the
   employee's id (Cancel's "own" check, for #47) and `attendance_record`'s time format.
   **#44 merged** (`56b6c75`) on the owner's say, 2026-11-17.
   **#43 merged** (`da3fda8`) on the owner's say, 2026-11-17.
   **#42 merged** (`2385f00`) on the owner's say, 2026-11-17.
   **#41 merged** (`a205629`) on the owner's say, 2026-11-17.
   **#40 merged** (`01bf4be`) on the owner's say, 2026-11-17.
   **#39 merged** (`35df673`) on the owner's say, 2026-11-17.
   **#38 merged** (`f3cdef7`) on the owner's say, 2026-11-17.
   **#37 merged** (`abfde43`) on the owner's say, 2026-11-17.
   **#36 merged** (`4ad1873`) on the owner's say, 2026-11-17.
   **#34 merged** (`55c41e7`) on the owner's say, 2026-11-17.
   **#33 merged** (`77db2c0`) on the owner's say, 2026-11-17.
   **#32 merged** (`c8880d6`) on the owner's say, 2026-11-17. A login whose `employee_id`
   is null (#75) sees no Edit/Cancel on its own request (the issue's "own employee only" read safely).
   **#31 merged** (`446a272`) on the owner's say, 2026-11-17. For the backend: the reason's
   2000 limit is kept in code points on the App side (a Lao letter is several); confirm how the server counts.
   **#30 merged** (`41c604f`) on the owner's say, 2026-11-17, after the review fixes (owner chose "fix first, then
   merge").
   **#29 merged** (`444929f`) on the owner's say, 2026-11-17. A Lao speaker to check
   `otPickMonth` "ເລືອກເດືອນ" (not from the issue).
   **#28 merged** (`c8ccd35`) on the owner's say, 2026-11-17. Still to confirm with the backend: cancel answers `403 FORBIDDEN` as "a waiting request: reject it instead" (the issue's table). If the
   server also sends `FORBIDDEN` when an employee cancels a request that is not theirs, that employee would read
   "reject it" (`ot_request_handler.go:80-83`, not readable here).
   **#27 merged** (`9a871bb`) on the owner's say, 2026-11-17. Still open for the lead: on a
   phone outside Laos, OT wall-clock times (`created_at`, `acted_at`, …, read as phone-local as the issue says) and
   moments (`starts_at`, …) are on different clocks, up to 12 h apart. Documented "never compare them"; reading both
   as Lao time (+07, or the company's zone) is a decision.
   **#26 merged** (`8cc530a`) on the owner's say, 2026-11-17. Still open, a product question: if
   only `/my/latest` fails (one dropped request) while the year's list loads, the card is gone with no Retry until the
   page is reopened (the issue's table: "hide the card; the list has its own Retry"). Add a way back (re-ask on a
   year switch when it failed, or a small Retry on the card)?
   **#25 merged** (`9515eee`) on the owner's say, 2026-11-17.
   **#24 merged** (`2d744c4`) on the owner's say, 2026-11-17. Still open: which Flutter version does the team use? The local `dart format` rewrites ~20
   salary files this change does not touch (reverted, not committed).
10. **#75** (new, 17 Nov): docs only. `/auth/me` finds `employee_id` a new way; `lib/features/auth/auth.md` lines 24
    and 186 are out of date. No code change. Where in the order?
2. **#56** is on the owner's BLOCKED list, and the backend said on 15 Nov that it is live. Treat as unblocked?
   (The same question was answered "go" for #21 and #23.)
3. **Paid chip and failed payments (#21):** a paid run whose payment failed is listed under "Paid", with its red
   pill, as the issue says. Should "Paid" leave it out?
4. **"What I decided" (#19)** sits under the waiting list in one scroll, as the issue says; with 140 waiting an
   approver scrolls through all of them to reach it. A tab or a jump link?
5. **Strict payslip reader (#20):** one payslip with bad money, or no id, fails the whole year's list. Keep, or
   skip the bad row and show the rest?
6. **Payslip page refresh (#23):** it does not refresh once loaded. Add a pull to refresh?
7. **English labels (#22, #23):** existing "Base Salary", "Social Security", "Income Tax", "Income", "Unable to
   load the payslip." against the issues' "Basic salary", "Social security", "Income tax", "Earnings", "Could not
   load the payslip." Lao matches the issues.
8. **#72 and #73:** where they go in the order.
9. **This file on `main`?** It is only on `docs/next-actions`.
11. **From #36:** keep the Approvals title "ອະນຸມັດ", or the issue's "ການອະນຸມັດ"? And `/attendance/time-correction/approvals`
    is still reachable by anyone with a direct link (nothing in the App links to it): a follow-up issue?
12. **From #38/#39 (not new, worth issues):** a 401 mid-upload replays a finalized `FormData` and fails; the
    new-request leave draft and its files outlive a sign-out (`leaveRequestFormNotifierProvider` is not autoDispose).
13. **From #40, for the lead:** a refusal shows the server's message when it sends one (#8's rule), so a Lao user may
    read English (e.g. `OFFSITE_REQUEST_EXISTS`, `CHECKIN_PENDING_APPROVAL`). Should the App's Lao text win?
14. **From #41, for the lead:** a day-shift off-site check-in from yesterday never closed now leaves today on a normal
    clock-in (only a night shift's yesterday check-in holds the slide). Confirm that is wanted.
15. **A login that heads a department on `nexton-demo`**, for the phone checks of #36, #37 (ask the lead).

## Confirmed decisions

Product decisions confirmed on 2026-11-13. They stand unless the owner says otherwise.

- App ID: `next.on.hr.com`.
- Test company: `nexton-demo` (`nexton-demo.nexton.work`). Store builds: `app.nexton.work`. Never test against
  `app.nexton.work`. Demo settings must not reach a production build.
- Only department heads and HR approve.
- Forgot to scan: up to 30 days back (not 90).
- Off-site: a camera photo only, no gallery; the form opens only after a refused clock-in or clock-out; no menu
  tile of its own.
- Notifications: no number on the App icon; the unread count is on the bell inside the App; the native popup
  still shows while the App is open; tapping a push opens its screen.
- Payslips: statuses are exactly "Approved", "Paid", "Payment failed — contact HR" (no "Pending"); the PDF opens
  in the App; a Share action.
- Profile: real working hours, late and absent figures.

Decided by the owner on 2026-11-16, during the work:

- Work reaches `main` by a direct push of a merge commit, on the owner's "push issue N to main directly". No
  force-push; no pull requests so far. Merge messages use `Refs #N`.
- Each issue: a plan first, then the owner's "go", then the branch.
- #7: the night-shift rule stays as the issue has it; no cut-off is added.
- #8: left as built (one Lao sentence still wants a Lao speaker's eye: `ruleClockOutBeforeClockIn`).
- #9: keep `lib/features/auth/auth-login.md` and `lib/features/attendance/attendance-offsite-requests.md`.
- #21 and #23: built after the backend's "now live" comment of 13 Nov and the owner's "go". They are no longer
  blocked.
- #22: built as functions and strings; the payslip page moved onto them in #23.

## Baseline

| Step | Branch | Commit | PR | Tests | Status |
|---|---|---|---|---|---|
| Bring `clock-in-out-location` into `main` (merge commit) | `clock-in-out-location` | `197ff6c` | none: pushed to `main` directly on the owner's say, 2026-11-16 | 369 passed on the merged result | MERGED |
| Fix nine off-site tests left stale by `b64a77a` ("scan" became "clock-in") | `fix/offsite-test-strings` | `ae02169` | none: pushed to `main` directly on the owner's say, 2026-11-16 | `flutter test`: 369 passed, 0 failed | MERGED |

## Next

1. **Next: #60 (work order 59 of 60), "sign-in: 'forgot password' says ask HR, and 'remember my email' works".**
   Not started: no branch, no plan shown yet. Read the issue and its comments, plan, wait for "go". Then #61. #55
   stays blocked on Nexton-Backend#190.

   **#59 (work order 58 of 60): MERGED (`08b8864`)** on the owner's say, 2026-11-18, from `59-profile-photo`
   (`13cb98c`, review fixes `371cea0`). Gates: analyze 1 warning already on `main`; `flutter test` 2,368 passed;
   debug APK built. Owner decisions: no shrinking package (a photo over 5,000,000 bytes is refused on the phone, as
   #38); JPEG and PNG only (a gallery HEIC is refused as "not a photo"); on success the returned URL is shown in place
   (no full refresh). Also fixed for every upload: the auth interceptor's replay after a token refresh sends a fresh
   copy of a multipart form (it failed with "Unknown network error"). Device checks pending on `nexton-demo`: camera,
   gallery and file photos change the profile and the home header without a restart, HR sees it; a file over 5 MB
   refused on the phone; a double tap starts nothing; flight mode mid-upload keeps the old photo. Next after this: #60.
   #55 stays blocked on Nexton-Backend#190.

   **#58 (work order 57 of 60): MERGED (`2c35513`)** on the owner's say, 2026-11-18, from `58-personal-info`
   (`dff359e`, review fixes `1792a0c`). Gates: analyze 1 warning already on
   `main`; `flutter test` 2,339 passed; debug APK built. The model reads only the page's fields (never salary, ID,
   passport, tax, social security, bank), texts and whole numbers only. For the owner: a failed pull to refresh
   replaces the record with the error (the profile notifier's `refresh()` drops to plain loading, as on Profile); the
   debug build's log prints the whole `/core_hr/employees/me` body, salary and IDs included (older than #58; release
   builds do not log); a Lao-only emergency contact (no `name`) is dropped, as the issue says. Device checks pending
   on `nexton-demo`: phones, manager, two contacts shown; none of them gives `-` and "None yet"; opening sends no
   request, a pull sends one. Next after this: #59. #55 stays blocked on Nexton-Backend#190.

   **#57 (work order 56 of 60): MERGED (`cb69094`)** on the owner's say, 2026-11-18, from `57-app-gate` (`d1a026a`,
   review fixes `5ccaa11`). Gates: analyze 1 warning
   already on `main`; `flutter test` 2,320 passed; debug APK built. Owner decisions: `package_info_plus` (already
   transitive, now direct) and `url_launcher` (new) approved; a failed check keeps the last status; an unreadable
   version skips the check; Play fallback `id=next.on.hr.com`; texts say "NEXTON". `AppConstants.appVersion` is gone:
   `AppVersion` (set in `main`) feeds the User-Agent, the login footer and push registration. Open: the gate shares
   the `/mobile` 60-a-minute-per-IP limit with push sign-up and the bell list (a 429 just carries on); whether
   `/mobile/app-info` stays up while the backend is in maintenance is unverified (backend repo private). Device
   checks pending (never by changing the live record): `--build-name=0.9.0` against `nexton-demo` shows the update
   screen before login and after sign-in, the Play button opens `next.on.hr.com`; a normal build and flight mode
   start as before; the call works on `app.nexton.work`. #55 stays blocked on Nexton-Backend#190.

   **#56 (work order 55 of 60): MERGED (`f3cb794`)** on the owner's say, 2026-11-18, from `56-server-logout`
   (`abba477`, review fixes `7564f53`). Owner's go 2026-11-18. Sign-out:
   push row (#52), then `POST /auth/logout` (refresh token in the body, no bearer, 5 s, failures ignored), then the
   local clear. A refresh answer without `refresh_token` keeps the saved one (no rotation on the server). A late
   refresh answer for an ended sign-in writes and clears nothing; a paused sign-out never ends the next user's
   sign-in. Worst-case sign-out on a very slow connection: about 13 s, no spinner (follow-up if wanted). Device checks
   pending on `nexton-demo` (sign in again first: older sign-ins cannot be ended): curl refresh with the old token
   answers 401 after sign-out; flight-mode sign-out at once; HR's end-sessions lands the phone on the login screen
   with "session expired". After this: #57 (#55 stays blocked).

1. **Next: #55 is blocked on the backend (unread count, Nexton-Backend#190), and #56 (sign-out ends the session on the
   server) waits for the owner's go. The next buildable is #57 (work order 56 of 60), "app: ask for an update when this
   version is too old, and show maintenance".** Not started: ask the owner which of #56 or #57 comes first, then read
   the issue, plan, wait for "go".

   **#54 (work order 53 of 60): MERGED (`748e760`)** on the owner's say, 2026-11-18, from `54-notifications-list`
   (`8ffe783`, review fixes `9678f08`). Gates: analyze 1 warning already
   on `main`; `flutter test` 2,267 passed; debug APK built. Owner decisions: the list in `lib/features/notifications/`;
   OT reuses `otMenu` (no `notificationKindOt`); #53's fallback (unknown push, or one missing its id) now opens the
   bell list, `attendance_offsite` still Home; a row with nowhere of its own to open does nothing. Copies from two
   phones collapse when a kept row within 60 s matches (until Nexton-Backend#190). Known limits, not fixed: a first
   page whose every row is unreadable (no id or `created_at`) ends the list; the bell and Profile rows have no
   double-tap guard (as every Profile row today); the bell tile is 44 dp, the design's size. Fields come from the
   issue's table (the backend repo is private): confirm on `nexton-demo`. Device checks pending: bell and Profile
   open the same list; empty text; Retry; more than 20 rows load page 2 once; a leave row opens the request, an
   off-site row Home; failed sends still show; a second login never sees the first's rows.

   **#53 (work order 52 of 60): MERGED (`dcb056c`)** on the owner's say, 2026-11-18, from `53-push-open`
   (`9df2051`, review fixes `862cb98`). Gates: analyze 1 warning already on `main`; `flutter
   test` 2,226 passed; debug APK built. Owner decisions: routing in `lib/features/notifications/`
   (`domain/push_route.dart`, `presentation/push_router.dart`, #54 reuses it); no new string (each by-id page keeps
   its 404 text); non-Home targets open with `push`. Someone else's leave or "forgot to scan" request hands over to
   the approver page (`ApproverHandOver`, only from the top page, once); a login that stays on the employee page
   sees no Edit/Cancel on another's leave. The open point above is settled that way: the server refuses, the App
   hides the owner's actions. Device checks pending: iOS tap on the foreground alert arrives via
   `onMessageOpenedApp`; Firebase-console messages for each table row (closed, background, open); the forced
   password change then the item; B tapping A's push sees the "not there" text.

   **#52 (work order 51 of 60): MERGED (`f0c7a6c`)** on the owner's say, 2026-11-18, from
   `52-device-registration` (`1e4d192`, review fixes `91b31f7`). Covers #71. Gates: analyze 1
   warning already on `main`; `flutter test` 2,177 passed; debug APK built. Owner decisions: device id stays in SharedPreferences; auth reaches push through
   `beforeSignOutProvider` (wired in `main.dart`). The sign-off DELETE carries `AuthInterceptor.noRefreshFlag` (no
   refresh on its 401, so a late refresh cannot write tokens back after sign-out). Device checks pending on
   `nexton-demo`: one row after sign-in, gone after sign-out, one row after a relaunch, flight-mode sign-out instant,
   two logins taking turns on one phone. Offline, the token delete is retried before the next registration; if it
   still fails, backend #213's shared-phone rule is what moves the token.

   **#51 (work order 50 of 60), "push: Firebase set up for nexton.hr on Android and iOS": MERGED (`adad453`),
   2026-11-18.** Merged on the owner's "push issue 51 to main directly"; gates green on the merge commit (analyze 1
   warning already on `main`; 2,150 tests passed; debug APK builds). Owner said go on 2026-11-18 (app id `next.on.hr.com`; a white placeholder tray
   icon; keep `flutter_local_notifications`; stays in `lib/features/notifications/`). Branch `51-push-setup` (pushed):
   `d4a2b38` (feature), `8f41b6d` (review fixes). Gates on `8f41b6d`: analyze 1 warning already on `main`; `flutter test`
   2,150 passed; debug APK builds; `flutter build ios --simulator --debug` builds. `pubspec.lock` unchanged (packages
   were on `main`).
   - `AppInitializer.initialize()` returns whether push started: Firebase and the background handler in a `try` (debug
     log only); `main.dart` passes it as `pushAvailableProvider` (default false), and the push notifier does nothing
     without it.
   - One file imports `package:firebase_messaging`: `firebase_messaging_data_source.dart` (background handler, instance,
     registration moved in; `push_background_handler.dart` gone).
   - Permission asked once on this phone, after sign-in: remembered in SharedPreferences (`push_permission_asked`),
     never again after a refusal; one prompt at a time (a token refresh waits); the save through `guard`. Registration
     still every sign-in.
   - Debug builds print the FCM token; nothing push-related logs in release. iOS `badge: false`.
   - Tray icon: `res/drawable/ic_stat_nexton.xml` (white placeholder ring and dot) + `default_notification_icon`
     meta-data; the local pop-up uses it.
   Open after #51, none built there:
   - device checks: console test message on an Android 13+ phone and an iPhone (closed, background; iOS also open); the
     tray icon; an iOS start with no plist;
   - **the designer's Nexton glyph** replaces `ic_stat_nexton.xml`;
   - the prompt may show over the splash on a cold start with a saved session (minor);
   - live pushes from the server wait for the backend's new key (phoudssp/Nexton-Backend#187).

   **#50 (work order 49 of 60), "approvals: my team's leave and "forgot to scan" history (read-only)": MERGED
   (`79a134a`), 2026-11-18.** Merged on the owner's "push issue 50 to main directly"; gates green on the merge commit
   (analyze 1 warning already on `main`; 2,142 tests passed; debug APK builds). Owner said go on 2026-11-18 (headed_department_ids, no profile
   department; readOnly pages). Branch `50-team-history` (pushed): `f00dd81` (feature), `c02e491` (review fixes). Gates
   on `c02e491`: analyze 1 warning already on `main`; `flutter test` 2,142 passed; debug APK builds.
   - Auth: `headed_department_ids` (live 15 Nov) from `/auth/me` onto `User.headedDepartmentIds`, kept in the cache.
   - Data: `GET leave/requests/team` (cursor, `limit` 20, `?status`), rows read `employee.department.id`;
     `GET correction-requests/team` by page number (`page` / `per_page`, never `limit`) into `NumberedPage` (new, in
     `core/network/paged_list.dart`).
   - 5th Approvals tab "ທີມຂອງຂ້ອຍ" for heads only (`canSeeTeam`): "ລາພັກ" / "ລືມລົງເວລາ" switch, each loaded when first
     shown and then kept while the tab lives; all / waiting / approved / rejected / cancelled chips (server filter).
   - `TeamListNotifier` base + `TeamLeaveNotifier` / `TeamCorrectionsNotifier`: never the head's own; an HR-leave login
     keeps only headed departments (a row with no department dropped); the server's pages kept, filtered on read; the
     automatic next page counts the whole load (stops at 20 shown or the end); restarts only when who is looking changes.
   - Rows: leave (name, type's Lao name, days "1, 15 Sep" when not in a row, status), corrections (#47's card, no buttons).
   - `/approvals/team/leave/:id` and `/approvals/team/correction/:id` (heads only): #37's and #45's pages with `readOnly`
     (no buttons, no Cancel, no contact note); a 404 on their own read keeps the row's copy.
   Open after #50, none built there:
   - phone check on `nexton-demo` (head login; an HR login heading Sales sees only Sales; 25 team corrections → `page=2`
     once on scroll);
   - an HR-head whose headed departments are a small part of the company still walks pages until 20 of its rows show;
   - **#48's OT tab has the per-page counting fixed here for #50** (one filtered row per page chains the next): the same
     one-line fix applies there; it is part of the owner's open #48 question (cap / `per_page=100`);
   - a page whose rows all fail to read ends the list (`PagedList`, shared); the read-only leave page's refresh still
     re-reads the head's own balances (as #37's page).


   **#49 (work order 48 of 60), "approvals: approve or reject OT, and cancel an approved OT before it starts": MERGED
   (`5960973`), 2026-11-18.** Merged on the owner's "push issue 49 to main directly"; gates green on the merge commit
   (analyze 1 warning already on `main`; 2,118 tests passed; debug APK builds). Owner said go on 2026-11-18. Branch `49-ot-decisions`
   (pushed): `1110d2d` (feature), `bbefe8b` (review fixes). Gates on `bbefe8b`: analyze 1 warning already on `main`;
   `flutter test` 2,118 passed; debug APK builds.
   - Data: `PUT ot-requests/:id/approve|reject` with `step_id` (always) and `comment` (typed; required on reject), never
     `pieces`; the answer is the request (warnings ignored). `422 errors.comment` → "ກະລຸນາຂຽນເຫດຜົນ" (a toast: the
     dialog has closed; it blocks an empty reason anyway). The head's cancel is #28's `PUT .../cancel`.
   - `ApproverAccess.canDecideOt` (pending; the waiting step a dept_head / specific one naming me; not my own; not after
     I approved an earlier step; HR rights add nothing) and `canCancelApprovedOt` (approved; a head step I approved; now
     before `starts_at`, moments).
   - `OtDecisionNotifier` per request: one approve / reject / cancel at a time from the row or the page. Success: the
     page shows the server's answer, the row leaves waiting at once, both lists reload (not waited on). Failure keeps
     the row: STEP_CHANGED / OT_ALREADY_DECIDED / NOT_APPROVER reload lists and page (NOT_APPROVER also takes the
     buttons away); OT_STARTED / OT_ALREADY_PAID / OT_PAID_BY_HAND take Cancel away; 404 → "not available", the page
     goes back; #28's texts.
   - `OtDecisionButtons` on #48's waiting rows and on #30's page for someone else's request (the employee's own Edit /
     Cancel / "ask the approver" unchanged): Approve → #37's note dialog (sent as `comment`), Reject → the reason
     dialog, "ຍົກເລີກໂອທີ" with a confirm. Toasts `otApprovedToast` / `otRejectedToast` / `otCancelledToast` (existing).
   Open after #49, none built there:
   - phone check on `nexton-demo` (`dept_head_hr`; HR approves on the web, then the head cancels before `starts_at`;
     the employee's OT switch off → `OT_NOT_ELIGIBLE` keeps the row);
   - Cancel does not hide by itself when `starts_at` passes with the page open (the server's `OT_STARTED` covers it);
   - after a decision the waiting list reloads from page 1 (later pages loaded before are dropped).


   **#48 (work order 47 of 60), "approvals: OT waiting and decided lists for heads": MERGED (`fbeb16e`), 2026-11-18.**
   Merged on the owner's "push issue 48 to main directly"; gates green on the merge commit (analyze 1 warning already on
   `main`; 2,089 tests passed; debug APK builds). Owner said go on 2026-11-18. Branch `48-ot-approvals-lists` (pushed): `11db106`
   (feature), `e1cd94d` (review fixes). Gates on `e1cd94d`: analyze 1 warning already on `main`; `flutter test` 2,089
   passed; debug APK builds.
   - Data: `GET ot-requests/my-approvals?status=&page=&per_page=` (offset only, never `limit`), always pending / approved /
     rejected, as `OtPage`. `employee.department` read (live 15 Nov: current department; `name_lo` may be null); a 422 is
     logged in debug.
   - 4th Approvals tab "ໂອທີ" (`apprSectionOt`) for heads only (`canApproveOt`); more than three tabs scroll. Waiting +
     "decided by me" chips, each paged by number (`PagedList` numbered mode), kept alive; waits for the session's
     employee id; restarts on another login.
   - HR steps hidden: waiting = pending step not HR's; decided = the step I decided not HR's (unmatched: shown only when
     no step decided that way is HR's). Lists hold the server's pages as sent; a page leaving fewer than 20 rows asks for
     the next at once; "none" only once the list has ended (a failed next page shows its Retry).
   - Rows (`OtApprovalRow`): name (or number), number · department, day · window ("(next day)"), reason in 2 lines,
     "ລໍຖ້າ {n} ຊົ່ວໂມງ" on waiting, the request's own state ("waiting for: HR", …) on decided. Tap → #30's page.
     Errors: no staff record → #28's text, no Retry; else the shared load error with Retry; a failed refresh is toasted.
   Open after #48, none built there:
   - phone check on `nexton-demo` (OT route `dept_head_hr`; 25 waiting → `page=2` once on scroll; an HR login that is
     also a head sees no HR-step rows);
   - **for the owner:** the automatic next page follows the issue exactly, so an HR login that is also a head (whose
     lists hold every HR step) fetches every page one after another on opening the tab (a burst of requests). A cap
     (e.g. stop after a few short pages and go on on scroll) or `per_page=100` for these lists would be cheaper;
   - "waiting n h" compares Lao wall-clock `created_at` with the phone's clock: off on a phone outside Lao time (the open
     #27 question: read wall clocks as +07?); it is computed per build, not ticking;
   - the decided-step match assumes `approver.id` is an employee id: check on `nexton-demo`.


   **#47 (work order 46 of 60), "approvals: "forgot to scan" requests for heads and HR": MERGED (`227a9b3`), 2026-11-18.**
   Merged on the owner's "push issue 47 to main directly"; gates green on the merge commit (analyze 1 warning already on
   `main`; 2,067 tests passed; debug APK builds). Owner said go on 2026-11-18 to the plan's three recommendations (shared bases,
   the old page to the Approvals tab, the page stays after approving). Branch `47-correction-approvals` (pushed):
   `3192f3e` (feature), `9a86936` (review fixes). Gates on `9a86936`: analyze 1 warning already on `main`; `flutter test`
   2,067 passed; debug APK builds.
   - Shared with #46 (its behaviour kept, its tests green): `AttendanceApprovalRequest` (both entities),
     `ApproverAccess.canDecideAttendance` (was `canDecideOffsite`), `ApprovalDecisionCode` (one shared table; each kind adds
     its own TOO_EARLY_CHECKIN wording, off-site its CHECKIN_* codes; `time_correction_error_code.dart` gone), base classes
     `AttendanceApprovalsNotifier`, `AttendanceDecisionNotifier`, `AttendanceApprovalsView`, `AttendanceDecisionFlow`.
   - The "forgot to scan" tab: waiting + "decided by me" chips, `limit=20` + cursor, kept alive; search box and dropdown
     gone; rows with the asked time beside the part's; buttons only on my step; own → the line.
   - Decisions: note on Approve; NOT_PENDING / STEP_CHANGED / 404 drop the row and reload; TOO_EARLY_CHECKIN (#8's text)
     and 500 keep it; NOT_APPROVER own / another, buttons go; a decision that went through hides the buttons even when the
     page cannot be read again.
   - `/approvals/correction/:id` (attendance approvers): #45's page with `approver: true`: no Cancel, no contact note,
     Approve / Reject; after a decision it stays and reloads ("ຜົນຫຼັງແກ້ໄຂ"). The old `/attendance/time-correction/approvals`
     opens Approvals on this tab behind the gate; `TimeCorrectionApprovalsPage` deleted (settles "Waiting" item 11).
   - The success toast for both kinds is #37's "Approved" / "Rejected"; 8 strings left unused by #46/#47 removed.
   - Tests: `correction_approvals_notifier_test.dart`, `correction_decision_code_test.dart` (not the issue's
     `correction_error_code_test.dart`: that name already holds #43's tests, kept as they were).
   Open after #47, none built there:
   - phone check on `nexton-demo` (the "Done when" walk, incl. two phones approving the same request);
   - the tab keeps #36's label "ອະນຸມັດແກ້ໄຂເວລາ" (the owner's go to the plan), not the issue's `apprSectionCorrection`;
   - not confirmed: that `GET correction-requests/:id` answers an approver (the issue says it does);
   - off-site's TOO_EARLY_CHECKIN still reads "Approved, but…" (as on `main` since #40); #46's issue asks for #8's text:
     a one-line follow-up.

   **#46 (work order 45 of 60), "approvals: off-site scans for heads and HR": MERGED (`afedb4f`), 2026-11-18.** Merged on
   the owner's "push issue 46 to main directly"; gates green on the merge commit (analyze 1 warning already on `main`;
   2,031 tests passed; debug APK builds). Owner said go on 2026-11-18 (search box dropped, the plan's recommendation). Branch
   `46-offsite-approvals` (pushed): `9aa91f0` (feature), `961cfb5` (review fixes). Gates on `961cfb5`: analyze 1 warning
   already on `main`; `flutter test` 2,031 passed; debug APK builds.
   - Visibility was #36's (comment item 1). The off-site tab in #19's shape: waiting (`status=pending`) + "decided by me"
     chips, each `limit=20` + cursor, loaded in parallel, kept alive. Search box and dropdown counts gone.
   - `ApproverAccess.canDecideOffsite`: pending with a waiting step; not own; not after approving an earlier step; HR step =
     attendance permission or admin; dept-head / specific = the named employee, or no one named yet (server decides).
     Rows read `employee.id`; steps `approver.id`. Own → `leaveOwnRequestNoActions`.
   - Approve → #37's note dialog (note sent when typed); Reject → `RejectReasonDialog` (moved from time_off to approvals).
     `OffsiteDecisionNotifier` (family by id): one decision at a time from row or page; decided / NOT_PENDING /
     STEP_CHANGED / 404 take the row out at once and reload; NOT_APPROVER → own / another approver, buttons go;
     CHECKIN_PENDING_APPROVAL, TOO_EARLY_CHECKIN, 500 keep it; CHECKIN_NOT_APPROVED → Reject only. A 403 stays a
     validation failure. Own decision table in `offsite_error_code.dart` (the correction one unchanged).
   - `/approvals/offsite/:id` (needs an attendance approver): #42's page with `approver: true`: card, photo full size,
     steps, decision; never Cancel; decided → back.
   - Shared: `core/widgets/paged_list_end.dart` (from the leave approvals tab); the scan card's number tag gives way at 420 px.
   - Strings: `apprAlreadyDecided`, `apprCannotDecideOwn`, `apprAnotherApprover`, `apprApproveCheckinFirst`,
     `apprCheckinNotApproved`. The tab keeps #36's label "ອະນຸມັດນອກພື້ນທີ່" (not the issue's `apprSectionOffsite`).
   Open after #46, none built there:
   - phone check on `nexton-demo` (two logins: staff without can_work_offsite + a head); **check a real
     `my-approvals?status=pending` payload: does a waiting dept-head step carry `approver.id`, and is it an employee id?**
     The rule leans on it (without it, the server decides and its NOT_APPROVER hides the buttons);
   - the leave approvals' and this tab's empty texts are leave's ("Nothing needs your approval"), as the issue allows;
   - `flutter analyze` (whole repo, as `CLAUDE.md` step 6 writes it) exits non-zero on the old `_ShiftHoursLine` warning
     and on stale `build/ios/SourcePackages` files: worth a small issue.


   **#45 (work order 44 of 60), "attendance: my "forgot to scan" requests — list, detail, cancel": MERGED (`0aa9eb1`),
   2026-11-18.** Merged on the owner's "push issue 45 to main directly"; gates green on the merge commit (analyze 1 warning
   already on `main`; 1,987 tests passed; debug APK builds). Owner said go on 2026-11-18, with "remove the menu tile". Branch
   `45-my-correction-requests` (pushed): `60fe12f` (feature), `f0d87d0` (review fixes). Gates on `f0d87d0`: analyze 1 warning
   already on `main`; `flutter test` 1,987 passed; debug APK builds.
   - "ຄຳຮ້ອງຂອງຂ້ອຍ" gets the tab "ລືມລົງເວລາ": `correction-requests/my?status=&limit=20&cursor=`, status as a server filter,
     next page on scroll, pull to refresh; both tabs kept alive across switches. `/attendance/time-correction/history` opens
     this tab; the "ປະຫວັດແກ້ໄຂເວລາ" menu tile is gone (owner's choice); the old history page is deleted.
   - Detail by id `/attendance/requests/correction/:id` (row as `extra`); old `…/history/detail` (id as extra) opens the same
     page. 404 → "not available", no staff record → #11's text, neither with Retry; back with nothing under → this tab.
   - `attendance_record` read only on an approved request → "ຜົນຫຼັງແກ້ໄຂ" card (in, out, #10's pill). Zone-less times as
     written; a time with a zone read as `records/my` is (on the phone's clock), so the card and history agree.
   - Cancel only on own pending (hidden when the request's employee id and the login's differ; shown when either is
     missing), one at a time; reloads detail and list; `CANNOT_CANCEL` by code → "already decided" + reload; cancel 404 →
     "not available"; accepted but the reload failed → shown cancelled. Today's card is not reloaded (a waiting
     correction cannot change it).
   - The submit keeps the 201's `data.id`; #44's toast has "ເບິ່ງ" opening it.
   - Row card: the id gives way so "Awaiting approval" fits at 400 px.
   Open after #45, none built there:
   - phone check on `nexton-demo` (the "Done when" walk); **check there whether the detail carries `employee.id` or
     `employee_id`**: without one, an approver opening this page by link would see Cancel (the server refuses it). Matters
     for #47;
   - **check `attendance_record`'s time format** on a real approved request (with or without a zone);
   - a page whose rows all fail to read (e.g. a new correction type) ends the list (`PagedList.append`, shared with #42):
     worth an issue;
   - the string `timeCorrectionHistoryMenu` is unused now; the `build_runner` run errors on `app_router.dart:64`
     (`?partId`, on `main`; harmless: the router has no generated part).

   **#44 (work order 43 of 60), "attendance: "forgot to scan" form, from a history day or the menu": MERGED (`56b6c75`),
   2026-11-17.** Owner said go on 2026-11-17. Branch `44-correction-form-entries`: `fdc11a7` (feature), `a2ba160` (review fixes).
   Gates: analyze 1 warning already on `main`; `flutter test` 1,944 passed; debug APK builds. Merged on the owner's "push issue 44
   to main directly"; gates green on the merge commit.
   - Built on the existing form/route: `/attendance/time-correction?date=&part=` (+ the session's part as `extra`) fills
     it; times follow the date's weekday; the window as a hint; DUPLICATE → dialog then back (home when nothing under);
     "Choose file" → #38's sheet (`CapturePolicy.photo`). History: "ລືມລົງເວລາ" under each session (or a day with
     none), only inside 30 days. Sessions read `shift_detail.id`.
   Open after #44, none built there:
   - phone check on `nexton-demo` (the "Done when" walk: last Friday's morning part → forgot to clock out 12:05 → web);
   - "View" on the success toast waits for #45; the attachment buttons row overflows in English at 420 px (on main);
   - a session with no part id opens on the first profile part; the form state is one provider (#53 pushing a second
     form while one is open would share it).

   **#43 (work order 42 of 60), "attendance: "forgot to scan" — rules and sending (no screen)": MERGED (`da3fda8`),
   2026-11-17.** Owner said go on 2026-11-17. Branch `43-correction-rules`: `3bb78d8` (feature), `3bffdd0` (review fixes). Gates:
   analyze 1 warning already on `main`; `flutter test` 1,921 passed; debug APK builds. Merged on the owner's "push issue 43
   to main directly"; gates green on the merge commit.
   - Look-back 30 days (was 90; decision 16), rule + picker + text. Profile parts read early/late minutes (part and
     weekly rows). `domain/correction_rules.dart`: window = start − early … end + late on that weekday, overnight by the
     times; a time placed on the day that puts it in the window; wrong_time needs one. The existing request carries
     its part. Submit refusals mapped: DUPLICATE, TOO_EARLY_CHECKIN, CORRECTION_DATE_OUT_OF_RANGE, any 422.
   Open after #43, none built there:
   - no new screen: nothing to try on `nexton-demo` until #44 (the existing form is the one the rules now check);
   - the form always holds both times, so wrong_time sends both; attachment_url "" stays for #73.

   **#42 (work order 41 of 60), "attendance: my off-site requests — list, detail, cancel": MERGED (`2385f00`),
   2026-11-17.**
   Owner said go on 2026-11-17. Branch `42-my-offsite-requests`: `47cc6b0` (feature), `8733133` (review fixes). Gates:
   analyze 1 warning already on `main`; `flutter test` 1,892 passed; debug APK builds. Merged on the owner's "push issue 42
   to main directly"; gates green on the merge commit.
   - "ຄຳຮ້ອງຂອງຂ້ອຍ" (`/attendance/requests`, TabBar, off-site tab; #45 adds "forgot to scan"). The off-site menu tile is
     now "My requests"; `/attendance/offsite/history` opens the same page.
   - The list pages by cursor (`limit=20`), status as a server filter (no counts), next page on scroll. Each request opens
     `/attendance/requests/offsite/:id` (by id): photo, time, in/out, place, reason, steps (ending "cancelled" when
     withdrawn), Cancel while it waits (reloads detail, list and today's card). 404 → "not available"; no staff record →
     "not linked". "ເບິ່ງ" on the off-site send toast opens the new request (`AppToast.success/info` take an action).
   Open after #42, none built there:
   - phone check on `nexton-demo` (the "Done when" walk, incl. >20 requests loading the next page once on scroll);
   - rows are the full off-site card, not the issue's one-line row; the detail Cancel has no "own" check (#46).

   **#41 (work order 40 of 60), "attendance: the card shows a waiting off-site check-in, and clock-out goes as off-site
   too": MERGED (`a205629`), 2026-11-17.** Owner said go on 2026-11-17. Branch `41-waiting-offsite`: `f6a1a8d` (feature),
   `c45b99f` (review fixes). Gates: analyze 1 warning already on `main`; `flutter test` 1,871 passed; debug APK builds.
   Merged on the owner's "push issue 41 to main directly"; gates green on the merge commit.
   - `loadToday` reads records/my, the open OT and `offsite-requests/my?status=pending&month=` (this month; the 1st also
     last month) together; the waiting read times out like the OT read and any failure means "none waiting".
   - `domain/next_punch.dart`: open session today / open OT → clock-out; a waiting check-in from today (or yesterday when
     its shift crosses midnight) with no paired waiting check-out → off-site clock-out; both waiting → `waitingBoth`
     (slide on clock-in); else clock-in. Card lines `attOffsiteCheckinWaiting` / `attOffsiteBothWaiting`. The slide on an
     off-site clock-out opens #40's form as `check_out` (no punch endpoint); one reload after.
   Open after #41, none built there:
   - phone check on `nexton-demo` (login without can_work_offsite): off-site check-in → card shows waiting + clock out;
     slide → form as check-out → both waiting; HR approves → the record's clock-in;
   - question for the lead: a day shift's off-site check-in from yesterday never closed — today goes back to a normal
     clock-in (only a night shift's yesterday check-in holds the slide); confirm that is wanted.

   **#40 (work order 39 of 60), "attendance: after a clock-in or clock-out refused for the area, scan outside the area
   with a photo and reason": MERGED (`01bf4be`), 2026-11-17.** Owner said go on 2026-11-17. Branch `40-offsite-after-refusal`:
   `90823eb` (feature), `7b616b4` (review fixes). Gates: analyze 1 warning already on `main`; `flutter test` 1,843 passed;
   debug APK builds. Merged on the owner's "push issue 40 to main directly"; gates green on the merge commit.
   - The form opens only from a refused punch, with its direction (read-only); `/attendance/offsite` without one is
     not-found. Camera only (gallery/file pick removed). **Owner's choice:** the off-site menu tile stays and opens only
     the history (until #42); the history's "new" banner is gone.
   - After sending: today reloaded (notifier taken before the send) and the form closes on recorded / pending /
     SESSION_* / CHECKIN_PENDING_APPROVAL; other refusals keep the form. Send waits while the position is read.
     `CHECKIN_PENDING_APPROVAL` mapped for the off-site form and a normal clock-out.
   Open after #40, none built there:
   - phone check standing outside the area (debug coordinates are gone on main): clock in / clock out refused → form;
     can_work_offsite → "Recorded"; second one → "already sent"; no gallery;
   - **question for the lead:** refusals show the server's message when it sends one (#8's rule), so a Lao user may read
     English for `CHECKIN_PENDING_APPROVAL` / `OFFSITE_REQUEST_EXISTS`; the App's Lao text shows only when the server
     sends none.

   **#39 (work order 38 of 60), "leave: attach a photo when the type needs a file, and open attached files": MERGED
   (`35df673`), 2026-11-17.** Owner said go on 2026-11-17 (and OK'd moving #25's viewer into core). Branch `39-leave-files`:
   `d940f37` (move: `core/widgets/pdf_file_view.dart`, `core/widgets/image_viewer.dart`, `core/files/temp_share_files.dart`;
   `PayslipPdfFiles` is its payslip setup, tests unchanged), `70da51a` (feature), `6724eac` (review fixes). Gates: analyze 1
   warning already on `main`; `flutter test` 1,829 passed; debug APK builds. Merged on the owner's "push issue 39 to main directly"; gates green on the merge commit.
   - Block only when the type needs a file and none is attached. Files in the form state (several; #38's sheet,
     `CapturePolicy.document`, folder `leave`); attach/remove off while sending; send off while uploading.
   - `attachments` is a list: create sends what is attached; edit sends the full list only when changed (absent keeps,
     `[]` removes). `LeaveAttachment`: url and file_name nullable, original_name read; url-less files kept and sent back.
   - Files open from the shared detail body (employee and approver): photo full screen, PDF in the App with Share, other
     on a Share page; plain Dio (no Bearer), timeouts, temp file deleted on close. Content type decides, name only as a
     fallback. `LEAVE_ATTACHMENT_REQUIRED` mapped.
   Open after #39, none built there:
   - phone check on `nexton-demo` (the "Done when" walk: Sick leave with a photo, a PDF opened, an edit that changes only
     the reason keeps the files, a head opens the certificate);
   - **privacy, worth its own issue:** the new-request draft and its files outlive a sign-out
     (`leaveRequestFormNotifierProvider` is not autoDispose; already so on main);
   - the downloader has no domain use case; Android share copies of leave files are not cleared; Lao file names become
     `_` in the share sheet (as payslips).

   **#38 (work order 37 of 60), "photos: take a photo with the camera and upload it (shared)": MERGED (`f3cdef7`),
   2026-11-17.**
   Owner said go on 2026-11-17 (and OK'd moving the upload code to `lib/core/upload/`; packages stay `camera` +
   `file_picker`, no `image_picker`). Branch `38-shared-upload`: `e2612f9` (pure move from `time_off`), `a498e41`
   (feature), `a0c7ecd` (review fixes). Gates: analyze 1 warning already on `main`; `flutter test` 1,804 passed; debug
   APK builds. Merged on the owner's "push issue 38 to main directly"; gates green on the merge commit.
   - One check before every upload (leave too): over 5,000,000 bytes is `uploadFileTooLarge`, never sent. `folder`
     sent: `leave`, `offsite`, `correction` (`UploadFolder`). 413 (by status) / `FILE_TOO_LARGE` → over 5 MB;
     `INVALID_REQUEST`, a missing file, an unusable 201, a picker error → choose again; `STORAGE_UNAVAILABLE` / 404 →
     contact HR.
   - For #39/#40/#44/#59 (not on a screen yet): `CapturePolicy` (cameraOnly/photo/document), `FileCapture` (provided in
     `main.dart`: the App's camera route; `file_picker` for gallery and files), `FileSourceSheet` (one at a time),
     `UploadNotifier`. iOS camera text widened; `NSPhotoLibraryUsageDescription` added.
   Open after #38, none built there:
   - phone check (Android + iOS): a camera photo uploads; a 6 MB PDF is refused; a server 413 may arrive as a dropped
     connection (try on `nexton-demo`);
   - off-site still offers the gallery until #40 switches it to `CapturePolicy.cameraOnly`;
   - not new, worth issues: a 401 mid-upload replays a finalized `FormData` and fails; `leaveAttachmentNotifierProvider`
     is not autoDispose (a file on an unsent new request outlives sign-out);
   - `timeCorrectionFileTooLarge` is now unused (both screens say `uploadFileTooLarge`).

   **#37 (work order 36 of 60), "approvals: open a leave request to see days, files, steps and notes before deciding":
   MERGED (`abfde43`), 2026-11-17.** Owner said go on 2026-11-17. Branch `37-leave-approval-detail`: `5fa7fba` (pure move of
   the read-only cards into `time_off/presentation/widgets/leave_request_detail_body.dart`), `55b7eeb` (feature),
   `c67dced` (review fixes). Gates: analyze 1 warning already on `main`; `flutter test` 1,773 passed; debug APK builds.
   Merged on the owner's "push issue 37 to main directly"; gates green on the merge commit.
   - `/approvals/leave/:id` (behind the Approvals gate): by-id load, list row first, pull to refresh; employee card
     (name, number, department), every day (one too). Buttons only from the page's own copy and only when
     `ApproverAccess.canDecideLeave` (HR step: leave permission or admin role; dept-head step: `approver.id` ==
     employee id, now `LeaveApprovalStep.approverId`; never own, never decided).
   - `ApproveNoteDialog` (shared by later approvals): confirm, optional `approver_note`, last-step balance line. Success:
     toast, lists reload, back (or to `/approvals` when opened by a link); kept alive if the user goes back mid-way.
     Stale refusals: text + page and lists reload. One decision per request, page or card. The list's inline Approve
     asks first too (owner's go on the plan's choice). Seven `appr*` strings.
   Open after #37, none built there:
   - phone check on `nexton-demo` with a head login (the "Done when" walk);
   - the shared by-id notifier refreshes the signed-in user's own balances/history when a status changes (extra call);
   - whether the list endpoint's rows carry `approver.id` (else the buttons wait for the by-id load: safe).

   **#36 (work order 35 of 60), "approvals: one Approvals place, only for department heads and HR": MERGED (`4ad1873`),
   2026-11-17.** Owner said go on 2026-11-17. Branch `36-approvals-heads-hr`: `d62a2bf` (feature), `04b85ee` (review
   fixes). Gates: analyze 1 warning already on `main`; `flutter test` 1,738 passed; debug APK builds. Merged on the owner's
   "push issue 36 to main directly"; gates green on the merge commit. #35 skipped (BLOCKED: OT hours, re-checked 2026-11-17).
   - `is_department_head` from login and `/auth/me` (live 14 Nov; `/auth/me` wins, missing = keep login/cached value);
     kept on the cached user (no separate secure-storage key), cleared on sign-out. `/auth/me` re-read on `onShow`, one at
     a time; a late answer is neither shown nor saved for a session that changed hands.
   - `approvals/domain/approver_access.dart` (admin roles count as HR; staff record required); tile, `/approvals` gate
     (`approvalsRoutes`, not-found otherwise), tabs per rule. Leave files not moved (optional). No new strings: kept
     "ອະນຸມັດ" over the issue's "ການອະນຸມັດ" (owner to confirm).
   Open after #36, none built there:
   - phone check on `nexton-demo` with a head login (ask the lead) and a plain login;
   - `/attendance/time-correction/approvals` still ungated (not linked in the App) — follow-up issue?;
   - page open while sections change keeps the tab number, not the section (cosmetic);
   - a late 401 on a stale request and the interceptor's refresh (not new here).

   **#34 (work order 33 of 60), "overtime: the clock button knows about an open OT session": MERGED (`55c41e7`),
   2026-11-17.** Owner said go on 2026-11-17. Branch `34-clock-open-ot`: `1c44232` (feature), `5f53ffa` (review fixes).
   Gates: analyze 1 warning already on `main`; `flutter test` 1,696 passed; debug APK builds. Merged on the owner's
   "push issue 34 to main directly"; gates green on the merge commit.
   - `GET /core_hr/attendance/ot-sessions/open` → `OpenOtSession` (`data: null` / no request id = none);
     `AttendanceState.openOt`; `nextAction` = Clock out when `day.isClockedIn` (#7's `pickCurrent`, kept) or an OT is
     open. `loadToday` reads both together on every trigger; only the newest load counts; the OT read gives up after
     5 s (`openOtSessionTimeoutProvider`) and its failure is no error. Card: OT `session_label` in the badge, "ສະແກນອອກ
     ພາຍໃນ HH:mm"; the per-second tick reloads once when that time passes. `PunchReceipt.overtimeRequestId`. No new
     check blocks a clock-in. Only `attendance_state.freezed.dart` regenerated (formatted like the committed one).
   Open after #34, none built there:
   - phone check on `nexton-demo` (OT on a day off: clock in, kill, reopen → Clock out; clock out → Clock in);
   - "clock out by" is on the phone's clock beside the server's OT label (two-clocks question);
   - the old OT badge shows until the reload after a clock-out finishes (slide locked meanwhile).

   **#33 (work order 32 of 60), "overtime: see HR's OT posts for my department and join one": MERGED (`77db2c0`),
   2026-11-17.** Owner said go on 2026-11-17. Branch `33-ot-posts`: `ceaf702` (feature), `6b7cadf` (review fixes). Gates:
   analyze 1 warning already on `main`; `flutter test` 1,670 passed; debug APK builds. Merged on the owner's "push
   issue 33 to main directly"; gates green on the merge commit.
   - `/overtime/posts` (entry ປະກາດໂອທີ at the top of the OT list). `OtPostButton` (pure, the guide's rule 1.5;
     an unreadable `my_join` never offers Join). `OtPostsNotifier`: page-number paging, refresh that keeps posts
     (and their load-more) on failure, join one at a time across cards, refused when the card no longer offers
     Join; the posts reload after every join answer; the OT list reloads after a join even if the page closed.
     Card: day, window, pieces + pay, places left (≥ 0) / no limit, closes (deadline, else start), reason.
     Join asks first (Back for no). Coming back from my join's page reloads the posts.
   - Also fixed in #29's OT list: a failed refresh during a load-more left the footer spinning for ever.
   Open after #33, none built there:
   - the closing time and piece times are in the phone's time zone (the two-clocks question);
   - nothing proves Join's question cannot open twice (a double tap opens one without the guard here).

   **#32 (work order 31 of 60), "overtime: edit or cancel my OT while it waits": MERGED (`c8880d6`), 2026-11-17.** Owner
   said go on 2026-11-17. Branch `32-ot-edit-cancel`: `16d741e` (feature), `eced537` (review fixes). Gates: analyze
   1 warning already on `main`; `flutter test` 1,636 passed; debug APK builds. Merged on the owner's "push issue 32
   to main directly"; gates green on the merge commit.
   - `OtRequestActions` (pure): Edit while pending, no step approved, not a join, day known; Cancel while pending;
     approved → "ask your approver or HR"; nothing on someone else's request or with the own id unknown
     (`otOwnEmployeeIdProvider`, from the session).
   - Cancel: question (no = "ກັບຄືນ"), `OtDetailNotifier.cancel()` (one request; `replace` → list row;
     `OT_ALREADY_DECIDED`/404 → refresh). Edit: `/overtime/request/:id/edit`, #31's form as a family
     (`otAskNotifierProvider(request)`; null asks), prefilled (reason controller, valid times only, reason cut to
     2000 code points), "approval starts again" note, Save (`otSaveAction`, our key). 200 → `replace`, "Saved",
     back; too late → text, reload, back; 404 → list; others stay. Edit and Cancel guarded against double taps;
     a link to the edit form of a gone request goes to the list, of a closed one shows the request.
   Open after #32, none built there:
   - nothing proves Cancel's question opens only once on a double tap (one request is proven, by the notifier);
   - an edit within the same month keeps the row's place in the list until it reloads;
   - the edit/cancel answers' `steps` are used as sent (handler not readable here);
   - for #49: `OtRequestActions` returns nothing for anyone but the owner, so the head's cancel needs its own
     branch.

   **#31 (work order 30 of 60), "overtime: ask for OT": MERGED (`446a272`), 2026-11-17.** Owner said go on 2026-11-17.
   Branch `31-ot-ask`: `c3659c1` (feature), `fdc36ec` (review fixes). Gates: analyze 1 warning already on `main`;
   `flutter test` 1,598 passed; debug APK builds. Merged on the owner's "push issue 31 to main directly"; gates green
   on the merge commit.
   - `/overtime/ask`: date (today), start/end 24 h (HH:MM), reason (2000, also 2000 code points); `(ມື້ຖັດໄປ)` when
     End < Start; amber past-date note (warning only). `OtAskNotifier`: one request however fast Send; 422
     `end_time` → End error; other refusals above Send, form kept; 201 → toast, `pushReplacement` to the request
     page, the OT list underneath refreshes. The page cannot be left while sending.
   - `EmployeeProfile.canAskOt` from `can_ask_ot` (live 15 Nov). Ask (floating button on the OT list) shows once
     the profile loaded and the flag is not false; hidden while loading or failed; a pull to refresh retries a
     failed profile. "How to clock OT" card (closed by default, four hints) above the list.
   Open after #31, none built there:
   - End = Start shows no `(ມື້ຖັດໄປ)` (the issue says ≤); the server refuses it and the End error shows;
   - the past-date note uses the phone's day, not the company's; a form left open past midnight warns only at the
     next change;
   - a 422 on a field other than `end_time` shows above Send in the server's words;
   - for #32: the form must start from a request (a family or `init`), prefill the reason (a controller), and
     call edit instead of ask.

   **#30 (work order 29 of 60), "overtime: an OT request page that opens by id": MERGED (`41c604f`), 2026-11-17.**
   Branch `30-ot-request-page`: `d4e2f6f` (feature), `0acf102` (review fixes). Gates on the merge commit: analyze 1
   warning already on `main`; `flutter test` 1,552 passed; debug APK builds.
   - `/overtime/request/:id` (`overtimeRoutes`, list row as `extra` when the id matches). `OtDetailNotifier`
     (autoDispose family; refresh keeps the copy except on 404; late answers and the first load never undo a
     newer `replace`; keeps the list's row in step: `OtListNotifier.showRow` / `dropRow`, so going back asks for
     nothing and loaded pages stay). Page: header, "ລໍຖ້າ: …", reason or —, leave timeline via `OtStepAdapter`
     with the shared `LeaveStepNote` (role • approver, note; moved out of the leave page), pieces with
     `otPayLabel`, "HR sets…" while pending, HR's note, the four notes only when set, "paid on your payslip" when
     approved; never an amount. 404: toast + back (to `/overtime` when nothing underneath). Retry shows the spinner.
   Open after #30, none built there:
   - a 404 goes back to whatever is underneath: from a #53 push over another screen it returns there, not to the
     list;
   - a piece past midnight shows `22:00–06:00` with no "(next day)" marker;
   - `pendingStep` takes the first pending step in list order, not by `stepNo`;
   - one leave test (`leave_approvals_card_test.dart`) did not complete once during the work and passed on two
     reruns: watch for a flaky test.

   **#29 (work order 28 of 60), "overtime: my OT list, on its own tile": MERGED (`444929f`), 2026-11-17.** Owner said go
   on 2026-11-17. Branch `29-ot-list`: `3728c18` (feature), `4615de2` (review fixes). Gates: analyze 1 warning
   already on `main`; `flutter test` 1,513 passed; debug APK builds. Merged on the owner's "push issue 29 to main
   directly"; gates green on the merge commit.
   - `PagedList` page-number mode (`firstNumbered`, `appendNumbered` with `keyOf` to drop repeated rows,
     `nextPage`, `retryable`); cursor mode unchanged. `OtListNotifier` (autoDispose; status/month filters, load
     more, retry, refresh that keeps rows on failure, stale answers dropped). `OtListPage` at `/overtime`, status
     chips (leave keys, reused `LeaveFilterChip`), month picker (2000–2200, All months, Cancel), rows with window,
     `(ມື້ຖັດໄປ)`, pill, `ຈາກປະກາດ` / `ບໍ່ໄດ້ມາ` badges. Refusals (400/403/422) show their text, no Retry; else
     `otListLoadFailed` with Retry. Tile `ໂອທີ` after leave history in `list_menu_entries.dart`,
     `Icons.work_history_outlined` (list tab and home menu; home test now counts 8).
   Open after #29, none built there:
   - rows are built all at once (as the leave history, #18): a lazy list for both is a follow-up;
   - a page whose rows are all unreadable ends the list early;
   - no reload when the App resumes or the day changes;
   - month names copied into `ot_copy.dart` (salary and attendance each have their own); a shared helper is a
     clean-up;
   - `LeaveFilterChip` is imported from time_off; moving it to `core/widgets` is a clean-up.

   **#28 (work order 27 of 60), "overtime: OT calls, error codes and Lao text": MERGED (`c8ccd35`), 2026-11-17.**
   Owner said go on 2026-11-17. Branch `28-overtime-calls`: `09944a4` (feature), `7dbfb73` (review fixes). Gates:
   analyze 1 warning already on `main`; `flutter test` 1,459 passed; debug APK builds. Merged on the owner's "push
   issue 28 to main directly"; gates green on the merge commit.
   - `OtPaths`, `OtRemoteDataSource` (7 calls), `OtErrorCode` (14 OT codes + `STEP_CHANGED` + `NOT_APPROVER` →
     tokens; `FORBIDDEN` on cancel only), `OtRepository` (`Result`), 7 use cases, `overtime_providers.dart`,
     localizer cases and 15 new strings (`NOT_APPROVER` reuses `leaveNotApprover`).
   - Body: `work_date` YYYY-MM-DD, times as given, `reason` trimmed / left out when empty. `status` only the four
     values; `month` YYYY-MM. Lists: `OtPage {items, page, totalPages}` from `meta` (page-based), a page number that
     is missing falls back to the page asked for, bad rows skipped.
   - Codes mapped only on 400/403/409 and keep the wire code; 404 keeps status, 422 its field, `EMPLOYEE_NOT_FOUND`
     #4's text, an unknown code the server's message. 403 `NOT_APPROVER`/`FORBIDDEN` never signs out (tested through
     the real `AuthInterceptor`). Empty, `.` and `..` ids refused before any request.
   Open after #28, none built there:
   - the `FORBIDDEN`-on-cancel question above;
   - an unknown 409 reaches screens as `Failure.network(statusCode: 409)` (the existing mapper): OT screens must
     check the status, not read every network failure as "no signal";
   - the English for `NOT_APPROVER` is leave's "You can't approve this step." (issue: "You cannot …"); Lao identical;
   - `_isoDate` sends a `DateTime`'s own calendar day (a UTC `DateTime` would send its UTC day); pickers give local
     days.

   **#27 (work order 26 of 60), "overtime: OT types and JSON reading (no screen yet)": MERGED (`9a871bb`), 2026-11-17.**
   Owner said go on 2026-11-17. Branch `27-overtime-models`: `ef5fe9c` (feature), `5ff8a06` (review fixes). Gates:
   analyze 1 warning already on `main`; `flutter test` 1,416 passed; debug APK builds. Merged on the owner's "push
   issue 27 to main directly"; gates green on the merge commit.
   - `lib/features/overtime/`: entities `OtRequest` (`OtStatus`, `pendingStep`, `hasApprovedStep`), `OtStep`,
     `OtPiece` (core `OtPayType`, `payValue` null when not a whole number), `OtPost` (`OtPostStatus`, `joined`,
     `hasSeatLimit`), `OtDraft`; hand-written models; `ot_parse.dart` (`instant` RFC 3339, `wallClock` no-zone Lao
     time read as phone-local, `date`; impossible days and times are null; nothing throws). A request or post with no
     id is refused; `tryFromJson` returns null for a list (#28) to skip the row.
   - Test JSON built from the issue's field tables (the guide's 1.3 / 1.5 JSON is in the private backend repo). To
     check one real request and post from `nexton-demo` against it.
   Open after #27, none built there:
   - the two clocks (see "Waiting for the owner"); a DST phone also shifts a wall time in its spring-forward gap;
   - `seats` of the wrong type reads as null, i.e. "no limit"; 0 and negatives are kept as sent (the server's `full`
     decides);
   - `pendingStep` takes the first pending step in list order, not checked against `currentStepNo` (0 when missing);
   - an `instant` with no offset is read as phone-local, not +07; a `work_date` sent as a UTC stamp keeps its UTC date.

   **#26 (work order 25 of 60), "payslip: the summary card shows the latest payslip": MERGED (`8cc530a`), 2026-11-17.**
   Owner said go on 2026-11-17. Branch `26-latest-payslip-card`: `5e51952` (feature), `7036c8b` (review fixes).
   Gates: analyze 1 warning already on `main`; `flutter test` 1,368 passed; debug APK builds. Merged on the owner's
   "push issue 26 to main directly"; gates green on the merge commit.
   - `GET /payroll/payslips/my/latest` → `PayslipLatest` (strict: whole kip, month 1-12, an id); `data: null` or no
     `data` → null, checked before `unwrapObject`. Asked for once when the page opens; a year or chip switch keeps the
     card and sends nothing; Retry asks for both; a failed Retry keeps a card that is showing.
   - Card: `ເງິນເດືອນສຸດທິ • ທັນວາ 2026` (from month/year), net pay, `ລາຍຮັບລວມ … · ຫັກລວມ …` (existing labels, no
     new string); no name line or pill (removed: `identityLine`, the page's `_StatusPill`); shimmer while loading;
     nothing on null or any error. Tap opens the payslip. Home screen unchanged.
   - Generated: only `salary_history_state.freezed.dart` committed; `build_runner` with the local Flutter rewrote 12
     others, restored.
   Open after #26, none built there:
   - product question above (card lost to one failed request, no way back on the page);
   - a double tap on the card opens the payslip twice (as the list rows, since #21); no tap feedback;
   - the page's year and the card are fixed when it opens: left open over New Year, neither refreshes;
   - on a narrow phone at a large text size, an eight-digit net pay (one line, 32 pt) may be cut with "…"; to check
     on the phone;
   - Retry tapped quickly sends one request per tap (the newest answer wins);
   - `SalaryHistoryState.all` is now used only by `filtered` and tests.

   **#25 (work order 24 of 60), "payslip: open the PDF in the App and share it": MERGED (`9515eee`), 2026-11-17.**

   **#25 (work order 24 of 60), "payslip: open the PDF in the App and share it": MERGED (`9515eee`), 2026-11-17.**
   Owner said go and approved the packages on 2026-11-17. Branch `25-payslip-pdf-viewer`: `de4324b` (feature),
   `1a59b20` (review fixes). Gates: analyze 1 warning already on `main`; `flutter test` 1,340 passed; debug APK builds.
   Merged on the owner's "push issue 25 to main directly"; gates green on the merge commit (1,340 tests).
   - Packages: `share_plus ^12.0.2` (not 13: 13 needs `win32` 6, `file_picker` 11 allows only 5), `pdfx ^2.11.0`,
     `path_provider ^2.1.5` (was transitive at 2.1.5). The lock only gains the new packages.
   - Both PDF buttons open `/salary-history/payslip/:id/pdf`: the PDF in the App (pdfx), Share (share_plus, iPad
     origin). 404 "not available", no Retry; no payroll its text, no Retry; offline and 500 "could not make the PDF"
     with Retry. One request per payslip; a double tap opens one page; the temp file (own folder per open, server's
     name made safe, max 100 chars) is deleted on close, also mid-load; leftovers of a killed App and Android's
     share_plus copies of payslips are cleared at the next open. Save-as (`PayslipPdfSaver`) and `salaryPdfSaved`
     removed; `file_picker` stays (leave attachments).
   - Core: `ApiError.tryParse` reads a JSON error that came as bytes, and no longer throws on a non-text code. Before
     it, a 403 `TENANT_INACTIVE` on the PDF call did not end the session (test added, red before).
   - Reviews (issues/rules/perf, adversarial) fixed: pdfx document never closed (file stayed open on disk); Android
     share copies left; a failed write left its folder; long names failed every Retry; Share twice opened two sheets.
   Open after #25, none built there:
   - phone check on `nexton-demo`, Android and iOS: the PDF opens with Lao readable; Share offers
     `payslip-<number>-YYYY-MM.pdf`; the iOS build has not been run here (plugins need iOS 13; the App targets 15);
   - leaving mid-load does not cancel the download (no `CancelToken`); the file is written and deleted at once;
   - a file left by a killed App stays in temp until the next PDF open (no clean-up at App start);
   - `filename*=UTF-8''…` and non-ASCII names are not decoded (server sends ASCII); odd characters become `_`;
   - a 200 that is not a PDF, or a 403 other than `MODULE_NOT_ACTIVE`, shows "could not make" with Retry (the salary
     list treats a refusal as final);
   - the issue's `content-type` check is the `%PDF` magic-bytes check instead.

   **#24 (work order 23 of 60), "payslip: tap the OT line to see what each OT paid": MERGED (`2d744c4`), 2026-11-17.**

   **#24 (work order 23 of 60), "payslip: tap the OT line to see what each OT paid": MERGED (`2d744c4`), 2026-11-17.**
   Owner said go on 2026-11-17. Branch `24-payslip-ot-items`: `0e0962b` (feature), `1d51810` (review fixes). Gates:
   analyze 1 warning already on `main`; `flutter test` 1,284 passed; debug APK builds. Two reviews (issues/rules/perf,
   adversarial) found no bugs; fixed: `OtPayType` moved to pure `core/utils/ot_pay_type.dart` (the entity had pulled
   Flutter into the domain through the l10n import); the "not paid" note needs 0 minutes **and** 0 amount; only the
   OT earning line opens the sheet. Merged on the owner's "push issue 24 to main directly"; gates green on the merge commit.
   Differences from the plan as shown: the enum is core's `OtPayType` (entity keeps `PayslipOvertimePayType` as a
   typedef) so core does not import a feature; one extra string `payslipOtTotal` ("Total" / "ລວມ").
   Open after #24, none built there:
   - phone check on `nexton-demo` (pieces match the web portal's payslip): pending;
   - two OT lines on one payslip (the server writes one): each would open all pieces with its own amount as total;
   - the sheet copies the pieces when opened; a reload while it is open shows only after reopening;
   - a window across midnight shows "22:00–02:00" beside one date; the date is `work_date` (no zone) while the window
     is `toLocal()`, so a phone outside +07:00 may show a window that looks like the day before (the issue asks for
     `toLocal()`);
   - negative `paid_minutes` (not sent) shows "-30 min" with no note; huge minutes are not digit-grouped;
   - `otPayLabel` takes `OtPayType`, not the issue's `String`: #30 calls `OtPayType.fromWire` first.
   The plan as shown on 2026-11-16, kept for the record:
   - Goal: tapping the OT line on a payslip opens a sheet with each OT piece: date, time window, pay, paid time,
     amount. No new call: the pieces are `overtime_items`, which #20 already reads.
   - New `lib/core/utils/ot_pay.dart`: `otPayLabel` ("150%", "20,000 ກີບ/ຊມ" / "20,000 kip/h", an unknown type
     gives the number). Shared with #30 later. Choice: it takes #20's `PayslipOvertimePayType` enum, not the
     issue's `String payType`.
   - New `presentation/widgets/payslip_ot_items_sheet.dart`: title "ລາຍລະອຽດໂອທີ" / "OT details"; one row per
     piece; a piece of zero paid minutes still shows ("0 ນາທີ", "0") with a grey note; the footer is the OT line's
     own amount, not a sum.
   - `payslip_detail_page.dart`: the row with code `OT` is tappable, with a chevron, only when there are pieces.
   - Strings in both arb files (prefix `payslipOt…`), then `flutter gen-l10n`.
   - Tests: new `test/core/utils/ot_pay_test.dart`; new `payslip_ot_items_sheet_test.dart` (rows, the zero row
     and its note, the total is the line's amount, a piece dated the month before, no pieces means not tappable).
   - Branch name planned: `24-payslip-ot-items`, from fresh `origin/main`, after the owner's "go".
   After #24 the order continues with #25 (the PDF in the App and Share), #26, then overtime from #27.

   #23 is merged.
   #23 moves the payslip page onto #22's functions, so #22 is done on screen once #23 is merged.
   Open after #23, none built there:
   - the page does not refresh once loaded: an approved payslip left open does not turn to paid or failed until
     it is reopened (before #23 it had a refresh). A pull to refresh is a small follow-up;
   - a deductions total or a deduction line below zero (not something the server sends) is shown as the number
     it is; "-5,000" then reads the same for +5,000 and -5,000 on the totals strip;
   - "paid on" is shown whenever `paid_at` is set, also beside an "Approved" pill; the backend says `paid_at` is
     null until the run is paid;
   - the English "could not load" text is still "Unable to load the payslip." (the issue says "Could not load the
     payslip."); the Lao is as the issue has it;
   - a benefit with an empty name shows as a row with no title;
   - nothing checks the page at phone width: the tests use a wide surface because the test font is far wider
     than a real one. To look at on a narrow phone, with the long Lao titles;
   - a payslip with thousands of lines builds them all at once (not a lazy list); real payslips have a dozen.
   Open after #22, none built there:
   - #22 is done at function level only. The issue's comment asks to move the payslip page's grouping, titles
     and captions onto the new functions ("one place, not two"); that page still reads the old `Payslip` entity,
     so the move is left to #23. Until then the page still shows "LATE · 86 ນາທີ" (code, no h + min), the bare
     code at zero, ຄັ້ງ / ມື້, no Lao title for OT, MISSED-PART, UNPAID-LEAVE, ATT-SETTLE and LOAN, and loans
     under "by law / other". Do not close #22 until #23 has moved the page;
   - #23 must also: show `PayslipSections.unplaced` (lines whose type the App does not know) or they vanish from
     the page; retire the old `salaryUnit*`, `salaryComponent*` and section keys, two of which now have the same
     Lao text as new keys;
   - the reused keys read "Base Salary", "Social Security", "Income Tax" and "Income" in English; the issue's
     table says "Basic salary", "Social security", "Income tax", "Earnings". Lao is as the issue has it;
   - English captions read "1 times", "1 days", "1 hours": that is the issue's table. Lao is not affected;
   - category, code and unit are matched exactly as the server writes them (`penalty`, `LATE`, `minutes`); another
     case or a space would put a line in "other deductions" or show the server's name. To confirm with the backend;
   - a count is shown to two decimal places at most (0.125 days reads 0.13).
   #23 is still on the owner's BLOCKED list; its backend dependency is the same one #21 had, now live.
   Open after #21, none built there:
   - product question for the owner: the Paid chip goes by the run's status, as the issue says, so a paid run
     whose payment failed is listed under Paid (with the red "Payment failed" pill). Should Paid leave it out?
   - the payslip page's header (month, paid date, status, PDF name) now comes from the list's row; its sections
     still come from the old `Payslip` entity until #23. A failed payment has the red pill there but no
     "contact HR" line (that line is on the list's open row);
   - the string `salaryFilterPending` ("Pending") is still in the arb files: the old entity's status label uses
     it when the payslip page is opened without a list row (no caller does). #23 removes it;
   - the list trusts the server's order (newest pay month first, per the backend's comment); if the server ever
     sent another order the summary card would show the wrong month as the latest;
   - one payslip the strict reader refuses fails the whole year (see #20);
   - a 401 or another 403 shows "could not load" with a Retry that cannot help;
   - a double tap on a row opens the payslip page twice (as before #21);
   - #72 (salary list stops at 10): the list now asks for one page of 100, so this is fixed on screen once #21
     is merged. To confirm on `nexton-demo` with a login that has more than 10 payslips in a year, then close #72;
   - not seen on a phone: the long Lao pill "ໂອນເງິນບໍ່ສຳເລັດ" beside the amount on a narrow screen.
   Open after #20, none built there:
   - the reader has not met a real payslip: no `nexton-demo` login here, so the test JSON is the confirmed list row
     already in `salary_api_test.dart` plus the issue's field table. Check one real list row and one real detail
     body (with overtime) against it. The reader is strict: a money field that is missing, text, or not whole kip
     fails the payslip (for a list, the whole year) instead of showing a wrong figure;
   - to confirm with the backend: a year with no payslips answers `"data": []`, not a missing or null `data`
     (that would show as an error, as it does for the old list call);
   - a refused payslip carries an English reason and no code (`A payslip without an id`, `... is not whole kip`).
     #21 and #23 must show their own text for it, not this one;
   - `paid_at` is read with `DateTime.tryParse`, which turns an impossible date (30 February) into a real one and
     reads a time with no offset as the phone's; the server sends RFC 3339 with an offset;
   - nothing uses the new calls yet: the two salary pages still read the old `Payslip` (month from `created_at`,
     money as `double`, `failed` shown as pending) until #21 and #23. #72 (list stops at 10) is fixed for the
     screens only when #21 moves them to `myPayslips`.
   Open after #19, none built there:
   - product question for the owner: "what I decided" sits under the waiting list in one scroll, so an approver
     with a long queue must scroll past every waiting request (loading each page) to reach it. With 140 waiting
     that is seven pages. A tab or a jump link would fix it; the issue asks for one scroll;
   - past 99 the tab's badge says "99+" and the header says "100+"; kept, as a longer badge runs over the next tab;
   - every loaded card is rebuilt when either list changes (not a lazy list), as in the history (#18);
   - if the session ends while the Approvals page is open, the lists are asked for once more with no token before
     the page closes (two refused requests, nothing shown);
   - rows are not de-duplicated by id.
   Open after #18, none built there:
   - the history's cards are one `Column` in a `ListView`, so every loaded card is rebuilt when a page is added.
     Fine at a few pages; a lazy list is a follow-up, before the later lists copy the pattern;
   - the tab listens to its `ScrollController`, not a `NotificationListener` as the issue names; same behaviour.
     #19 and later lists should copy the tab;
   - rows are not de-duplicated by id; to look at on the phone check with more than 20 requests;
   - `CursorPage.fromBody` reads `meta.has_more` only as a real `true` and `next_cursor` only as text; a server
     that sends them otherwise ends the list early with no sign.
   Open after #17, none built there:
   - the request page offers Edit and Cancel by status and date only: `LeaveRequest` has no owner field, so an
     approver or HR opening someone else's request by id (a push, #53) would see them. The server refuses; the
     App should hide them. To settle before #53;
   - "today" for the cancel rule is the phone's date; the server uses the company's. Around midnight the server's
     `LEAVE_ALREADY_STARTED` decides, and the page then reloads;
   - the "not available" state has no button of its own; the page's back arrow is the way out (no Back string
     exists yet);
   - the decision time under a timeline step is one line at 10 px; with four nodes on a 320 dp phone it may be
     cut short. To look at on a small phone;
   - an edit draft left without saving is kept while the request itself has not changed (as before #17);
   - the history notifier's own `cancel` is no longer called by any screen (the request page cancels through its
     by-id provider); it is still tested. To remove in a clean-up issue;
   - Cancel does not appear or disappear by itself when the day changes while the page is open.
   Open after #16, none built there:
   - an edit answered `NOT_FOUND` always reads "request gone" and closes the page, as the issue says; to confirm
     with the backend that an edit never answers `NOT_FOUND` about something else (a leave type);
   - the codes of phoudssp/Nexton-Backend#192 (`LEAVE_SPAN_TOO_LONG` and the rest) are not mapped; they show the
     server's English message until that is merged, then a small follow-up maps them;
   - a file attached during an edit that was refused as out of date is still attached at the next edit;
   - the strings `leaveStepRefreshed` and `leaveRequestCancelFailed` are no longer used and are still in the arb
     files;
   - reloading the history after an edit resets its filter and month (already so for a successful edit);
   - the detail page's cancel flow has no widget test (the notifier behind it has).
   Open after #15, none built there:
   - the shape of `GET /core_hr/rest-days` (rows, `meta.total_pages`) is from the issue text only; the backend repo
     is private. A rest-day row with a value the App cannot read is left out without a warning;
   - while the days off are still loading (not failed), the separate-days calendar offers every day and shows no
     warning; a day off picked then stays in the list with no mark and is charged;
   - with the days off unknown, the default return date is the next day, which may be a day off, and is sent;
   - which year's balance a range across a year end is charged to: the App uses the first charged day; to confirm
     with the backend whether it uses that or `start_date`;
   - public holidays are not skipped (the issue says so);
   - already on main before #15: two `submit()` calls in the same frame send two requests, and the form's draft
     (type, dates, reason) survives a sign-out. Each needs its own issue.
   To confirm with the backend team for #14: a leave type with no balance row for a year is shown as 0 and blocked,
   as the issue specifies. If the server creates next year's rows late, nobody could ask for January leave in
   December from the App.
   Not built in #14: the leave screens have no pull to refresh, so a type HR switches off disappears only when the
   type list is next loaded.
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

The owner's list of 2026-11-13: not to be built until the backend team confirms. State on 2026-11-16:

| Issue | Waits for | Latest word on the issue | State |
|---|---|---|---|
| #21, #23 | the payslip month (phoudssp/Nexton-Backend#191) | "Now live", 13 Nov 12:03 UTC | built and merged on the owner's "go" |
| #35 | OT hours on the summary and history | no "live" comment; the one comment (13 Nov) still says to wait; re-checked 2026-11-17 when the order reached it | **BLOCKED** (skipped; #36 next) |
| #55 | the unread count (phoudssp/Nexton-Backend#190) | no "live" comment; the one comment (13 Nov) says it still waits | **BLOCKED** |
| #56 | sign-out ends the session (phoudssp/Nexton-Backend#189) | "Now live", 15 Nov 13:27 UTC: `POST /api/v1/auth/logout`, body `{"refresh_token"}`, always `204` | live on the backend; **still on the owner's list until the owner says go** |

When the work order reaches a blocked issue: read its comments again, record it as BLOCKED if nothing has
changed, and move to the next one. The backend repo is private, so the issue's comments are the only source.

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
| 12 | #13 | leave: tests for what works today, and drop the old guide copy | `13-leave-tests` | `debd358` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 726 passed, 0 failed; debug APK builds; tests only, no app behaviour changed | MERGED |
| 13 | #14 | leave: the form offers only active types and checks the balance the server will charge | `14-leave-form-active-types-balance` | `fbae4aa` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 776 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 14 | #15 | leave: company days off are skipped, not charged | `15-leave-days-off` | `c9b73ee`, `8845610` | merged to main directly (`a103fc4`) | analyze clean, 854 tests, debug APK | MERGED — phone check on `nexton-demo` pending |
| 15 | #16 | leave: refusals show Lao text and the screen reloads | `16-leave-refusals-reload` | `9d8f1f8`, `d60a2c2` | merged to main directly (`6889f2a`) | analyze clean, 890 tests, debug APK | MERGED — two-login check on `nexton-demo` pending |
| 16 | #17 | leave: the request page opens by id, stays fresh, and shows a cancelled request plainly | `17-leave-request-by-id` | `5eb5e50`, `77395b8` | merged to main directly (`4920c50`) | analyze clean, 970 tests, debug APK | MERGED — phone check on `nexton-demo` pending |
| 17 | #18 | lists: load more as you scroll (leave history first) | `18-lists-load-more` | `a4cf8ad`, `e5b7b5e` | merged to main directly (`65b81bf`) | analyze clean, 1,015 tests, debug APK | MERGED — phone check on `nexton-demo` pending |
| 18 | #19 | approvals: leave lists keep what I decided, hide buttons on my own request, and load more | `19-approvals-decided-own-load-more` | `88c9004`, `47d9f67` | merged to main directly (`4327616`) | analyze clean, 1,046 tests, debug APK | MERGED — two-login check on `nexton-demo` pending |
| 19 | #20 | payslip: read real payslips from the server (data layer) | `20-payslip-data-layer` | `62302e6`, `dd7400d` | merged to main directly (`bc25ec2`) | analyze clean, 1,101 tests, debug APK | MERGED — a real `nexton-demo` payslip to be checked against the reader |
| 20 | #21 | payslip: the salary list shows real payslips, paid and failed | `21-salary-list-real-payslips` | `a8455eb`, `a6ed9fb` | merged to main directly (`cf7c936`) | analyze clean, 1,139 tests, debug APK | MERGED, phone check on `nexton-demo` pending — was on the owner's BLOCKED list; built after the backend's "now live" comment (13 Nov) and the owner's go |
| 21 | #22 | payslip: name, group and caption every payslip line | `22-payslip-line-names` | `123e7d3`, `c8626d5` | merged to main directly (`e9496d6`) | analyze clean, 1,225 tests, debug APK | MERGED — functions and strings only; no screen uses them until #23 |
| 22 | #23 | payslip: the payslip page opens by id and shows the real lines | `23-payslip-page-by-id` | `61e9f13`, `5c3f1b5` | merged to main directly (`b55b1ed`) | analyze clean, 1,261 tests, debug APK | MERGED, phone check on `nexton-demo` pending — was on the owner's BLOCKED list; built after the backend's "now live" comment (13 Nov) and the owner's go |
| 23 | #24 | payslip: tap the OT line to see what each OT paid | `24-payslip-ot-items` | `0e0962b`, `1d51810` | merged to main directly (`2d744c4`) | analyze: 1 warning already on `main`; `flutter test`: 1,284 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 24 | #25 | payslip: open the PDF in the App and share it | `25-payslip-pdf-viewer` | `de4324b`, `1a59b20` | merged to main directly (`9515eee`) | analyze: 1 warning already on `main`; `flutter test`: 1,340 passed, 0 failed; debug APK builds | MERGED, phone check (Android and iOS) on `nexton-demo` pending |
| 25 | #26 | payslip: the summary card shows the latest payslip | `26-latest-payslip-card` | `5e51952`, `7036c8b` | merged to main directly (`8cc530a`) | analyze: 1 warning already on `main`; `flutter test`: 1,368 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 26 | #27 | overtime: OT types and JSON reading (no screen yet) | `27-overtime-models` | `ef5fe9c`, `5ff8a06` | merged to main directly (`9a871bb`) | analyze: 1 warning already on `main`; `flutter test`: 1,416 passed, 0 failed; debug APK builds | MERGED, a real `nexton-demo` request and post to be checked against the reader |
| 27 | #28 | overtime: OT calls, error codes and Lao text | `28-overtime-calls` | `09944a4`, `7dbfb73` | merged to main directly (`c8ccd35`) | analyze: 1 warning already on `main`; `flutter test`: 1,459 passed, 0 failed; debug APK builds | MERGED |
| 28 | #29 | overtime: my OT list, on its own tile | `29-ot-list` | `3728c18`, `4615de2` | merged to main directly (`444929f`) | analyze: 1 warning already on `main`; `flutter test`: 1,513 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 29 | #30 | overtime: an OT request page that opens by id | `30-ot-request-page` | `d4e2f6f`, `0acf102` | merged to main directly (`41c604f`) | analyze: 1 warning already on `main`; `flutter test`: 1,552 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 30 | #31 | overtime: ask for OT | `31-ot-ask` | `c3659c1`, `fdc36ec` | merged to main directly (`446a272`) | analyze: 1 warning already on `main`; `flutter test`: 1,598 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 31 | #32 | overtime: edit or cancel my OT while it waits | `32-ot-edit-cancel` | `16d741e`, `eced537` | merged to main directly (`c8880d6`) | analyze: 1 warning already on `main`; `flutter test`: 1,636 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 32 | #33 | overtime: see HR's OT posts for my department and join one | `33-ot-posts` | `ceaf702`, `6b7cadf` | merged to main directly (`77db2c0`) | analyze: 1 warning already on `main`; `flutter test`: 1,670 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 33 | #34 | overtime: the clock button knows about an open OT session | `34-clock-open-ot` | `1c44232`, `5f53ffa` | merged to main directly (`55c41e7`) | analyze: 1 warning already on `main`; `flutter test`: 1,696 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 34 | #35 | attendance: show OT hours on the summary and history | | | | | BLOCKED: backend, OT hours (re-checked 2026-11-17, skipped) |
| 35 | #36 | approvals: one Approvals place, only for department heads and HR (leave moves in) | `36-approvals-heads-hr` | `d62a2bf`, `04b85ee` | merged to main directly (`4ad1873`) | analyze: 1 warning already on `main`; `flutter test`: 1,738 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 36 | #37 | approvals: open a leave request to see days, files, steps and notes before deciding | `37-leave-approval-detail` | `5fa7fba`, `55b7eeb`, `c67dced` | merged to main directly (`abfde43`) | analyze: 1 warning already on `main`; `flutter test`: 1,773 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 37 | #38 | photos: take a photo with the camera and upload it (shared) | `38-shared-upload` | `e2612f9`, `a498e41`, `a0c7ecd` | merged to main directly (`f3cdef7`) | analyze: 1 warning already on `main`; `flutter test`: 1,804 passed, 0 failed; debug APK builds | MERGED, phone check pending |
| 38 | #39 | leave: attach a photo when the type needs a file, and open attached files | `39-leave-files` | `d940f37`, `70da51a`, `6724eac` | merged to main directly (`35df673`) | analyze: 1 warning already on `main`; `flutter test`: 1,829 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 39 | #40 | attendance: after a clock-in or clock-out refused for the area, scan outside the area with a photo and reason | `40-offsite-after-refusal` | `90823eb`, `7b616b4` | merged to main directly (`01bf4be`) | analyze: 1 warning already on `main`; `flutter test`: 1,843 passed, 0 failed; debug APK builds | MERGED, phone check pending |
| 40 | #41 | attendance: the card shows a waiting off-site check-in, and clock-out goes as off-site too | `41-waiting-offsite` | `f6a1a8d`, `c45b99f` | merged to main directly (`a205629`) | analyze: 1 warning already on `main`; `flutter test`: 1,871 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 41 | #42 | attendance: my off-site requests — list, detail, cancel | `42-my-offsite-requests` | `47cc6b0`, `8733133` | merged to main directly (`2385f00`) | analyze: 1 warning already on `main`; `flutter test`: 1,892 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 42 | #43 | attendance: "forgot to scan" — rules and sending (no screen) | `43-correction-rules` | `3bb78d8`, `3bffdd0` | merged to main directly (`da3fda8`) | analyze: 1 warning already on `main`; `flutter test`: 1,921 passed, 0 failed; debug APK builds | MERGED |
| 43 | #44 | attendance: "forgot to scan" form, from a history day or the menu | `44-correction-form-entries` | `fdc11a7`, `a2ba160` | merged to main directly (`56b6c75`) | analyze: 1 warning already on `main`; `flutter test`: 1,944 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 44 | #45 | attendance: my "forgot to scan" requests — list, detail, cancel | `45-my-correction-requests` | `60fe12f`, `f0d87d0` | merged to main directly (`0aa9eb1`) | analyze: 1 warning already on `main`; `flutter test`: 1,987 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 45 | #46 | approvals: off-site scans for heads and HR | `46-offsite-approvals` | `9aa91f0`, `961cfb5` | merged to main directly (`afedb4f`) | analyze: 1 warning already on `main`; `flutter test`: 2,031 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 46 | #47 | approvals: "forgot to scan" requests for heads and HR | `47-correction-approvals` | `3192f3e`, `9a86936` | merged to main directly (`227a9b3`) | analyze: 1 warning already on `main`; `flutter test`: 2,067 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 47 | #48 | approvals: OT waiting and decided lists for heads | `48-ot-approvals-lists` | `11db106`, `e1cd94d` | merged to main directly (`fbeb16e`) | analyze: 1 warning already on `main`; `flutter test`: 2,089 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 48 | #49 | approvals: approve or reject OT, and cancel an approved OT before it starts | `49-ot-decisions` | `1110d2d`, `bbefe8b` | merged to main directly (`5960973`) | analyze: 1 warning already on `main`; `flutter test`: 2,118 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 49 | #50 | approvals: my team's leave and "forgot to scan" history (read-only) | `50-team-history` | `f00dd81`, `c02e491` | merged to main directly (`79a134a`) | analyze: 1 warning already on `main`; `flutter test`: 2,142 passed, 0 failed; debug APK builds | MERGED, phone check on `nexton-demo` pending |
| 50 | #51 | push: Firebase set up (app id next.on.hr.com) | `51-push-setup` | `d4a2b38`, `8f41b6d` | merged to main directly (`adad453`) | analyze: 1 warning already on `main`; `flutter test`: 2,150 passed, 0 failed; debug APK and iOS simulator build | MERGED, device checks pending |
| 51 | #52 | push: register this phone after sign-in, remove it before sign-out | `52-device-registration` | `1e4d192`, `91b31f7` | merged to main directly (`f0c7a6c`) | analyze: 1 warning already on `main`; `flutter test`: 2,177 passed, 0 failed; debug APK | MERGED, device checks pending |
| 52 | #53 | push: tapping a push opens the right screen | `53-push-open` | `9df2051`, `862cb98` | merged to main directly (`dcb056c`) | analyze: 1 warning already on `main`; `flutter test`: 2,226 passed, 0 failed; debug APK | MERGED, device checks pending |
| 53 | #54 | notifications: the bell shows recent pushes | `54-notifications-list` | `8ffe783`, `9678f08` | merged to main directly (`748e760`) | analyze: 1 warning already on `main`; `flutter test`: 2,267 passed, 0 failed; debug APK | MERGED, device checks pending |
| 54 | #55 | notifications: unread dots and a count on the bell | | | | | BLOCKED: backend, unread count |
| 55 | #56 | sign-in: signing out ends the session on the server | `56-server-logout` | `abba477`, `7564f53` | merged to main directly (`f3cb794`) | analyze: 1 warning already on `main`; `flutter test`: 2,283 passed, 0 failed; debug APK | MERGED, device checks pending |
| 56 | #57 | app: ask for an update when this version is too old, and show maintenance | `57-app-gate` | `d1a026a`, `5ccaa11` | merged to main directly (`cb69094`) | analyze: 1 warning already on `main`; `flutter test`: 2,320 passed, 0 failed; debug APK | MERGED, device checks pending |
| 57 | #58 | profile: see my personal information (read-only) | `58-personal-info` | `dff359e`, `1792a0c` | merged to main directly (`2c35513`) | analyze: 1 warning already on `main`; `flutter test`: 2,339 passed, 0 failed; debug APK | MERGED, device checks pending |
| 58 | #59 | profile: change my own photo | `59-profile-photo` | `13cb98c`, `371cea0` | merged to main directly (`08b8864`) | analyze: 1 warning already on `main`; `flutter test`: 2,368 passed, 0 failed; debug APK | MERGED, device checks pending |
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
| #68 | leave approvals: refresh when the leave was already decided (INVALID_STATUS) | likely covered by #16 (a stale refusal reloads both lists, then says why); to check on a phone, then close |
| #69 | leave cancel: refresh when the leave was already decided (INVALID_STATUS) | likely covered by #16 and #17 (the request page reloads in place); to check, then close |
| #70 | leave approve: show "not enough days left" on 422 INSUFFICIENT_BALANCE | likely covered by #16 (the approvals tab shows the code's own text); not checked against the issue line by line |
| #71 | push: sign the phone off on logout (shared phones get the last user's messages) | COVERED by #52, merged (`f0c7a6c`) |
| #72 | payslip: the salary list stops at 10 payslips a year | priority bug; fixed on screen by #21 (one page of 100); to confirm with a login that has more than 10 payslips in a year, then close |
| #73 | forgot to scan: a request with a photo is always refused (attachment_url must be a string) | NOT STARTED, priority bug. Root cause known: the request sends the whole upload object as `attachment_url`, not the URL string. Not scheduled |
| #75 | Docs: /auth/me employee_id now uses the own-record lookup (backend live 17 Nov) | NOT STARTED; docs only (`lib/features/auth/auth.md` lines 24 and 186); no code change |
| #74 | Leave edit: handle 409 LEAVE_CHANGED; type change now checked (backend #221) | its one to-do (map `LEAVE_CHANGED` on the edit call: refresh and say so) was built in #16; backend live 13 Nov 15:56 UTC; to check, then close |

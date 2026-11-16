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

1. #22 is built and pushed (`22-payslip-line-names`), waiting for the owner's say to merge. #23 is next in the
   work order and is on the owner's BLOCKED list; its backend dependency (the payslip month) is live since 13 Nov.
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
| 12 | #13 | leave: tests for what works today, and drop the old guide copy | `13-leave-tests` | `debd358` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 726 passed, 0 failed; debug APK builds; tests only, no app behaviour changed | MERGED |
| 13 | #14 | leave: the form offers only active types and checks the balance the server will charge | `14-leave-form-active-types-balance` | `fbae4aa` | none: pushed to `main` directly on the owner's say, 2026-11-16 | analyze: 1 warning already on `main`; `flutter test`: 776 passed, 0 failed; debug APK builds; not yet tried on a phone against `nexton-demo` | MERGED |
| 14 | #15 | leave: company days off are skipped, not charged | `15-leave-days-off` | `c9b73ee`, `8845610` | merged to main directly (`a103fc4`) | analyze clean, 854 tests, debug APK | MERGED — phone check on `nexton-demo` pending |
| 15 | #16 | leave: refusals show Lao text and the screen reloads | `16-leave-refusals-reload` | `9d8f1f8`, `d60a2c2` | merged to main directly (`6889f2a`) | analyze clean, 890 tests, debug APK | MERGED — two-login check on `nexton-demo` pending |
| 16 | #17 | leave: the request page opens by id, stays fresh, and shows a cancelled request plainly | `17-leave-request-by-id` | `5eb5e50`, `77395b8` | merged to main directly (`4920c50`) | analyze clean, 970 tests, debug APK | MERGED — phone check on `nexton-demo` pending |
| 17 | #18 | lists: load more as you scroll (leave history first) | `18-lists-load-more` | `a4cf8ad`, `e5b7b5e` | merged to main directly (`65b81bf`) | analyze clean, 1,015 tests, debug APK | MERGED — phone check on `nexton-demo` pending |
| 18 | #19 | approvals: leave lists keep what I decided, hide buttons on my own request, and load more | `19-approvals-decided-own-load-more` | `88c9004`, `47d9f67` | merged to main directly (`4327616`) | analyze clean, 1,046 tests, debug APK | MERGED — two-login check on `nexton-demo` pending |
| 19 | #20 | payslip: read real payslips from the server (data layer) | `20-payslip-data-layer` | `62302e6`, `dd7400d` | merged to main directly (`bc25ec2`) | analyze clean, 1,101 tests, debug APK | MERGED — a real `nexton-demo` payslip to be checked against the reader |
| 20 | #21 | payslip: the salary list shows real payslips, paid and failed | `21-salary-list-real-payslips` | `a8455eb`, `a6ed9fb` | merged to main directly (`cf7c936`) | analyze clean, 1,139 tests, debug APK | MERGED, phone check on `nexton-demo` pending — was on the owner's BLOCKED list; built after the backend's "now live" comment (13 Nov) and the owner's go |
| 21 | #22 | payslip: name, group and caption every payslip line | `22-payslip-line-names` | `123e7d3`, `c8626d5` | none yet: branch pushed, waiting for the owner's say to merge | analyze clean, 1,225 tests, debug APK | IN REVIEW — functions and strings only; no screen uses them until #23 |
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

# Work log

Day-by-day log of the Nexton App work items. Newest day at the bottom; append, never rewrite. The status of each
issue lives in `NEXT_ACTIONS.md` ("Work items"); the start-of-session checklist is `VERIFY_BEFORE_CONTINUING.md`.
All three files live on branch `docs/next-actions` only.

## 2026-11-16

Started the log on 2026-11-17; this day is summarised from `NEXT_ACTIONS.md`.

- Baseline and work orders 1 to 22 (#2 to #23) merged to `main`, each on its own branch with two reviews.
- Areas: app set-up (#2, #3), errors and sign-in (#4 to #6), attendance (#7 to #11), profile (#12), leave
  (#13 to #17), lists and approvals (#18, #19), payslip (#20 to #23).
- Tests: 369 (baseline) → 1,261. End of day `origin/main` = `b55b1ed`.

## 2026-11-17

**Completed:** work orders 23 to 43, that is #24 to #44 except #35 (BLOCKED: the backend's OT hours are not live;
re-checked, no "now live" comment). 20 issues, each merged to `main` on the owner's "push issue N to main directly".

| Issue | What | Merge |
|---|---|---|
| #24 | payslip: OT items sheet | `2d744c4` |
| #25 | payslip: the PDF in the App, with Share (`pdfx`, `share_plus` 12: owner-approved packages) | `9515eee` |
| #26 | payslip: the latest-payslip card | `8cc530a` |
| #27 | OT: models | `9a871bb` |
| #28 | OT: calls | `c8ccd35` |
| #29 | OT: the list | `444929f` |
| #30 | OT: the request page (owner: "fix first, then merge") | `41c604f` |
| #31 | OT: ask | `446a272` |
| #32 | OT: edit and cancel | `c8880d6` |
| #33 | OT: HR's posts, join | `77db2c0` |
| #34 | the clock button knows an open OT | `55c41e7` |
| #36 | Approvals only for department heads and HR | `4ad1873` |
| #37 | leave approval detail: Approve with note / Reject | `abfde43` |
| #38 | shared upload in `lib/core/upload/` | `f3cdef7` |
| #39 | leave: several files; files open in the App | `35df673` |
| #40 | off-site form only after a refused punch, camera only (owner: "keep the tile, open history") | `01bf4be` |
| #41 | the card sees a waiting off-site check-in | `a205629` |
| #42 | "My requests" with the off-site tab, paging, detail, cancel | `2385f00` |
| #43 | "forgot to scan": rules and sending (30-day look-back, window, overnight) | `da3fda8` |
| #44 | "forgot to scan" form filled from a history day (`?date=&part=`) | `56b6c75` |

**Verification:** for every issue, tests first where `CLAUDE.md` asks, then
`flutter analyze lib test && flutter test && flutter build apk --debug` on the branch and again on the merge
commit. Analyze keeps the one warning already on `main` (`_ShiftHoursLine`). Tests: 1,261 → 1,944, all passing at
`56b6c75`. Two fresh reviews per issue (issues/house rules/performance, and adversarial with probes); the real
findings were fixed in a follow-up commit, and each fix was mutation-checked (break the code, see a test fail).
No phone check on `nexton-demo` was possible from here; all are pending.

**Commits and push:** 43 non-merge commits and 20 merge commits on `main`, all pushed (`origin/main` = `56b6c75`).
Every issue branch is pushed and contained in `origin/main`. Merges were `--no-ff` with `Refs #N` (issues stay
open until their phone check). No force-push. `docs/next-actions` updated after each issue.

**Technical decisions worth remembering:**
- Upload code moved to `lib/core/upload/` (#38) and is shared by leave, off-site and "forgot to scan".
- Approvals are gated by `approver_access.dart` (#36).
- Correction rules live in the domain (`attendance/domain/correction_rules.dart`); refusals travel as encoded
  tokens (`token|v1|v2`) that the shared `failure_localizer` turns into Lao, without core importing a feature.
- Off-site after refusal only (#40); the "next punch" is decided in `domain/next_punch.dart` (#41).
- Lists page with the shared `PagedList`/`CursorPage` and load more on scroll (#42).
- `?date=` is parsed strictly; a form opened from a link goes home after sending (#44).

**Open at the end of the day:** the owner's questions in `NEXT_ACTIONS.md` "Waiting for the owner"; #73 priority
bug; phone checks for every issue. Next: #45, not started.

## 2026-11-18

**Completed:** work orders 44 to 60, that is #45 to #61 except #55 (BLOCKED: Nexton-Backend#190, the unread
count, not live). 16 issues, each merged to `main` on the owner's "push issue N to main directly".

| Issue | What | Merge |
|---|---|---|
| #45 | "My requests": "forgot to scan" tab, detail by id, cancel | `0aa9eb1` |
| #46 | approvals: off-site scans for heads and HR | `afedb4f` |
| #47 | approvals: "forgot to scan" for heads and HR | `227a9b3` |
| #48 | approvals: OT waiting and decided lists | `fbeb16e` |
| #49 | approvals: OT approve, reject, cancel before it starts | `5960973` |
| #50 | approvals: "My team" history, read-only | `79a134a` |
| #51 | push: Firebase set up, permission asked once | `adad453` |
| #52 | push: register the phone; sign it off before sign-out (covers #71) | `f0c7a6c` |
| #53 | push: a tapped push opens its item | `dcb056c` |
| #54 | notifications: the bell list | `748e760` |
| #56 | sign-in: sign-out ends the sign-in on the server (owner's go) | `f3cb794` |
| #57 | app: update needed / maintenance (`package_info_plus`, `url_launcher`: owner-approved) | `cb69094` |
| #58 | profile: personal info, read-only | `2c35513` |
| #59 | profile: change my own photo | `08b8864` |
| #60 | sign-in: forgot password says ask HR; remember my email | `1ffb410` |
| #61 | app: hide what the company has not bought | `4d3161c` |

**Verification:** as on 2026-11-17, for every issue: tests first, gates on the branch and on the merge commit
(analyze keeps the one old warning), two fresh reviews (one adversarial, with probes), the real findings fixed in
a follow-up commit and mutation-checked. Tests: 1,944 → 2,398, all passing at `4d3161c`. No phone check on
`nexton-demo` was possible from here; all are pending.

**Commits and push:** 32 non-merge commits and 16 merge commits on `main`, all pushed (`origin/main` = `4d3161c`).
Every issue branch is pushed and contained in `origin/main`. Merges were `--no-ff` with `Refs #N`. No force-push.
`docs/next-actions` updated after each issue.

**Technical decisions worth remembering:**
- The sign-off at sign-out runs through auth's `beforeSignOutProvider` hook, wired in `main.dart` (#52); its DELETE
  and the logout never start a token refresh (`noRefreshFlag`, path match), and a refresh answer for a sign-in that
  ended meanwhile writes and clears nothing (#56).
- Push routing is one table (`notifications/domain/push_route.dart`) and one opener (#53); the bell list reuses it
  (#54). Someone else's request hands over to the approver's page (`ApproverHandOver`, top page only, once).
- The auth interceptor's replay sends a fresh copy of a multipart form (`FormData.clone`, #59): fixes every upload
  after a token ran out.
- The real version lives in `core/app/app_version.dart`, set in `main.dart` (#57); the version gate sits before
  every session rule in `authRedirect`.
- Modules: pure rules in `core/modules/app_modules.dart`; the session-reading providers in the auth feature (#61).

**Open at the end of the day:** #35 and #55 (backend); the owner's questions in "Waiting for the owner"; #73
priority bug; phone checks for every issue; GitHub issues #2 to #61 still open. Next: #62, the "fixes" parent
tracker: a read-only check and the owner's call on closing its children (`NEXT_ACTIONS.md` "Next", item 1).

## 2026-11-19

**Checked at the start:** `main` = `origin/main` = `4d3161c`, clean, every issue branch in `main`; gates green on
`main` (analyze 1 old warning, 2,398 tests, debug APK). #62's body and comments unchanged since 13 Nov.

**#62 (read-only, no code):** all 18 children are in `main` and open on GitHub. #13 needs no phone and can close
now; the other 17 each still need their phone, two-login or web-portal boxes. Asked the owner: when to close, and
who closes. No answer yet.

**New from the backend since the last handoff (all 18 Nov):** #35 "Live now" (16:31 UTC, outcome A); #16: eight
leave rule codes live (`LEAVE_NOT_YET_AVAILABLE`, `LEAVE_NOTICE_TOO_SHORT`, `LEAVE_TOO_LONG` and the rest; the App
shows the server's English message, a follow-up to map them is proposed, not filed) and "leave type not found"
(`400 VALIDATION_ERROR`) asks for a reload of the type list (not found in the App; not traced in full); #53, #38,
#39, #59 guide fixes already match the merged code; #76 is a notice.

**#35:** built on the owner's "go" on `35-attendance-ot-hours` (`4ddf976`), two reviews, fixes in `8e4cce2`,
pushed. Gates: analyze 1 old warning, 2,407 tests passed, debug APK builds. Merged on the owner's "push issue 35 to
main directly": `5081e0a` (`--no-ff`, `Refs #35`), gates green on the merge commit, fast-forward push to `main`.

**Lesson:** do not run `dart format` on a folder here: `main` is not formatted to the tool's style and it rewrote
23 untouched files (restored before the commit). Leave formatting alone, or format only the lines changed.

**#73:** planned and built on the owner's "go" on `73-correction-photo-url` (`9fb5730`): the request sends the
photo's URL as text. One review; its test gap (the photo travelling from the form into the request) closed in
`e11571a`. Gates: analyze 1 old warning, 2,411 tests, debug APK. Merged on the owner's "push issue 73 to main
directly": `139f1c5` (`--no-ff`, `Refs #73`), gates green on the merge commit, fast-forward push. Open: what
`POST /uploads` returns as `url` on `nexton-demo`, since the detail page loads it as it is.

**#16 follow-up (leave rule refusals):** planned and built on the owner's "go" on `16-followup-leave-rule-refusals`
(`6bd2413`); two reviews; fixes in `af794bc`: the form no longer picks a type for the user after a refusal, a
failed type reload keeps the list, only the two type refusals reload, the texts reworded. Gates: analyze 1 old
warning, 2,452 tests, debug APK. Merged on the owner's "push the #16 follow-up to main directly": `2599166`
(`--no-ff`, `Refs #16`), gates green on the merge commit, fast-forward push.

**Lesson:** `build_runner` here rewrites every generated file in an older layout and reports SEVERE on files with
newer syntax (already so on `main`). Keep only the generated file of the class changed, run `dart format` on that
one file (the committed ones are formatted), and restore the rest.

**#75:** docs only, on `75-auth-me-employee-id-docs` (`d419130`), pushed; gates green. `auth.md` now gives the
server's new order for `employee_id` and says the App reads it. Found while checking: a `null` `employee_id` hides
the Approvals entry and the decision buttons. Merged on the owner's "push issue 75 to main directly": `2b2f5dc`
(`--no-ff`, `Refs #75`), gates green on the merge commit, fast-forward push.

**#55 re-checked** (end of day): still one comment, 13 Nov; no new comment on any issue since 18 Nov 17:00 UTC; no
issue newer than #76.

**#35, two decimals:** the owner chose two decimals so OT hours read as on the payslip. On
`35-ot-hours-two-decimals` (`7c2ead8`), pushed; gates green, 2,454 tests. Merged on the owner's say: `30dd634` (`--no-ff`, `Refs #35`), gates green on the
merge commit, fast-forward push. `main` = `origin/main` = `30dd634` at the end of the day.

**#35, Lao tile label:** the owner chose `ໂອທີ` for the home OT tile. Its own key (`attOvertimeTileLabel`), since
`salaryOvertimeLabel` is also the payslip's and the history row's. On `35-ot-tile-label-lao` (`a48d855`), pushed;
gates green, 2,454 tests. Not merged: waits for the owner's word.

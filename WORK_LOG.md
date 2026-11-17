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

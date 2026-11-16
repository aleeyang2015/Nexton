# Nexton App

Flutter phone App for the Nexton HR product: the employee and department-head side (clock in and out, leave, OT,
payslips, approvals).

## The three Nexton repos

| Repo | What | Runs at |
|------|------|---------|
| `Nexton` (`aleeyang2015/Nexton`) — this repo | Flutter phone App: staff and department heads | phones, calling the same API |
| `Nexton-Backend` (`phoudssp/Nexton-Backend`) | Go API + worker | `api.nexton.work`; a merge to `main` deploys and migrates |
| `nexton_web_admin` (`vongsavanh-dev/nexton_web_admin`) | Next.js HR web (the company portal) | `*.nexton.work`; a merge to `main` deploys |

What the server sends: the backend's handler or struct (the code wins over its docs); its guides are in
`docs/integration/`. Something the backend must add → an issue on `phoudssp/Nexton-Backend`. Staff ask here; HR
decides in the web.

## Working on an issue

How a change goes from a GitHub issue to a merged PR here. Scale it to the change: a typo, a one-line fix or a
docs edit goes straight to the gates and the PR.

1. **Read the issue to the end** (`gh issue view <n>`). Issues carry *Why*, *The API*, *Errors to handle*, *What to
   change* and *Done when*, with file:line refs; the "Work order" line says what lands first. The backend's App
   guides are in `Nexton-Backend/docs/integration/` (`*-flutter.md`, `attendance-self-service.md`,
   `backend-changes-for-frontend.md` Part 1; OT is `overtime-frontend.md` Parts 1 and 2).
   For anything about what the server sends, open its handler or struct. The code wins over the docs. Work bigger
   than a fix with no issue yet: write the issue first, in those five parts, and build once the lead agrees. The
   issue is the spec.
2. **Plan, then wait for a go.** Show the developer a short plan: the goal in one line, the files to touch, the tests
   to add, and each choice you made. Build after they say go. A product question (what users can or cannot do,
   money, what gets cut) goes to the lead as a comment on the issue; build the parts that do not depend on it.
3. **Branch from fresh `main`**: `git fetch && git switch -c <n>-<short-name> origin/main`. One issue per branch and
   per PR. Everyone builds from `main`, so it moves only through a reviewed PR.
4. **Test first where it matters**: sign-in, tokens and logout (`lib/core/network/`, `features/auth`; every
   provider that holds a user's data is `.autoDispose`, so logout drops it), clock-in and clock-out
   (`features/attendance`: the punch, its location, the mock-location check, and the refresh when the App comes
   back from the background or the day changes), asking for leave or OT, joining an OT post, and approving
   (`features/time_off` leave approvals for department heads, which has no tests yet: who sees which button, each
   status change), payslip money (`features/salary_history`), and push notifications, once they are added, with
   the screen each one opens. Write the test, see it go red for the right reason, then make it green. Everywhere
   else, add or update the test beside the code you change: tests go in `test/features/<feature>/`, and shared fakes
   live in `test/support/`.
5. **Build the smallest change** the issue asks for, following the project rules below. Every string a user sees
   goes in both `lib/l10n/app_en.arb` and `lib/l10n/app_lo.arb`; then run `flutter gen-l10n` and commit
   `lib/l10n/generated/` with it. After you change a `@freezed` or `@JsonSerializable` class, run
   `dart run build_runner build --delete-conflicting-outputs` and commit the generated files with it. Unrelated
   clean-ups get their own issue.
6. **Gates**, all green before a push. There is no CI yet, so you run them and put the result in the PR:
   ```sh
   flutter analyze && flutter test && flutter build apk --debug
   ```
   Use the team's Flutter version; the repo does not pin one, so ask the lead. If `flutter pub get` or
   `build_runner` rewrites `pubspec.lock` or generated files your change did not touch, your Flutter differs: match
   it, and never commit those rewrites. The Android build
   runs Gradle 8.12, which needs JDK 17 to 23; JDK 25 fails with nothing but the version number as its error.
7. **Try it on the test company `nexton-demo`**. The App talks to the **live** server, so clocking in, asking for
   leave or OT, approving and cancelling happen for real: do them on `nexton-demo` only, and open any other company
   to look only.
   ```sh
   flutter run --dart-define=NEXTON_API_BASE_URL=https://nexton-demo.nexton.work/api --dart-define=NEXTON_TENANT_SLUG=nexton-demo
   ```
   A plain `flutter run` points at `api.nexton.work`, which is not a company (`AppConstants.baseUrl`), and the live
   server ignores the `X-Tenant-Slug` header, so the company comes only from the host. Never test against
   `app.nexton.work`: it picks the company from the login, so a real company's login writes to that real company.
   Only the `nexton-demo.nexton.work` address keeps you on the test company. On an emulator, debug builds clock in
   from a fixed spot (`FixedPunchLocationSource`; move it with `NEXTON_DEBUG_PUNCH_LAT` and
   `NEXTON_DEBUG_PUNCH_LNG`). Department-head screens need a `nexton-demo` login that heads a department; ask the
   lead for one. Walk every *Done when* box; a change under `android/` or `ios/` is tried on that platform.
8. **Review with fresh eyes before the PR.** Start a subagent and give it the issue text and
   `git diff origin/main...HEAD`, never your plan. Three angles: **issues** (bugs, edge cases, what the server really
   sends), **house rules** (the project rules below, the arb files, committed generated code), **performance**
   (duplicate or waterfall requests, a provider that refetches on every rebuild, `ref.watch` on a whole object where
   `select` would do, work inside `build()`, a request per list row, a heavy new package). When the change touches the
   step 4 list, start a second subagent beside it, an **adversarial** one: same inputs, its only job is to break the
   change (wrong role, stale screen after the App resumes or the day rolls over, double tap on a punch or submit,
   server error mid-flow, no signal, token expiring mid-request, a new login seeing the last user's data, a money
   figure off by one). Check each finding against the code, fix the real ones in one pass, then re-run the gates.
9. **Open the PR** when the developer says so: `Fixes #<n>`, what changed in a few lines, the gate result, how it was
   tried (company, device, steps), and a screenshot for UI work. The lead reviews every PR before merge; answer each
   comment with a fix or a reason.

## Project rules

### Architecture

- Feature First
- Clean Architecture

Every feature contains

- presentation
- domain
- data

### State Management

Riverpod only

Use Notifier/AsyncNotifier

### Navigation

GoRouter

### Networking

Dio

### Rules

- Don't change architecture without approval.
- Don't introduce new packages unless requested.
- Reuse existing code whenever possible.
- Keep widgets small.
- No business logic inside widgets.
- Repository returns Result<T>.
- Always explain architectural decisions.
- Implement only the requested task.

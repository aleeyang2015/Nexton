# Verify before continuing

The checklist for the start of a work session on the Nexton App. Do it top to bottom before writing any code.
It takes a few minutes and stops the two expensive mistakes: redoing finished work, and building on a stale tree.

Written at the end of 2026-11-16; brought up to date at the end of 2026-11-17 (the checkpoint after #44) and at
the end of 2026-11-18 (the checkpoint after #61). The record of what is done is `NEXT_ACTIONS.md`, next to this
file on branch `docs/next-actions`, with `WORK_LOG.md` (the day-by-day log). None of the three is on `main`.

## Resume here (next session, after 2026-11-18)

1. Read the project rules: `CLAUDE.md` on `main`. There is no `PROJECT_RULES.md`; `CLAUDE.md` is the rules file.
2. Read this file, then `NEXT_ACTIONS.md` (both on `origin/docs/next-actions`).
3. Check the real Git and project state before changing anything (steps 3 to 5 below).
4. Confirm #61 is done: `git merge-base --is-ancestor origin/61-hide-unbought-modules origin/main && echo "in main"`.
5. Continue with **#62**. It is not a feature issue: it is the "fixes" parent tracker (children #2 to #19, and the
   60-item work order for all five trackers #62 to #66). Every child is merged on `main`, but every child is still
   **open** on GitHub (merges said `Refs #N`, not `Fixes #N`). The first step is in `NEXT_ACTIONS.md` "Next",
   item 1: a read-only check and a short plan for the owner. No code is expected for #62.
6. Follow the existing architecture, conventions and workflow; do not restart planning, regenerate these documents,
   or redo a MERGED issue.
7. Do not create a branch, close an issue, or change anything on GitHub until the owner says so. #62 needs no
   branch unless the owner asks for a code change.

### State at the end of 2026-11-18

| | |
|---|---|
| Branch checked out | `main` |
| `main` = `origin/main` | `4d3161c` "Merge branch '61-hide-unbought-modules' into main" |
| Working tree | clean: nothing modified, staged or untracked; no stashes |
| Unpushed commits | none, on any local branch (every branch equals its remote) |
| Last completed | #61 (merged on the owner's say; gates green on `4d3161c`: analyze 1 old warning, 2,398 tests passed, debug APK builds) |
| Done today | work orders 44 to 60: #45 to #61, but #55 (BLOCKED on Nexton-Backend#190) |
| Still blocked | #35 (Nexton-Backend#195, OT hours) and #55 (Nexton-Backend#190, unread count): the only two work orders not merged |
| Next | #62 (parent tracker): a read-only check and the owner's call on closing; no branch, no code |
| Phone checks | none done for any issue; all pending on `nexton-demo` |

Known risks to keep in mind:
- GitHub issues #2 to #61 are all open although merged; closing them is the owner's (it needs a login; the public
  API here can only read). Their phone checks are still pending, which is why they were left open.
- The owner's open questions in `NEXT_ACTIONS.md` "Waiting for the owner" are unanswered.
- #73 (a "forgot to scan" request with a photo is always refused) is a priority bug outside the work order.
- Follow-ups proposed today (none filed): see `NEXT_ACTIONS.md` "Next", item 2.

## Do not

- Do not restart project planning, and do not regenerate architecture documents.
- Do not redo an issue that `NEXT_ACTIONS.md` marks MERGED.
- Do not create a branch before steps 1 to 7 are done and the owner has said "go" to the plan.
- Do not force-push, reset a branch to an older commit, discard uncommitted work, or rewrite shared history.
- Do not merge or push to `main` without the owner's say for that issue.
- Do not build an issue on the blocked list until the owner says so (step 7).
- Do not test against `app.nexton.work`. Real actions go on `nexton-demo` only.

## 1. Read the project rules

`CLAUDE.md` at the repo root, on `main`: the three repos, "Working on an issue" (steps 1 to 9) and the project
rules (feature-first clean architecture, Riverpod, GoRouter, Dio, `Result<T>`, no new packages, strings in both
arb files).

## 2. Read the record

```sh
git fetch origin
git show origin/docs/next-actions:NEXT_ACTIONS.md | less
```

Read "Current status", "Waiting for the owner", "Confirmed decisions" and "Next". The first item under "Next"
names the issue to continue.

## 3. Check the working tree

```sh
git status -sb          # which branch; anything uncommitted, staged or untracked
git stash list          # expected: empty
git log --oneline -1    # where HEAD is
```

Expected at the start of the next session: on `main`, clean, no stashes. If anything is uncommitted, find out what
it is and keep it; do not discard it.

## 4. Fetch, and compare with the record

```sh
git fetch origin --prune
git log --oneline -1 origin/main
```

`NEXT_ACTIONS.md` says `origin/main` was `4d3161c` ("Merge branch '61-hide-unbought-modules' into main") at the
end of 2026-11-18.

- If `origin/main` is still `4d3161c`: nothing moved. Go on.
- If it has moved: someone merged since. Read `git log --oneline 4d3161c..origin/main` and work out what it
  changes for the next issue before planning it. Update local `main` with `git switch main && git merge --ff-only
  origin/main`. If it cannot fast-forward, stop and report.

## 5. Check the last merge really is there

For the last issue marked MERGED (work order 60, #61):

```sh
git merge-base --is-ancestor origin/61-hide-unbought-modules origin/main && echo "in main"
```

There are no pull requests for the work items: each was pushed to `main` as a merge commit on the owner's say, so
"merged" means "contained in `origin/main`". The GitHub issues stay open until their phone check. To see the state
of the issues and PRs (there is no `gh` here, and the GitHub connector has not been connecting):

```sh
curl -s "https://api.github.com/repos/aleeyang2015/Nexton/issues?state=all&per_page=100"
curl -s "https://api.github.com/repos/aleeyang2015/Nexton/pulls?state=all&per_page=100"
```

The public API allows about 60 requests an hour without a login. It can read; it cannot create a PR, comment or
close an issue. Those are the owner's to do, or need a login the owner provides.

## 6. Read the next issue, with its comments

The next issue is the first item under "Next" in `NEXT_ACTIONS.md` (at the time of writing: **#62, the "fixes"
parent tracker**; every work order is merged except #35 and #55, both blocked on the backend).

```sh
curl -s https://api.github.com/repos/aleeyang2015/Nexton/issues/62
curl -s https://api.github.com/repos/aleeyang2015/Nexton/issues/62/comments
```

Read the body to the end and every comment. A comment headed "Checked against branch `clock-in-out-location`"
wins over the body where they differ. A later "Now live" comment from the backend team is the only source for what
the server sends: the backend repo is private.

## 7. Check whether anything has changed

- Has the issue's body or its comments changed since the plan in `NEXT_ACTIONS.md` was written? If so, the plan
  there is out of date: say what changed and plan again.
- Is the issue on the blocked list ("Blocked on the backend" in `NEXT_ACTIONS.md`)? If so, read its comments for a
  "now live" from the backend. If there is none, record it as BLOCKED and take the next issue in the work order.
  If there is one, the issue is still on the owner's list: ask the owner before building it.
- Has the owner answered any of "Waiting for the owner"? An answer may change an issue already merged; that is a
  new, small piece of work with its own branch, not a reason to reopen the old one.
- New issues since #75? Read them; one may say an earlier issue's behaviour has changed on the server.

## 8. Continue from the first unfinished task

For the next issue, follow `CLAUDE.md` "Working on an issue":

1. Show the owner a short plan: the goal in one line, the files to touch, the tests to add, each choice made. If
   `NEXT_ACTIONS.md` already holds a plan that still matches the issue, show that one.
2. Wait for "go".
3. Only then branch from fresh `main`: `git fetch && git switch -c <n>-<short-name> origin/main`.
4. Tests first where it matters; the smallest change; strings in both arb files, then `flutter gen-l10n`; after a
   `@freezed` change, `dart run build_runner build --delete-conflicting-outputs`, and commit only the generated
   file the change touched (restore any other the tool rewrote).
5. Gates, all green: `flutter analyze lib test && flutter test && flutter build apk --debug`. One warning is
   already on `main` (`_ShiftHoursLine` unused); anything else is new.
6. Commit (`type(scope): sentence`, a body that says why, `Refs #<n>`, the co-author line), push the branch.
7. Two reviews with fresh eyes, given the issue text and `git diff origin/main...HEAD`: one for issues, house
   rules and performance; one adversarial. Check each finding against the code, fix the real ones, run the gates
   again, commit and push.
8. Update the issue's row and "Next" in `NEXT_ACTIONS.md` on `docs/next-actions`, and push that branch.
9. Report to the owner: what it does, what the reviews found, what is left open, the compare link. Then wait.
   Merge only when the owner says "push issue N to main directly": a merge commit with `Refs #N` on top of
   `origin/main`, the gates on that commit, then a fast-forward push to `main`.

One issue, one branch. Never start an issue on top of an unmerged one.

## What cannot be done from here

- Trying a change on a phone against `nexton-demo`: there is no test login in this environment. Every phone check
  is recorded as pending in `NEXT_ACTIONS.md`; never report one as done.
- Reading the backend's code: `phoudssp/Nexton-Backend` is private.
- Opening a pull request, commenting on an issue, closing an issue.

# Verify before continuing

The checklist for the start of a work session on the Nexton App. Do it top to bottom before writing any code.
It takes a few minutes and stops the two expensive mistakes: redoing finished work, and building on a stale tree.

Written at the end of 2026-11-16; brought up to date at the end of 2026-11-17 (the checkpoint after #44), at
the end of 2026-11-18 (the checkpoint after #61) and at the end of 2026-11-19 (after #35, #73, the #16 follow-up
and #75). The record of what is done is `NEXT_ACTIONS.md`, next to this
file on branch `docs/next-actions`, with `WORK_LOG.md` (the day-by-day log). None of the three is on `main`.

## Resume here (next session, after 2026-11-19)

1. Read the project rules: `CLAUDE.md` on `main`. There is no `PROJECT_RULES.md`; `CLAUDE.md` is the rules file.
2. Read this file, then `NEXT_ACTIONS.md` (both on `origin/docs/next-actions`; they are not in the working tree
   of `main`: read them with `git show origin/docs/next-actions:<file>`). The files of the same names under
   `../nexton_app_flutter/docs/handover/` belong to an older project and say nothing about this one.
3. Check the real Git and project state before changing anything (steps 3 to 5 below).
4. Confirm the last merge is there:
   `git merge-base --is-ancestor origin/70-approve-insufficient-balance origin/main && echo "in main"`.
5. **Nothing buildable is queued.** Every work order is merged except **#55** (unread dots and a count on the
   bell), which waits on Nexton-Backend#190. Start by re-reading the comments on #55 for a "now live", and by
   checking for issues newer than #76 and for new backend comments on any issue
   (`curl -s "https://api.github.com/repos/aleeyang2015/Nexton/issues/comments?since=2026-11-19T00:00:00Z&per_page=100&sort=updated"`).
   On 2026-11-19 exactly that check found #35 unblocked and new live rules on #16.
6. Then put the owner's open items in front of them (the list under the table below); each answer may become a
   small piece of work with its own branch.
7. Follow the existing architecture, conventions and workflow; do not restart planning, regenerate these documents,
   or redo a MERGED issue.
8. Do not create a branch, close an issue, or change anything on GitHub until the owner says so. For a new piece
   of work: show the plan, wait for "go", build on a branch, and merge only on "push issue N to main directly".

### State at the end of 2026-11-19

| | |
|---|---|
| Branch checked out | `main` |
| `main` = `origin/main` | `3daed16` "Merge branch '70-approve-insufficient-balance' into main" |
| Working tree | clean: nothing modified, staged or untracked; no stashes |
| Unpushed commits | none, on any local branch (every branch equals its remote) |
| Gates on `3daed16` | `flutter analyze lib test`: 1 warning, already on `main` (`_ShiftHoursLine` unused); `flutter test`: 2,459 passed, 0 failed; `flutter build apk --debug`: builds |
| Done on 2026-11-19 | #62 checked (read-only); #35 (`5081e0a`); #73 (`139f1c5`); the #16 follow-up, leave rule refusals in Lao, no issue of its own (`2599166`); #75, docs (`2b2f5dc`); #35's OT hours to two decimals (`30dd634`) and its Lao tile label `ໂອທີ` (`12b3019`), both the owner's calls; #70, the approver's "not enough days left" text (`3daed16`). Each merged on the owner's say |
| Still blocked | #55 (Nexton-Backend#190, unread count): the only work order not merged |
| Next | no code queued: re-check #55 and new backend comments, then the owner's open items below |
| Phone checks | none done for any issue; all pending on `nexton-demo` |

Waiting for the owner (asked on 2026-11-19, not answered):
- **#62's children (#2 to #19): ANSWERED** (owner, 2026-11-19): close #13 now, and the other 17 **after their
  phone checks**. **#13 is CLOSED** (2026-11-19, with a note naming its merge commit). The other 17 stay open until
  someone has walked their phone boxes on `nexton-demo`; the trackers #63 to #66 close when their children have.
- **#35 rounding: ANSWERED, two decimals** (owner, 2026-11-19): built and merged (`30dd634`). Nothing left.
- **#35 Lao tile label: ANSWERED, `ໂອທີ`** (owner, 2026-11-19): built and merged (`12b3019`). Nothing left.
- The older questions in `NEXT_ACTIONS.md` "Waiting for the owner".

Waiting for other people:
- **A native read of the Lao** written on 2026-11-19 (`lib/l10n/app_lo.arb`): the twelve `leaveRule…` strings and
  `leaveApprovalInsufficientBalance`.
- **Backend team or HR, asked on #75** (comment of 2026-11-19): is any login linked to its staff record only by
  the old `users.employee_id`? Since 17 Nov `/auth/me` answers `employee_id: null` for it, and the App then shows
  that login no Approvals entry and no Approve or Reject buttons (`ApproverAccess.canSeeApprovals`).
- **Backend team, asked on #16** (comment of 2026-11-19): a real code for "leave type not found" (the App tells it
  by its English message); what `requested_days` holds on `LEAVE_TOO_LONG` when days off join the run (the App
  does not show it).
- **Backend team, asked on #73** (comment of 2026-11-19): what `POST /uploads` returns as `url` (the App loads it
  as it is, so the photo shows only if the phone can reach it).
- Read the answers with `gh issue view <n> --comments`; an answer may become a small piece of work.

Known risks to keep in mind:
- GitHub issues #2 to #76 are open although their work is merged, except the eight closed on 2026-11-19 on the
  owner's say because no box of theirs needs a phone: #13, #22, #27, #28, #43, #68, #69, #70, #74 (each with a note naming
  its merge commit and tests) and #76 (a notice, closed as not planned). Every other issue closes on the owner's
  say, after its phone check.
- Left open on purpose although the work is merged: #75 (docs done, but the backend question sits on it), #71
  (covered by #52, whose phone check is pending), #20 (wants a real `nexton-demo` payslip).
- #70's review (after the merge) found no defect. Two points left for people: the Lao second sentence can be read
  as "have HR add days or reject" (for the native read), and the toast shows for 3 seconds like every other, which
  may be short for two sentences (the owner was asked: a longer time, a dialog, or wait for the phone check).
- In the trackers the boxes of the closed children are ticked (owner's say, 2026-11-19): #13 in #62, #22 in #63,
  #27 and #28 in #64, #43 in #65. Tick a box only when its issue is closed. (#68, #74 and #76 are in no tracker's
  list.)
- #35's phone check needs an approved, clocked OT on `nexton-demo` first: the backend says no company has one yet.
- Follow-ups proposed and not filed: see `NEXT_ACTIONS.md` "Next", item 2.

Two things about the tools here, learned on 2026-11-19:
- Do not run `dart format` on a folder: `main` is not formatted to the tool's style and it rewrites untouched
  files. Leave formatting alone.
- `dart run build_runner build` rewrites every generated file in an older layout and reports SEVERE on files with
  newer syntax (already so on `main`). Keep only the generated file of the class changed, run `dart format` on
  that one file, and restore the rest (`git checkout -- <paths>`).

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

`NEXT_ACTIONS.md` says `origin/main` was `3daed16` ("Merge branch '70-approve-insufficient-balance' into main") at
the end of 2026-11-19.

- If `origin/main` is still `3daed16`: nothing moved. Go on.
- If it has moved: someone merged since. Read `git log --oneline 3daed16..origin/main` and work out what it
  changes for the next issue before planning it. Update local `main` with `git switch main && git merge --ff-only
  origin/main`. If it cannot fast-forward, stop and report.

## 5. Check the last merge really is there

For the last one marked MERGED (#70):

```sh
git merge-base --is-ancestor origin/70-approve-insufficient-balance origin/main && echo "in main"
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

Since 2026-11-19 the GitHub CLI is installed and signed in as the owner (`gh`, scopes `repo`): `gh issue view <n>
--comments` reads without the hourly limit, and it can comment and close. Close or comment only when the owner has
said so for that issue.

## 6. Read the next issue, with its comments

The next issue is the first item under "Next" in `NEXT_ACTIONS.md` (at the time of writing there is
none to build: every work order is merged except #55, blocked on the backend; the example below reads #55).

```sh
curl -s https://api.github.com/repos/aleeyang2015/Nexton/issues/55
curl -s https://api.github.com/repos/aleeyang2015/Nexton/issues/55/comments
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
- New issues since #76? Read them; one may say an earlier issue's behaviour has changed on the server.

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

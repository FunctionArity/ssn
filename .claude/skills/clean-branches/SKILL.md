---
name: clean-branches
description: Delete local and remote (origin) git branches that are already merged into main, keeping main, the current work and anything with unmerged commits. Use when asked to clean up, prune or clear merged branches.
---

Delete every branch, local and on `origin`, whose work is already in `main`. Never delete anything that still has unmerged work.

1. Sync and get onto an up-to-date `main`:
   - `git fetch --prune origin`
   - If the working tree has uncommitted changes, stop and tell the user (switching branches could carry or lose them).
   - `git checkout main && git pull --ff-only`

2. Find the branches merged into `origin/main` (merge commits and fast-forwards):
   - Local: `git branch --merged origin/main` — exclude `main`.
   - Remote: `git branch -r --merged origin/main` — exclude `origin/main` and `origin/HEAD`.

3. Find branches merged with squash or rebase (their commits never appear in `main`, so step 2 misses them). For each remaining local branch, and each remaining `origin/*` branch:
   - Look up its PR: `gh pr list --head <branch> --state merged --json number,headRefOid --limit 1`
   - Treat it as merged only if a merged PR exists **and** its `headRefOid` equals the branch tip (`git rev-parse <branch>` or `git rev-parse origin/<branch>`). If the branch has commits added after the PR merged, keep it.

4. Never delete:
   - `main` or the current branch.
   - Branches with an open PR (`gh pr list --head <branch> --state open`), e.g. open dependabot branches.
   - Branches with commits not in `main` and no matching merged PR — list them with the reason (e.g. "2 commits not in main, PR #162 closed without merging").

5. Delete:
   - Local, merged via step 2: `git branch -d <branches…>` (refuses unmerged branches, which is the safety net).
   - Local, merged via step 3: `git branch -D <branches…>` (needed because squash/rebase commits differ; only for branches verified in step 3).
   - Remote: one call, `git push origin --delete <branches…>` (without the `origin/` prefix).

6. Verify with `git branch` and `git branch -r`, and report to the user:
   - Deleted locally and deleted on `origin` (separately).
   - Kept, with the reason for each.
   - Whether `main` is up to date with `origin/main`.
   If nothing was merged, say so and delete nothing.

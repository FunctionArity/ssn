Consolidate all currently open dependabot "Bump" pull requests into a single `bump-dependencies` branch and open one PR for it.

1. `git fetch --prune` to sync remote refs.

2. List open bump PRs targeting main:
   `gh pr list --search "in:title Bump" --state open --json number,title,headRefName,baseRefName --limit 100`
   If there are none, tell the user and stop.

3. From an up-to-date `main`, (re)create the branch:
   - `git checkout main && git pull --ff-only`
   - If a local `bump-dependencies` branch already exists, delete it first (`git branch -D bump-dependencies`) — it should not carry over old state.
   - `git checkout -b bump-dependencies`

4. For each PR's `headRefName`, merge it in one at a time:
   `git merge --no-edit origin/<headRefName>`

   If a merge conflicts (this project's lockfile conflicts are almost always in `Gemfile.lock` when multiple gem bumps touch overlapping transitive dependencies):
   - Resolve any real conflict markers by hand if needed (e.g. picking the newer version).
   - Regenerate the lockfile with `bundle lock --local` so all transitive versions are consistent, then `git add Gemfile.lock && git commit --no-edit` to complete the merge.
   - If a merge fails outright and can't be resolved this way, stop and tell the user which branch conflicted.

5. Verify consistency: run `bundle lock --local` again — it should produce no diff. Run `bundle install` to fetch the new gem versions locally.

6. Attempt the test suite (`/test` skill or `bundle exec rails test`). Report results honestly — if a failure is clearly pre-existing and unrelated to the bump (verify by reproducing it on `main`), say so explicitly rather than treating it as a blocker.

7. Push and open a PR:
   - `git push -u origin bump-dependencies`
   - `gh pr create --title "Bump dependencies" --body "..."` — list each consolidated PR (number + title) in the Summary, and note the lockfile was regenerated with `bundle lock --local`.

8. Return the PR URL to the user. Mention that the individual dependabot PRs can be closed once this one merges.

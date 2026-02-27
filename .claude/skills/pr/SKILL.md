Create a pull request from the current branch to main.

1. Run the following in parallel:
   - `git status` to see untracked/modified files
   - `git log main..HEAD --oneline` to see commits on this branch
   - `git diff main...HEAD` to understand all changes

2. Determine the current branch with `git branch --show-current`. If it is `main`, tell the user there is nothing to PR and stop.

3. Check whether the branch has a remote tracking ref with `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null`. If not, push with `git push -u origin HEAD`.

4. Analyse all commits and diffs, then draft:
   - A concise PR **title** (under 70 characters, imperative mood)
   - A **body** with:
     ## Summary
     - bullet points describing what changed and why

     ## Test plan
     - bulleted checklist of how to verify the changes

     🤖 Generated with [Claude Code](https://claude.com/claude-code)

5. Create the PR with:
   gh pr create --title "..." --body "..."

6. Return the PR URL to the user.

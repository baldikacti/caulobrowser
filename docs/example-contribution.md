# Example contribution: add a small doc, push to origin, then delete branch

This file is a minimal, copyable example you can follow to practice the fork/branch/push/PR/cleanup flow.

Prerequisites: you have cloned your fork and set `upstream` remote.

1) Create a feature branch and add this file

```bash
# from repo root
git switch -c docs/example-pr
cp docs/example-contribution.md docs/example-contribution.md   # (no-op if already present)
git add docs/example-contribution.md
git commit -m "docs: add example contribution guide"
```

2) Push branch to your fork (`origin`) and open a PR

```bash
git push -u origin docs/example-pr
# open a PR using the GitHub UI or:
# gh pr create --title "docs: add example contribution guide" --body "Small example file" --base main
```

3) After review: (a) if PR is merged on upstream, delete local and remote branch

```bash
# update local main and remove branch locally
git fetch upstream
git switch main
git merge upstream/main   # or: git pull --rebase upstream main
git branch -d docs/example-pr
# remove branch from your fork
git push origin --delete docs/example-pr
```

3b) If you want to delete the branch without merging (abandon the change)

```bash
git switch main
git branch -D docs/example-pr         # force-delete local
git push origin --delete docs/example-pr
```

Helpful checks

```bash
git branch -vv        # show local branches and tracking info
git remote -v         # show origin/upstream URLs
```

Notes
- Use `--force-with-lease` when you must force-push after rebasing: `git push --force-with-lease`.
- If you need to update the branch after feedback, make commits locally and `git push` (no force) unless you rebased.

That's it — follow these commands step-by-step in your clone to practice the flow.

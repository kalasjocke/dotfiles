---
name: rebase-main
description: Fetch the latest main and rebase the current branch onto it, resolving any conflicts. Use when the user asks to rebase on/onto main, update/sync the branch with main, or "rebase main".
---

# Rebase onto latest main

Bring the current feature branch up to date with `main` by rebasing, resolving any conflicts that arise.

## Steps

1. **Check state.** Run `git status`. The working tree must be clean — if there are uncommitted changes, stop and ask the user (or offer to stash). Confirm the current branch with `git branch --show-current`; never run this flow while on `main` itself.

2. **Fetch main.** Run:
   ```
   git fetch origin main:main
   ```
   This fast-forwards the local `main` ref to origin's latest without checking it out. (If it fails because `main` can't fast-forward, fall back to `git fetch origin` and rebase onto `origin/main` instead.)

3. **Rebase.** Run `git rebase main`.

4. **Resolve conflicts**, looping until done:
   - Inspect: `git status`, then open each conflicted file and find the `<<<<<<<` / `=======` / `>>>>>>>` markers.
   - Resolve by understanding *both* sides — keep each side's independent changes; take the **union** for append-only lists; don't blindly pick one side.
   - Stage and continue: `git add <files>` then `GIT_EDITOR=true git rebase --continue` (the `GIT_EDITOR=true` prevents the commit-message editor from blocking).
   - Repeat until you see "Successfully rebased."
   - If it goes wrong, `git rebase --abort` returns to the exact pre-rebase state — safe to retry.

5. **Generated / checked-in artifacts.** If a conflict is in a generated file (SQL schema dump, codegen types, lockfile), prefer **regenerating it after the rebase** over hand-merging — re-run the project's codegen/build and stage the result. Practical tips:
   - **Append-only lists** (e.g. a migration version list in a schema dump): merge as the union, in the correct order (e.g. timestamp).
   - **Environment-specific header lines** (e.g. pg_dump's `-- Dumped from database version X` / `-- Dumped by pg_dump version X`): set them to match what's on `main` so local tool-version drift doesn't show up as diff noise.
   - After regenerating types/schema, re-run codegen (`generate-types`, etc.) so the checked-in output matches the merged sources.

6. **Verify.** Run the project's typecheck and the tests relevant to the change. Confirm the working tree is clean and the history looks right: `git log --oneline main..HEAD`. Sanity-check that the rebased diff vs main contains only intended changes (no stray conflict leftovers, no generated-file noise).

7. **Push.** If the branch was already pushed (a PR exists), update it with:
   ```
   git push --force-with-lease
   ```
   Rebasing rewrites commit SHAs, so a force-push is required — always use `--force-with-lease` (it refuses to clobber if the remote moved), never a plain `--force`.

## Notes
- Only ever force-push your own feature branch — never `main` or a shared/protected branch.
- `git rebase -i` (interactive) is not available in some environments; this flow uses plain `git rebase main`, which doesn't need it.
- If many commits conflict on the same generated file, it's often faster to resolve each pick minimally to get through the rebase, then regenerate the artifact once at the end and amend.

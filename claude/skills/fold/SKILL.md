---
name: fold
description: Fold uncommitted fixes into the branch commits they belong to, with fixup commits and an autosquash rebase, then check the result. Use when the user asks to fold, fixup or squash changes into earlier commits, or to put a review fix in the commit it belongs to.
---

# Fold fixes into their commits

Put each uncommitted change into the commit on the branch that introduced the
code it changes, so every commit stays reviewable on its own.

## Steps

1. **Check state.** Run `git status` and `git branch --show-current`. Never run
   this on the default branch. Find the base with
   `git merge-base HEAD origin/<default-branch>` and list the branch's commits
   with `git log --oneline <base>..HEAD`.

2. **Pick a target commit for each change.** For each changed file, run
   `git log --oneline <base>..HEAD -- <file>`. If several commits touched the
   file, run `git blame <base>..HEAD -- <file>` on the changed lines to see which
   commit wrote them. A change that belongs to no commit on the branch is new
   work: stop and ask whether it should be a new commit. If the right target is
   unclear, show the options and ask.

3. **Make the fixup commits.** Stage files by name, then run
   `git commit --fixup=<sha>` once per target. When one file has changes for
   two targets, write each part as a patch and stage it with
   `git apply --cached`. `git add -p` needs a terminal and won't work here.
   If the fix changes what a commit does, so its message no longer fits, use
   `git commit --fixup=amend:<sha>` and write the corrected message.

4. **Record the tip.** Save `git rev-parse HEAD` as the expected result. After
   the rebase, the tree must match it.

5. **Rebase.** Run:
   ```
   GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>
   ```
   `GIT_SEQUENCE_EDITOR=:` accepts the generated todo list without opening an
   editor. On a conflict, resolve it, stage the files and run
   `GIT_EDITOR=true git rebase --continue`. `git rebase --abort` returns to the
   state before the rebase.

6. **Verify.**
   - `git diff <recorded-tip> HEAD` must print nothing.
   - `git log --oneline <base>..HEAD` must have no `fixup!` or `amend!` commits
     left.
   - Reread the message of every commit that changed, with
     `git log --format='%h %B' <base>..HEAD`. Update any message that no longer
     describes its commit.
   - Run the project's tests or typecheck for the changed code.

7. **Report.** List which change went into which commit, with the new short
   hashes, and show the verify output.

## Notes

- Don't push unless the user asks. A pushed branch then needs
  `git push --force-with-lease`, never plain `--force`. If the branch has an
  open PR, update its title and description to match the commits.
- Don't use `git stash` to set changes aside. Other sessions and worktrees
  share the stash.

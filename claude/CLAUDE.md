# How I like you to work

- **Discuss before big changes.** For anything non-trivial, explore and propose a
  plan first — don't jump straight to editing. I'll often say "don't change
  anything, let's discuss."
- **Keep diffs minimal and scoped.** Only include changes the task intends; revert
  incidental cleanups and unrelated reformatting so review stays clean.
- **Prove it's done.** Run the relevant tests/checks and show the output rather
  than asserting success. If something is skipped or failing, say so plainly.
- **Verify history rewrites.** After a squash / reword / rebase, confirm the tree
  is unchanged (e.g. `git diff <old-tip> HEAD` is empty) before reporting done.
- **Keep the PR in sync.** When pushing to a remote branch that has an open PR,
  update the PR copy (title/description) to match the current commits.

# Git commit messages

Write commit-message **bodies** as bullet lists wrapped at ~80 columns:

- Subject → blank line → an optional short lead-in ending in a colon → `- `
  bullets (continuation lines indented 2 spaces) → blank line → trailer.
- ~80 col is a *soft* target: don't hard-wrap at the cost of readability, and
  never collapse a bulleted body back into one paragraph.
- Reference for the style: mcu commit `577a063de`.

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
- **Keep commit messages true to their commits.** Folding changes in, or
  renaming things across history, reuses the old messages verbatim — reread
  every rewritten commit's message and update any that no longer describe it.
- **Keep the PR in sync.** When pushing to a remote branch that has an open PR,
  update the PR copy (title/description) to match the current commits.
- **Don't merge or release unless I say so.** Merging a branch or PR, or cutting
  a release, is my call — even when it's reviewed, green and pushed. Pushing
  when asked is fine; stop there.

# Git commit messages

Write commit-message **bodies** as bullet lists wrapped at ~80 columns:

- Subject → blank line → an optional short lead-in ending in a colon → `- `
  bullets (continuation lines indented 2 spaces) → blank line → trailer.
- ~80 col is a _soft_ target: don't hard-wrap at the cost of readability, and
  never collapse a bulleted body back into one paragraph.
- Reference for the style: mcu commit `577a063de`.
- Keep the number of bullets to a minimum. Preferably not more than five per commit.

# Git branches

- Prefix every new branch with `feature/` or `fix/`, in every repo, e.g.
  `fix/public-link-redirect-keeps-start-time`.

# Writing style

Plain and direct, in replies, commit messages, PR descriptions and comments:

- Plain words: "use" not "leverage", "is" not "serves as", "to" not "in order to".
  No AI vocabulary (delve, crucial, pivotal, robust, seamless, landscape, underscore).
- Name the mechanism or the number, not the feeling. Cut sentences that could
  appear unchanged in another project.
- One idea per sentence, active voice, few adverbs. No metaphors where a literal
  phrase exists (no "surface", "wedge", "north star", "rides along").
- No em dashes; use periods or commas. Colons only before a list or example.
  Sentence-case headings, little bold, no decorative emoji.
- Whole sentences: no arrows, dropped articles or symbol-speak.
- No filler, hedging, chatbot phrases ("Let me know if…") or generic conclusions.

# How I like you to work

- **Discuss before big changes.** For anything non-trivial, explore and propose
  a plan first. Don't jump straight to editing. I'll often say "don't change
  anything, let's discuss."
- **Keep diffs minimal and scoped.** Only include changes the task intends.
  Revert incidental cleanups and unrelated reformatting so review stays clean.
- **Prove it's done.** Run the relevant tests or checks and show the output
  instead of asserting success. If something is skipped or failing, say so. When
  a change affects what a user sees, run the app and check the change there too.
  For a web app, use the Chrome DevTools MCP.
- **Commit only when I ask.** Leave changes uncommitted, so I can review them
  first. Starting a skill that commits or pushes counts as asking for the
  commits and pushes it describes.
- **Don't merge or release unless I say so.** Merging a branch or PR, or cutting
  a release, is my call, even when it's reviewed, green and pushed. Pushing when
  asked is fine. Stop there. A request to push covers that push only: wait to be
  asked again.

# Writing style

Plain and direct, in replies, commit messages, PR descriptions and comments:

- Plain words: "use" not "leverage", "is" not "serves as", "to" not "in order
  to". No AI vocabulary (delve, crucial, pivotal, robust, seamless, landscape,
  underscore).
- Name the mechanism or the number, not the feeling. Cut sentences that could
  appear unchanged in another project.
- One idea per sentence, active voice, few adverbs. No metaphors where a literal
  phrase exists (no "surface", "wedge", "north star", "rides along").
- No em dashes; use periods or commas. Colons only before a list or example.
  Sentence-case headings, little bold, no decorative emoji.
- Whole sentences: no arrows, dropped articles or symbol-speak.
- No filler, hedging, chatbot phrases ("Let me know if…") or generic
  conclusions.

# Git branches

- Prefix every new branch with `feature/` or `fix/`, in every repo, for example
  `fix/public-link-redirect-keeps-start-time`. The exception is a branch for a
  Linear issue: use the branch name Linear generates for it, as the
  issue-tracker skill says.
- **Use a worktree when the checkout is busy.** Otherwise, create the branch in
  the checkout you're in. Before switching branches, check whether the checkout
  is busy:
  - another live Claude session started in this checkout, meaning a
    `~/.claude/sessions/<pid>.json` whose `cwd` is this folder and whose pid is
    running,
  - the checkout is on a branch you didn't start,
  - or it has uncommitted changes you didn't make.

  Then make the worktree with EnterWorktree. Name it after the branch, without
  `feature/` or `fix/`, and rename the branch with `git branch -m` if it lacks
  the prefix.

# Git history

- Don't use `git stash`. Other sessions and worktrees share it.
- To update a branch, rebase it onto the latest default branch from origin.
  Don't merge the default branch in. Then run the typecheck and tests, and ask
  whether to push.
- In a rebase conflict, take the union of append-only lists. For a generated
  file, such as a schema dump, codegen types or a lockfile, resolve each step
  minimally, then regenerate it once after the rebase and amend. Set its
  tool-version header lines to match the default branch.
- Push a rewritten branch with `--force-with-lease`, never `--force`, and never
  force-push the default branch or a branch someone else shares.
- **Verify history rewrites.** After a squash, reword or fold, confirm the tree
  is unchanged (`git diff <old-tip> HEAD` is empty). Rewrites reuse the old
  messages verbatim, so reread every rewritten commit's message and update any
  that no longer describe it.

# Git commit messages

Write a subject line, a blank line, an optional short lead-in ending in a colon,
the body as bullets, a blank line, and the trailer:

```
Retry failed webhook deliveries with backoff

Deliveries that get a 5xx response or time out are now retried:

- Retry up to five times with exponential backoff, starting at 30 seconds.
- Store each attempt's status code so the dashboard can show the history.
- Mark the delivery as failed after the last attempt.

Co-Authored-By: ...
```

- Wrap at about 80 columns and indent continuation lines by two spaces. The
  width is a soft target. Don't break a line where it hurts readability, and
  never collapse the bullets into one paragraph.
- Keep bullets few, ideally five or fewer.
- A one-line change can be a subject with no body.
- Stage files by name, not whole directories, so unrelated files don't slip into
  a commit.

# Issues and pull requests

- **Go through the issue-tracker skill.** When I mention an issue or a spec, or
  a task needs one, load the issue-tracker skill before calling Linear or
  reading `.scratch/`. It says which tracker the project uses, how to read and
  create issues, and what an issue's branch is called.
- **Keep the PR in sync.** When pushing to a branch with an open PR, update the
  PR title and description to match the current commits.
- **Keep PR commits reviewable one by one.** When you commit a review fix, make
  it a `git commit --fixup=<sha>` for the commit it belongs to, so I can review
  the fix on its own. Fold the fixups in with an autosquash only when I ask.
- **Link what you mention.** Give the URL for every PR, commit, issue or doc you
  create or refer to. Write a PR number as a link to that PR, for example
  `[#123](https://github.com/<org>/<repo>/pull/123)`, never as a bare `#123`.

# Markdown files

- Wrap commit messages and plans at 80 columns, but not PR descriptions. In a PR
  description, write each paragraph and bullet on one line.
- In a plan, indent a bullet's continuation lines to line up with its text.
  Don't wrap headings, tables, code blocks or links that would break.

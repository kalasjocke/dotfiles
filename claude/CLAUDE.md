# How I like you to work

- **Discuss before big changes.** For anything non-trivial, explore and propose
  a plan first. Don't jump straight to editing. I'll often say "don't change
  anything, let's discuss."
- **Keep diffs minimal and scoped.** Only include changes the task intends.
  Revert incidental cleanups and unrelated reformatting so review stays clean.
- **Prove it's done.** Run the relevant tests or checks and show the output
  instead of asserting success. If something is skipped or failing, say so.
- **Verify history rewrites.** After a squash, reword or rebase, confirm the
  tree is unchanged (`git diff <old-tip> HEAD` is empty). Rewrites reuse the
  old messages verbatim, so reread every rewritten commit's message and update
  any that no longer describe it.
- **Keep the PR in sync.** When pushing to a branch with an open PR, update the
  PR title and description to match the current commits.
- **Keep PR commits reviewable one by one.** Fold review fixes into the commit
  they belong to (fixup and autosquash) instead of adding fix commits on top.
- **Link what you mention.** Give the URL for every PR, commit, issue or doc you
  create or refer to.
- **Don't merge or release unless I say so.** Merging a branch or PR, or
  cutting a release, is my call, even when it's reviewed, green and pushed.
  Pushing when asked is fine. Stop there.

# Git commit messages

Write a subject line, a blank line, an optional short lead-in ending in a
colon, the body as bullets, a blank line, and the trailer:

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
- Stage files by name, not whole directories, so unrelated files don't slip
  into a commit.

# Git branches

- Prefix every new branch with `feature/` or `fix/`, in every repo, for
  example `fix/public-link-redirect-keeps-start-time`.

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

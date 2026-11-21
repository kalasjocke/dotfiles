#!/bin/sh
# Names the Rex pane a Claude Code session runs in after the session and the
# size of its context, like "dotfiles (258k)". Rex shows the focused pane's
# name in the tab, so the tab follows whichever Claude Code session has focus.
#
# Wired to these hooks in ~/.claude/settings.json: SessionStart,
# UserPromptSubmit, PostToolUse and Stop rename the pane, and SessionEnd gives
# it its default name back.
#
# Hooks get no context size, so this reads the token count of the last
# response from the session's transcript. That is the same count the status
# line gets as context_window.total_input_tokens.

[ -n "$REX_BLOCK" ] || exit 0
input=$(cat)
field() { printf '%s' "$input" | jq -r "$1"; }

event=$(field .hook_event_name)

if [ "$event" = SessionEnd ]; then
  rex --timeout 2s block rename "$REX_BLOCK" "" >/dev/null 2>&1
  exit 0
fi

# Rename in the background, so the hook doesn't hold up Claude Code. Stop can
# fire before Claude Code writes the last response to the transcript, and
# SessionStart after a compaction before it writes the compaction, so wait a
# quarter of a second for them.
(
  case $event in Stop | SessionStart) sleep 0.25 ;; esac
  sid=$(field .session_id)
  name=$(jq -r --arg s "$sid" 'select(.sessionId == $s) | .name // empty' \
    "$HOME"/.claude/sessions/*.json 2>/dev/null | head -1)
  [ -n "$name" ] || name=$(basename "$(field .cwd)")

  # The last response's input, cache creation and cache read tokens, from the
  # main conversation only. Placeholder responses Claude Code writes after an
  # interrupt or error have the model "<synthetic>" and no tokens, so they're
  # skipped. A compaction that came after the last response
  # shows as "compacted" until the next response. Its compact_boundary entry
  # has a postTokens count, but that leaves out the system prompt and tools.
  tokens=$(tail -n 400 "$(field .transcript_path)" 2>/dev/null | tail -r |
    jq -r 'select(.isSidechain | not)
      | if .type == "assistant" and .message.usage
          and .message.model != "<synthetic>" then
          .message.usage
          | .input_tokens + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)
        elif .type == "system" and .subtype == "compact_boundary" then
          "compacted"
        else empty end' \
      2>/dev/null | head -1)
  # A new session has no response yet, so it shows only the name.
  case $tokens in
    "" | 0) label=$name ;;
    compacted) label="$name (compacted)" ;;
    *) label="$name ($(awk -v t="$tokens" \
      'BEGIN { if (t < 1000) print t; else printf "%dk", int(t / 1000 + 0.5) }'))" ;;
  esac

  rex --timeout 2s block rename "$REX_BLOCK" "$label" >/dev/null 2>&1
) </dev/null >/dev/null 2>&1 &

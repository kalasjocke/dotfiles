#!/bin/sh
# Rings the bell for Claude Code hooks, so tmux flags the window it happened in.
#
# Wired to the Notification and Stop hooks in ~/.claude/settings.json. tmux turns
# the bell into window_bell_flag, which tmux.conf renders by recoloring the
# window index gold and bold (window-status-bell-style) -- Stop is the one that
# matters, since it fires when a turn finishes and that is the moment worth
# noticing from another window.
#
# Hook processes have no controlling terminal, so /dev/tty cannot be written to;
# the bell has to go to the pane's own tty.

pane=$TMUX_PANE

# Background sessions run hooks in Claude's daemon, which has no $TMUX_PANE.
# Claude titles the pane showing a session with the session's name, sometimes
# after a status symbol like "✳ ". So look up the name from the hook's
# session_id and find the pane whose title is or ends with that name.
if [ -z "$pane" ]; then
  sid=$(jq -r .session_id)
  name=$(jq -r --arg s "$sid" 'select(.sessionId == $s) | .name' \
    "$HOME"/.claude/sessions/*.json 2>/dev/null | head -1)
  [ -n "$name" ] || exit 0
  pane=$(tmux list-panes -a -F '#{pane_id} #{pane_title}' |
    awk -v n="$name" '{ id = $1; sub(/^[^ ]+ /, "") }
      $0 == n || substr($0, length($0) - length(n)) == " " n { print id; exit }')
fi
[ -n "$pane" ] || exit 0

tty=$(tmux display -p -t "$pane" '#{pane_tty}' 2>/dev/null)
[ -n "$tty" ] || exit 0

# Emits nothing visible, so it cannot disturb the Claude TUI.
printf '\a' > "$tty" 2>/dev/null
exit 0

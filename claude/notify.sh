#!/bin/sh
# Rings the bell for Claude Code hooks, so tmux flags the window it happened in.
#
# Wired to the Notification and Stop hooks in ~/.claude/settings.json. tmux turns
# the bell into window_bell_flag, which ~/.tmux.conf renders by recoloring the
# window index gold and bold (window-status-bell-style) -- Stop is the one that
# matters, since it fires when a turn finishes and that is the moment worth
# noticing from another window.
#
# Hook processes have no controlling terminal, so /dev/tty cannot be written to;
# the bell has to go to the pane's own tty, looked up through $TMUX_PANE.

[ -n "$TMUX_PANE" ] || exit 0

tty=$(tmux display -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null)
[ -n "$tty" ] || exit 0

# Emits nothing visible, so it cannot disturb the Claude TUI.
printf '\a' > "$tty" 2>/dev/null
exit 0

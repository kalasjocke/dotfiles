#!/bin/sh
# Marks the tmux window a Claude Code session runs in as blocked or done, so
# tmux.conf can color its index in the status bar.
#
# Wired to the Notification and Stop hooks in ~/.claude/settings.json. The state
# goes in the window option @claude, using the state names of the OSC 7501
# program status protocol:
#
# - blocked: Claude waits on a permission prompt or a question (Notification).
# - done: a turn finished and its result is not yet seen (Stop).
#
# tmux.conf unsets @claude when the window is selected. tmux does not read OSC
# 7501 itself yet, which is why this sets the option directly.

input=$(cat)

case $(printf '%s' "$input" | jq -r .hook_event_name) in
  Stop) state=done ;;
  Notification)
    # Prompts, questions and dialogs, in this session or an agent it tracks,
    # wait on you. idle_prompt fires a minute after Stop and must not turn done
    # into blocked. agent_completed is covered by Stop, and the other types,
    # like auth_success and push_notification, need no action.
    case $(printf '%s' "$input" | jq -r '.notification_type // ""') in
      permission_prompt | worker_permission_prompt | elicitation_dialog | \
        elicitation_url_dialog | agent_needs_input | "") state=blocked ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac

pane=$TMUX_PANE

# Background sessions run hooks in Claude's daemon, which has no $TMUX_PANE.
# Claude titles the pane showing a session with the session's name, sometimes
# after a status symbol like "✳ ". So look up the name from the hook's
# session_id and find the pane whose title is or ends with that name.
if [ -z "$pane" ]; then
  sid=$(printf '%s' "$input" | jq -r .session_id)
  name=$(jq -r --arg s "$sid" 'select(.sessionId == $s) | .name' \
    "$HOME"/.claude/sessions/*.json 2>/dev/null | head -1)
  [ -n "$name" ] || exit 0
  pane=$(tmux list-panes -a -F '#{pane_id} #{pane_title}' |
    awk -v n="$name" '{ id = $1; sub(/^[^ ]+ /, "") }
      $0 == n || substr($0, length($0) - length(n)) == " " n { print id; exit }')
fi
[ -n "$pane" ] || exit 0

# Leave the window you are looking at alone, as tmux does with the bell flag.
[ "$(tmux display -p -t "$pane" '#{&&:#{window_active},#{session_attached}}' \
  2>/dev/null)" = 1 ] && exit 0

tmux set -w -t "$pane" @claude "$state" 2>/dev/null
exit 0

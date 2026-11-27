#!/bin/sh
# Sets the window option @state of the tmux window a Claude Code session runs
# in, using the state names of the OSC 7501 program status protocol.
#
# Wired to these hooks in ~/.claude/settings.json:
#
# - working: you sent a prompt (UserPromptSubmit), or a tool finished
#   (PostToolUse), which ends blocked once you answer a prompt.
# - blocked: Claude waits on a permission prompt or a question
#   (PermissionRequest, Notification).
# - done: a turn finished and its result is not yet seen (Stop).
# - error: a turn ended on an API error (StopFailure).
# - unset: the session ended (SessionEnd).
#
# Claude Code runs no hook when you interrupt a turn, so working stays until
# the next prompt or the end of the session.
#
# blocked, done and error mean "come and look", so they are not set on the
# window you are looking at, and tmux.conf unsets them when you select the
# window. tmux does not read OSC 7501 itself yet, which is why this sets the
# option directly.

input=$(cat)

# Outside tmux, such as in Rex, there is no window to set the state on.
[ -n "$TMUX_PANE" ] || tmux info >/dev/null 2>&1 || exit 0

field() { printf '%s' "$input" | jq -r "$1"; }

case $(field .hook_event_name) in
  UserPromptSubmit | PostToolUse) state=working ;;
  PermissionRequest) state=blocked ;;
  Stop) state=done ;;
  StopFailure) state=error ;;
  SessionEnd) state= ;;
  Notification)
    # Prompts, questions and dialogs, in this session or an agent it tracks,
    # wait on you. idle_prompt fires a minute after Stop and must not turn done
    # into blocked. agent_completed is covered by Stop, and the other types,
    # like auth_success and push_notification, need no action.
    case $(field '.notification_type // ""') in
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
  sid=$(field .session_id)
  name=$(jq -r --arg s "$sid" 'select(.sessionId == $s) | .name' \
    "$HOME"/.claude/sessions/*.json 2>/dev/null | head -1)
  [ -n "$name" ] || exit 0
  pane=$(tmux list-panes -a -F '#{pane_id} #{pane_title}' |
    awk -v n="$name" '{ id = $1; sub(/^[^ ]+ /, "") }
      $0 == n || substr($0, length($0) - length(n)) == " " n { print id; exit }')
fi
[ -n "$pane" ] || exit 0

# In the window you are looking at, unset the state instead of asking you to
# come and look, as tmux does with the bell flag. This also ends working.
case $state in
  blocked | done | error)
    [ "$(tmux display -p -t "$pane" '#{&&:#{window_active},#{session_attached}}' \
      2>/dev/null)" = 1 ] && state=
    ;;
esac

if [ -n "$state" ]; then
  tmux set -w -t "$pane" @state "$state" 2>/dev/null
else
  tmux set -w -u -t "$pane" @state 2>/dev/null
fi
exit 0

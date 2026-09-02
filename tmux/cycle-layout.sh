#!/bin/sh
# Toggle the current window between an even layout and one big main pane with
# the other splits at a fixed width.
#
#   2 panes:  50/50     <->  rest | 80
#   3 panes:  33/33/33  <->  rest | 80, split 50/50 high
#
# Bound to prefix + Space. The split axis is preserved: panes side by side stay
# side by side, stacked panes stay stacked.

# Width of the non-main splits. Stacked panes get a percentage instead, since a
# fixed row count means something different on every screen.
other_cols=80
other_rows=40%

panes=$(tmux display -p '#{window_panes}')
[ "$panes" -lt 2 ] && exit 0

# The outermost bracket of the layout string says how the panes are arranged:
# '{' is a row of columns, '[' is a column of rows.
case $(tmux display -p '#{window_layout}' | tr -dc '{[' | cut -c1) in
  '[')
    even=even-vertical
    main=main-horizontal
    opt=other-pane-height
    val=$other_rows
    floor=main-pane-height
    size='#{pane_height}'
    ;;
  *)
    even=even-horizontal
    main=main-vertical
    opt=other-pane-width
    val=$other_cols
    floor=main-pane-width
    size='#{pane_width}'
    ;;
esac

# An even layout has every pane the same size along the split axis, give or take
# a cell for rounding. Anything else counts as the main layout, so the next
# press evens it out -- including a layout you dragged around with the mouse.
sorted=$(tmux list-panes -F "$size" | sort -n)
spread=$(( $(echo "$sorted" | tail -1) - $(echo "$sorted" | head -1) ))

if [ "$spread" -le 1 ]; then
  # main-pane-* acts as a floor and would keep the other splits off 80.
  tmux setw -u "$floor"
  tmux setw "$opt" "$val"
  tmux select-layout "$main"
else
  tmux select-layout "$even"
fi

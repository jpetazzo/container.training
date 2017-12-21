#!/bin/sh
# This removes the clock (and other extraneous stuff) from the
# tmux status bar, and it gives it a non-default color.
tmux set-option -g status-left ""
tmux set-option -g status-right ""
tmux set-option -g status-style bg=cyan


#!/bin/bash

zen-browser &

chromium --new-window --app=https://chat.openai.com &

kitty --class quick-term &

kitty --class nvim-tmux -e tmux &

clipse -listen &

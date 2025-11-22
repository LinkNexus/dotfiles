#!/bin/bash

zen-browser &

chromium --new-window --app=https://chat.openai.com &

kitty --class quick-term &

kitty --class work-term &

clipse -listen &

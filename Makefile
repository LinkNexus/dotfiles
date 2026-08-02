# Windows has no built-in `make`: install one via `choco install make`,
# `scoop install make`, or MSYS2's `pacman -S make`, then run this from
# Git Bash (its bundled sh.exe/coreutils are what make the POSIX-shell
# recipes below -- ln -sfn, mkdir -p, rm -f -- work). Creating symlinks
# also needs either an elevated shell or Developer Mode turned on.

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CONFIG := $(HOME)/.config

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
	OS := macos
else ifneq (,$(filter MINGW% MSYS% CYGWIN%,$(UNAME_S)))
	OS := windows
else
	OS := linux
endif

ifeq ($(OS),macos)
	VSCODE_CONFIG := "$(HOME)/Library/Application Support/Code - Insiders/User"
else ifeq ($(OS),windows)
	VSCODE_CONFIG := "$(HOME)/AppData/Roaming/Code/User"
else
	VSCODE_CONFIG := $(HOME)/.config/Code/User
endif

.PHONY: install install-common install-macos install-linux install-windows uninstall

install: install-common install-$(OS)

setup-unix:
	mkdir -p $(HOME)/.local/bin
	mkdir -p $(HOME)/.local/share
	mkdir -p $(HOME)/.local/state
	mkdir -p $(HOME)/.cache

setup-zsh: setup-unix
	mkdir -p $(HOME)/.cache/zsh
	mkdir -p $(HOME)/.local/state/zsh

install-common:
	mkdir -p $(CONFIG)
	ln -sfn $(ROOT)/nvim $(CONFIG)/nvim
	ln -sfn $(ROOT)/vscode/settings.json $(VSCODE_CONFIG)/settings.json

install-macos: setup-zsh
	ln -sfn $(ROOT)/ghostty $(CONFIG)/ghostty
	ln -sfn $(ROOT)/kitty $(CONFIG)/kitty
	ln -sfn $(ROOT)/tmux $(CONFIG)/tmux
	ln -sfn $(ROOT)/wezterm/.wezterm.lua $(HOME)/.wezterm.lua
	ln -sfn $(ROOT)/zsh/.zshenv $(HOME)/.zshenv
	ln -sfn $(ROOT)/aerospace $(CONFIG)/aerospace
	ln -sfn $(ROOT)/sketchybar $(CONFIG)/sketchybar
	ln -sfn $(ROOT)/hammerspoon $(HOME)/.hammerspoon

	# Custom Claude Code themes (carbonfox/dayfox, switched by
	# scripts/on-theme-change following the OS appearance). macOS-only
	# for now: the auto-switch mechanism is tied to AppleInterfaceStyle
	# and launchd. Revisit once Linux/Windows get their own watchers.
	mkdir -p $(HOME)/.claude
	ln -sfn $(ROOT)/claude/themes $(HOME)/.claude/themes

	# Theme-change watcher runs as a LaunchAgent so it works even with
	# AeroSpace/sketchybar disabled. Copied, not symlinked: launchd is
	# unreliable with symlinked plists. Re-run install after plist edits.
	mkdir -p $(HOME)/Library/LaunchAgents
	cp $(ROOT)/launchd/com.levynkeneng.theme-watcher.plist $(HOME)/Library/LaunchAgents/
	-launchctl bootout gui/$$(id -u)/com.levynkeneng.theme-watcher 2>/dev/null
	launchctl bootstrap gui/$$(id -u) $(HOME)/Library/LaunchAgents/com.levynkeneng.theme-watcher.plist

	# Display watcher: enables/disables AeroSpace, sketchybar, JankyBorders
	# and Stage Manager based on whether a screen wide enough for tiling
	# is connected
	cp $(ROOT)/launchd/com.levynkeneng.display-watcher.plist $(HOME)/Library/LaunchAgents/
	-launchctl bootout gui/$$(id -u)/com.levynkeneng.display-watcher 2>/dev/null
	launchctl bootstrap gui/$$(id -u) $(HOME)/Library/LaunchAgents/com.levynkeneng.display-watcher.plist

	# Opens the daily app set (kitty, Zen, Thunderbird, btop) once per
	# login, independent of AeroSpace's on/off state for the session
	cp $(ROOT)/launchd/com.levynkeneng.login-apps.plist $(HOME)/Library/LaunchAgents/
	-launchctl bootout gui/$$(id -u)/com.levynkeneng.login-apps 2>/dev/null
	launchctl bootstrap gui/$$(id -u) $(HOME)/Library/LaunchAgents/com.levynkeneng.login-apps.plist

install-linux: setup-zsh
	ln -sfn $(ROOT)/ghostty $(CONFIG)/ghostty
	ln -sfn $(ROOT)/kitty $(CONFIG)/kitty
	ln -sfn $(ROOT)/tmux $(CONFIG)/tmux
	ln -sfn $(ROOT)/zsh/.zshenv $(HOME)/.zshenv

install-windows:
	ln -sfn $(ROOT)/wezterm/.wezterm.lua $(HOME)/.wezterm.lua

uninstall:
	-launchctl bootout gui/$$(id -u)/com.levynkeneng.theme-watcher 2>/dev/null
	rm -f $(HOME)/Library/LaunchAgents/com.levynkeneng.theme-watcher.plist
	-launchctl bootout gui/$$(id -u)/com.levynkeneng.display-watcher 2>/dev/null
	rm -f $(HOME)/Library/LaunchAgents/com.levynkeneng.display-watcher.plist
	-launchctl bootout gui/$$(id -u)/com.levynkeneng.login-apps 2>/dev/null
	rm -f $(HOME)/Library/LaunchAgents/com.levynkeneng.login-apps.plist
	rm -f $(HOME)/.claude/themes
	rm -f $(CONFIG)/nvim
	rm -f $(CONFIG)/ghostty
	rm -f $(CONFIG)/kitty
	rm -f $(CONFIG)/tmux
	rm -f $(CONFIG)/aerospace
	rm -f $(CONFIG)/sketchybar
	rm -f $(HOME)/.hammerspoon
	rm -f $(HOME)/.wezterm.lua
	rm -f $(HOME)/.zshenv
	rm -f "$(HOME)/Library/Application Support/Code - Insiders/User/settings.json"
	rm -f $(HOME)/.config/Code/User/settings.json
	rm -f "$(HOME)/AppData/Roaming/Code/User/settings.json"

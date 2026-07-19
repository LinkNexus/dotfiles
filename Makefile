ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CONFIG := $(HOME)/.config

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
	VSCODE_CONFIG := "$(HOME)/Library/Application Support/Code - Insiders/User"
else
	VSCODE_CONFIG := $(HOME)/.config/Code/User
endif

.PHONY: install uninstall

install:
	mkdir -p $(CONFIG)

	ln -sfn $(ROOT)/ghostty $(CONFIG)/ghostty
	ln -sfn $(ROOT)/nvim $(CONFIG)/nvim
	ln -sfn $(ROOT)/kitty $(CONFIG)/kitty
	ln -sfn $(ROOT)/tmux $(CONFIG)/tmux
	ln -sfn $(ROOT)/wezterm/.wezterm.lua $(HOME)/.wezterm.lua
	ln -sfn $(ROOT)/zsh/.zshrc $(HOME)/.zshrc
	ln -sfn $(ROOT)/vscode/settings.json $(VSCODE_CONFIG)/settings.json
	ln -sfn $(ROOT)/aerospace $(CONFIG)/aerospace
	ln -sfn $(ROOT)/sketchybar $(CONFIG)/sketchybar

	# Custom Claude Code themes (carbonfox/dayfox, switched by
	# scripts/on-theme-change following the OS appearance)
	mkdir -p $(HOME)/.claude
	ln -sfn $(ROOT)/claude/themes $(HOME)/.claude/themes

	# Theme-change watcher runs as a LaunchAgent so it works even with
	# AeroSpace/sketchybar disabled. Copied, not symlinked: launchd is
	# unreliable with symlinked plists. Re-run install after plist edits.
	mkdir -p $(HOME)/Library/LaunchAgents
	cp $(ROOT)/launchd/com.levynkeneng.theme-watcher.plist $(HOME)/Library/LaunchAgents/
	-launchctl bootout gui/$$(id -u)/com.levynkeneng.theme-watcher 2>/dev/null
	launchctl bootstrap gui/$$(id -u) $(HOME)/Library/LaunchAgents/com.levynkeneng.theme-watcher.plist

uninstall:
	-launchctl bootout gui/$$(id -u)/com.levynkeneng.theme-watcher 2>/dev/null
	rm -f $(HOME)/Library/LaunchAgents/com.levynkeneng.theme-watcher.plist
	rm -f $(HOME)/.claude/themes
	rm -f $(CONFIG)/nvim
	rm -f $(CONFIG)/ghostty
	rm -f $(CONFIG)/kitty
	rm -f $(CONFIG)/tmux
	rm -f $(HOME)/.wezterm.lua
	rm -f $(HOME)/.zshrc
	rm -f $(VSCODE_CONFIG)/settings.json

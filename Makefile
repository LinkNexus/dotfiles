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

uninstall:
	rm -f $(CONFIG)/nvim
	rm -f $(CONFIG)/ghostty
	rm -f $(CONFIG)/kitty
	rm -f $(CONFIG)/tmux
	rm -f $(HOME)/.wezterm.lua
	rm -f $(HOME)/.zshrc
	rm -f $(VSCODE_CONFIG)/settings.json

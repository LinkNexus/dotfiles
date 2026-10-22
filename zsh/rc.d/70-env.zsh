export HOMEBREW_BUNDLE_FILE_GLOBAL="$HOME/dotfiles/Brewfile"

export FZF_DEFAULT_OPTS="--preview '[[ -d {} ]] && eza --tree --level=2 --color=always {} || bat --style=numbers --color=always --line-range=:500 {}' --preview-window=right:60%:border-left"

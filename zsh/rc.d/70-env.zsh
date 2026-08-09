export HOMEBREW_BUNDLE_FILE_GLOBAL="$HOME/dotfiles/Brewfile"
export DOTNET_ROOT=$(dirname $(readlink -f $(which dotnet)))

# fzf previews: bat for files (syntax highlighting), eza for directories
# (bat can't render those) -- applies to every fzf invocation, including
# the Ctrl-T file widget from `fzf --zsh` in 40-prompt.zsh
export FZF_DEFAULT_OPTS="--preview '[[ -d {} ]] && eza --tree --level=2 --color=always {} || bat --style=numbers --color=always --line-range=:500 {}' --preview-window=right:60%:border-left"

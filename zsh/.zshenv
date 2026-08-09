if [[ -z "$XDG_CONFIG_HOME" ]]; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$HOME/dotfiles/zsh" ]]; then
    export ZDOTDIR="$HOME/dotfiles/zsh"
fi

export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export EDITOR="nvim"
export VISUAL="nvim"

export GPG_TTY=$(tty)

export PATH="/run/current-system/sw/bin:$HOME/.local/share/nvim/mason/bin:/opt/homebrew/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.dotnet/tools:$HOME/dotfiles/scripts:$HOME/.bun/bin:$HOME/.cache/.bun/bin:$PATH"

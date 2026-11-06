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

# Where LLDB finds debugserver. Without it, LLDB derives it from
# DEVELOPER_DIR, which nix dev shells point at nix's apple-sdk (no
# debugserver): "could not find 'debugserver'" from codelldb, nix's lldb,
# etc. Dev shells don't touch this variable, so it survives into them.
_debugserver=/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Resources/debugserver
[[ -x "$_debugserver" ]] && export LLDB_DEBUGSERVER_PATH="$_debugserver"
unset _debugserver

export PATH="/run/current-system/sw/bin:$HOME/.local/share/nvim/mason/bin:/opt/homebrew/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.dotnet/tools:$HOME/dotfiles/scripts:$HOME/.bun/bin:$HOME/.cache/.bun/bin:$PATH"

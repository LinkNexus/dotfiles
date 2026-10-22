export HOMEBREW_BUNDLE_FILE_GLOBAL="$HOME/dotfiles/Brewfile"
# A fixed path, deliberately NOT `dirname $(readlink -f $(which dotnet))`.
# That resolved down to the SDK's /nix/store path, which is right when the
# shell starts and wrong from the next `darwin-rebuild switch` onwards:
# every shell already open -- and everything launched from one, Neovim's
# dotnet plugins included -- kept pointing at the previous dotnet-sdk
# generation. Since that store path still existed, dotnet silently paired
# the new SDK with the old host and runtime instead of failing, which
# surfaces as "the installed dotnet and the runtime have conflicting
# versions" after updating flake inputs.
#
# /run/current-system is repointed on every activation, so this same
# string always resolves to the current generation's SDK and a long-lived
# shell can no longer go stale. nix/flake.nix adds the matching
# `environment.pathsToLink = ["/share/dotnet"]` that makes the path exist;
# without it dotnet just ignores DOTNET_ROOT and resolves relative to its
# own binary, so this is harmless even before that lands.
export DOTNET_ROOT=/run/current-system/sw/share/dotnet

# fzf previews: bat for files (syntax highlighting), eza for directories
# (bat can't render those) -- applies to every fzf invocation, including
# the Ctrl-T file widget from `fzf --zsh` in 40-prompt.zsh
export FZF_DEFAULT_OPTS="--preview '[[ -d {} ]] && eza --tree --level=2 --color=always {} || bat --style=numbers --color=always --line-range=:500 {}' --preview-window=right:60%:border-left"

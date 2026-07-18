#!/usr/bin/env pwsh

param(
    [ValidateSet("install", "uninstall")]
    [string]$Action = "install"
)

$Root = $PSScriptRoot
$HomeDir = $HOME

function Get-TargetPaths {
    if ($IsWindows) {
        return @{
            Nvim    = Join-Path $env:LOCALAPPDATA "nvim"
            Kitty   = Join-Path $env:APPDATA "kitty"
            Ghostty = Join-Path $env:APPDATA "ghostty"
            Tmux    = Join-Path $env:APPDATA "tmux"
            VSCode  = Join-Path $env:APPDATA "Code\User"
            WezTerm = Join-Path $HomeDir ".wezterm.lua"
            Zsh     = Join-Path $HomeDir ".zshrc"
        }
    }

    if ($IsMacOS) {
        return @{
            Nvim    = Join-Path $HomeDir ".config/nvim"
            Kitty   = Join-Path $HomeDir ".config/kitty"
            Ghostty = Join-Path $HomeDir ".config/ghostty"
            Tmux    = Join-Path $HomeDir ".config/tmux"
            VSCode  = Join-Path $HomeDir "Library/Application Support/Code - Insiders/User"
            WezTerm = Join-Path $HomeDir ".wezterm.lua"
            Zsh     = Join-Path $HomeDir ".zshrc"
        }
    }

    # Linux
    return @{
        Nvim    = Join-Path $HomeDir ".config/nvim"
        Kitty   = Join-Path $HomeDir ".config/kitty"
        Ghostty = Join-Path $HomeDir ".config/ghostty"
        Tmux    = Join-Path $HomeDir ".config/tmux"
        VSCode  = Join-Path $HomeDir ".config/Code/User"
        WezTerm = Join-Path $HomeDir ".wezterm.lua"
        Zsh     = Join-Path $HomeDir ".zshrc"
    }
}

$Paths = Get-TargetPaths

$Links = @(
    @{
        Source = Join-Path $Root "nvim"
        Target = $Paths.Nvim
    }
    @{
        Source = Join-Path $Root "kitty"
        Target = $Paths.Kitty
    }
    @{
        Source = Join-Path $Root "ghostty"
        Target = $Paths.Ghostty
    }
    @{
        Source = Join-Path $Root "tmux"
        Target = $Paths.Tmux
    }
    @{
        Source = Join-Path $Root "wezterm/.wezterm.lua"
        Target = $Paths.WezTerm
    }
    @{
        Source = Join-Path $Root "zsh/.zshrc"
        Target = $Paths.Zsh
    }
    @{
        Source = Join-Path $Root "vscode/settings.json"
        Target = Join-Path $Paths.VSCode "settings.json"
    }
)

function Link-Item {
    param(
        [string]$Source,
        [string]$Target
    )

    $Parent = Split-Path $Target -Parent

    if ($Parent -and !(Test-Path $Parent)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    if (Test-Path $Target -PathType Any) {
        Remove-Item $Target -Recurse -Force
    }

    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null

    Write-Host "✓ Linked $Target"
}

function Remove-Link {
    param(
        [string]$Target
    )

    if (Test-Path $Target -PathType Any) {
        Remove-Item $Target -Recurse -Force
        Write-Host "✓ Removed $Target"
    }
}

switch ($Action) {

    "install" {

        foreach ($Link in $Links) {
            Link-Item $Link.Source $Link.Target
        }

    }

    "uninstall" {

        foreach ($Link in $Links) {
            Remove-Link $Link.Target
        }

    }

}

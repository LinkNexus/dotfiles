#!/usr/bin/env pwsh

param(
    [ValidateSet("install", "uninstall")]
    [string]$Action = "install"
)

$Root = Split-Path -Parent $PSScriptRoot
$UserHome = $HOME

if ($IsWindows) {
    $Config = Join-Path $env:APPDATA ""
    $VSCodeConfig = Join-Path $env:APPDATA "Code\User"
    $WezTermConfig = Join-Path $UserHome ".wezterm.lua"
    $ZshConfig = Join-Path $UserHome ".zshrc"
}
elseif ($IsMacOS) {
    $Config = Join-Path $UserHome ".config"
    $VSCodeConfig = Join-Path $UserHome "Library/Application Support/Code - Insiders/User"
    $WezTermConfig = Join-Path $UserHome ".wezterm.lua"
    $ZshConfig = Join-Path $UserHome ".zshrc"
}
else {
    $Config = Join-Path $UserHome ".config"
    $VSCodeConfig = Join-Path $Config "Code/User"
    $WezTermConfig = Join-Path $UserHome ".wezterm.lua"
    $ZshConfig = Join-Path $UserHome ".zshrc"
}

function Link-Item {
    param(
        [string]$Source,
        [string]$Target
    )

    $parent = Split-Path $Target -Parent
    if (!(Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $Target -PathType Any) {
        Remove-Item $Target -Recurse -Force
    }

    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    Write-Host "Linked $Target -> $Source"
}

function Remove-Link {
    param([string]$Target)

    if (Test-Path $Target -PathType Any) {
        Remove-Item $Target -Recurse -Force
        Write-Host "Removed $Target"
    }
}

switch ($Action) {
    "install" {
        if (!(Test-Path $Config)) {
            New-Item -ItemType Directory -Path $Config -Force | Out-Null
        }

        Link-Item "$Root/ghostty"              (Join-Path $Config "ghostty")
        Link-Item "$Root/nvim"                 (Join-Path $Config "nvim")
        Link-Item "$Root/kitty"                (Join-Path $Config "kitty")
        Link-Item "$Root/tmux"                 (Join-Path $Config "tmux")
        Link-Item "$Root/wezterm/.wezterm.lua" $WezTermConfig
        Link-Item "$Root/zsh/.zshrc"           $ZshConfig
        Link-Item "$Root/vscode/settings.json" (Join-Path $VSCodeConfig "settings.json")
    }

    "uninstall" {
        Remove-Link (Join-Path $Config "ghostty")
        Remove-Link (Join-Path $Config "nvim")
        Remove-Link (Join-Path $Config "kitty")
        Remove-Link (Join-Path $Config "tmux")
        Remove-Link $WezTermConfig
        Remove-Link $ZshConfig
        Remove-Link (Join-Path $VSCodeConfig "settings.json")
    }
}

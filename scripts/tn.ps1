#!/usr/bin/env pwsh

param(
    [string] $targetName
)

if (-not $targetName) {
    Write-Host "Usage: tn <target-name>"
    exit 1
}

function CommandExists {
    param (
        [string] $command
    )

    return Test-Path (Get-Command $command -ErrorAction SilentlyContinue).Source
}

function InTmux {
    return -not [string]::IsNullOrEmpty($env:TMUX)
}


if (-not (CommandExists "tmux")) {
    Write-Host "tmux is not installed. Please install tmux to use this script."
    exit 1
}

$targetDir = zoxide query $targetName 2>$null

if (-not $targetDir) {
    Write-Host "Target '$targetName' not found in zoxide database."
    exit 1
}

$dirName = Split-Path $targetDir -Leaf

# Replace dots and colons with underscores to create a valid tmux session name
$sessionName = $dirName -replace '[.:]', '_'

if (tmux has-session -t $sessionName 2>$null) {
    if (-not (InTmux)) {
        tmux attach-session -t $sessionName
    }
    else {
        tmux switch-client -t $sessionName
    }

    exit 0
}

$configFiles = @(
    "tmux-session.json",
    "tmux_session.json"
);

$configFile = $configFiles | ForEach-Object { Join-Path $targetDir $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1

function CreatePanes {
    param (
        [array] $panes,
        [string] $target,
        [string] $workingDir
    )

    for ($i = 0; $i -lt $panes.Count; $i++) {
        $pane = $panes[$i]

        if ($i -gt 0) {
            $splitFlag = if ($pane.split -eq "horizontal") { "-v" } else { "-h" }

            tmux split-window $splitFlag -t $target -c $workingDir
        }

        # If this pane has nested panes, recursively create them
        if ($pane.panes) {
            CreatePanes -panes $pane.panes -target $target -workingDir $workingDir
        }
        # Otherwise, send commands to this pane
        elseif ($pane.command) {
            $paneIndex = tmux display-message -p -t $target "#{pane_index}"
            
            if ($pane.command -is [string]) {
                tmux send-keys -t "${target}.${paneIndex}" $pane.command C-m
            }
            elseif ($pane.command -is [array]) {
                foreach ($cmd in $pane.command) {
                    tmux send-keys -t "${target}.${paneIndex}" $cmd C-m
                }
            }
        }
    }
}

if (-not $configFile) {
    tmux new-session -s $sessionName -c $targetDir
}
else {
    Write-Host "Found tmux session configuration file: $configFile, creating session..."

    tmux new-session -d -s $sessionName -c $targetDir

    $config = Get-Content $configFile -Raw | ConvertFrom-Json

    if ($config.windows) {
        for ($i = 0; $i -lt $config.windows.Count; $i++) {
            $window = $config.windows[$i]
            
            if ($i -eq 0) {
                # Rename the first window created by default
                tmux rename-window -t "${sessionName}:0" $window.name
            }
            else {
                tmux new-window -t $sessionName -n $window.name -c $targetDir
            }

            $windowTarget = "${sessionName}:${i}"
            
            if ($window.panes) {
                CreatePanes -panes $window.panes -target $windowTarget -workingDir $targetDir
            }
        }
    }

    tmux select-layout -t $sessionName tiled
    tmux select-window -t "${sessionName}:0"
    tmux select-pane -t "${sessionName}:0.0"
}

if (InTmux) {
    tmux switch-client -t $sessionName
}
else {
    tmux attach-session -t $sessionName
}



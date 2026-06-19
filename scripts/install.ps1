[CmdletBinding()]
param(
    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"),
    [string]$Repository = "kon-owr/computer-use-repair",
    [string]$Ref = "main"
)

$ErrorActionPreference = "Stop"

$skillName = "computer-use-repair"
$target = Join-Path $CodexHome "skills\$skillName"
$repoRoot = Split-Path -Parent $PSScriptRoot
$localSource = Join-Path $repoRoot "skill\$skillName"

function Install-FromLocal {
    param([string]$Source)

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $Source -Destination (Split-Path -Parent $target) -Recurse -Force
}

function Install-FromGitHub {
    $base = "https://raw.githubusercontent.com/$Repository/$Ref/skill/$skillName"
    $files = @(
        "SKILL.md",
        "agents/openai.yaml",
        "scripts/diagnose-computer-use.ps1"
    )

    if (Test-Path -LiteralPath $target) {
        $backup = "$target.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Move-Item -LiteralPath $target -Destination $backup
        Write-Host "Backed up existing skill to $backup"
    }

    foreach ($file in $files) {
        $destination = Join-Path $target $file
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
        $url = "$base/$file"
        Invoke-WebRequest -Uri $url -OutFile $destination
    }
}

if (Test-Path -LiteralPath (Join-Path $localSource "SKILL.md")) {
    Install-FromLocal -Source $localSource
} else {
    Install-FromGitHub
}

Write-Host "Installed $skillName to $target"
Write-Host "Restart Codex Desktop to refresh skill discovery."

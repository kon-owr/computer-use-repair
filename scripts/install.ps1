[CmdletBinding()]
param(
    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "skill\computer-use-repair"
$target = Join-Path $CodexHome "skills\computer-use-repair"

if (-not (Test-Path -LiteralPath (Join-Path $source "SKILL.md"))) {
    throw "Skill source not found: $source"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
Copy-Item -LiteralPath $source -Destination (Split-Path -Parent $target) -Recurse -Force

Write-Host "Installed computer-use-repair to $target"
Write-Host "Restart Codex Desktop to refresh skill discovery."

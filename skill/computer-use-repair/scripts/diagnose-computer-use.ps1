[CmdletBinding()]
param(
    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"),
    [switch]$SkipDoctor
)

$ErrorActionPreference = "Continue"

function Write-Section {
    param([string]$Name)
    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan
}

function Invoke-Codex {
    param(
        [string]$Exe,
        [string[]]$Arguments
    )

    if (-not $Exe -or -not (Test-Path -LiteralPath $Exe)) {
        Write-Warning "codex.exe is not available; skipped: $($Arguments -join ' ')"
        return
    }

    & $Exe @Arguments
}

$Config = Join-Path $CodexHome "config.toml"
$LocalBin = Join-Path $env:LOCALAPPDATA "OpenAI\Codex\bin"
$CurrentCodex = Get-ChildItem -LiteralPath $LocalBin -Recurse -Filter codex.exe -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
$CodexExe = if ($CurrentCodex) { $CurrentCodex.FullName } else { $null }

Write-Section "Codex executable"
Get-Command codex -ErrorAction SilentlyContinue | Select-Object Name,Source,Path | Format-List
if ($CurrentCodex) {
    $CurrentCodex | Select-Object FullName,LastWriteTime | Format-List
    Invoke-Codex -Exe $CodexExe -Arguments @("--version")
} else {
    Write-Warning "No codex.exe found under $LocalBin"
}

Write-Section "Codex AppX package"
Get-AppxPackage *Codex* -ErrorAction SilentlyContinue |
    Select-Object Name,PackageFullName,InstallLocation,Version |
    Format-List

Write-Section "Relevant config"
if (Test-Path -LiteralPath $Config) {
    Select-String -LiteralPath $Config -Pattern `
        '^model_provider',
        '^base_url',
        '^\[marketplaces\.openai-bundled\]',
        '^source =',
        '^\[mcp_servers\.node_repl\]',
        '^command =',
        '^args =',
        '^startup_timeout_sec =',
        'CODEX_CLI_PATH',
        'NODE_REPL_NODE_MODULE_DIRS',
        'NODE_REPL_NODE_PATH',
        'SKY_CUA' -Context 0,2
} else {
    Write-Warning "Config not found: $Config"
}

if ($CodexExe) {
    $env:CODEX_HOME = $CodexHome

    Write-Section "Feature flags"
    Invoke-Codex -Exe $CodexExe -Arguments @("features", "list") |
        Select-String -Pattern 'browser_use|computer_use|in_app_browser|js_repl'

    Write-Section "Bundled plugin status"
    Invoke-Codex -Exe $CodexExe -Arguments @("plugin", "list") |
        Select-String -Pattern 'Marketplace `openai-bundled`|browser@openai-bundled|chrome@openai-bundled|computer-use@openai-bundled'

    Write-Section "MCP status"
    Invoke-Codex -Exe $CodexExe -Arguments @("mcp", "list") |
        Select-String -Pattern 'node_repl|disable-sandbox|SKY_CUA|NODE_REPL|CODEX_CLI_PATH|enabled'

    if (-not $SkipDoctor) {
        Write-Section "Doctor"
        Invoke-Codex -Exe $CodexExe -Arguments @("doctor", "--all")
    }
}

Write-Section "node_repl processes"
Get-CimInstance Win32_Process -Filter "name = 'node_repl.exe'" -ErrorAction SilentlyContinue |
    Select-Object ProcessId,ParentProcessId,CommandLine,CreationDate |
    Format-List

Write-Section "Computer Use pipes"
Get-ChildItem -Path '\\.\pipe\' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'codex-computer-use|computer-use|cua|codex' } |
    Select-Object Name |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Section "Next checks"
Write-Host "1. plugin list must show browser/chrome/computer-use installed, enabled."
Write-Host "2. mcp list must show node_repl enabled and current SKY_CUA/NODE_REPL/CODEX_CLI_PATH values."
Write-Host "3. If config changed, fully restart Codex Desktop or open a fresh session before retesting."

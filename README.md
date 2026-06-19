# computer-use-repair

Codex skill for diagnosing and repairing Codex Desktop Browser / Computer Use availability issues on Windows.

This project packages a reusable Codex skill that captures a practical repair workflow for cases where Browser or Computer Use appears unavailable after Codex Desktop updates, provider switching, stale bundled plugin paths, `node_repl` runtime drift, or Windows sandbox startup errors.

## What It Checks

- `openai-bundled` marketplace and bundled plugin visibility.
- Browser, Chrome, and Computer Use plugin status.
- `node_repl` MCP configuration and runtime paths.
- `NODE_REPL_*`, `CODEX_CLI_PATH`, and `SKY_CUA_*` environment wiring.
- Computer Use native pipe availability.
- Whether `CreateProcessAsUserW failed: 5` is a real runtime failure or only a stale config symptom.

The skill intentionally treats actual tool behavior as the acceptance standard. For example, `args = []` in `config.toml` is not a failure by itself if Browser / Computer Use works.

## Repository Layout

```text
skill/computer-use-repair/
  SKILL.md
  agents/openai.yaml
  scripts/diagnose-computer-use.ps1
scripts/
  install.ps1
```

## Install

From PowerShell:

```powershell
.\scripts\install.ps1
```

Or copy the skill folder manually:

```powershell
Copy-Item -Recurse -Force .\skill\computer-use-repair "$env:USERPROFILE\.codex\skills\computer-use-repair"
```

Restart Codex Desktop after installing or updating a skill so the skill index can refresh.

## Use

In Codex, invoke:

```text
Use $computer-use-repair to diagnose Browser / Computer Use unavailable on Windows.
```

The bundled read-only diagnostic script can also be run directly:

```powershell
& "$env:USERPROFILE\.codex\skills\computer-use-repair\scripts\diagnose-computer-use.ps1" -SkipDoctor
```

Remove `-SkipDoctor` only when you also want provider/API reachability checks.

## Safety Notes

- The diagnostic script is read-only.
- The skill recommends backing up `config.toml` before any repair.
- Do not blindly force `--disable-sandbox`; only use it when actual `node_repl` execution or direct initialization fails with `CreateProcessAsUserW failed: 5`.
- Provider/API reachability failures are separate from Browser / Computer Use plugin health.

## License

MIT

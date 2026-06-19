# computer-use-repair

English | [简体中文](README.zh-CN.md)

A Codex skill for diagnosing and repairing Codex Desktop Browser and Computer Use runtime issues on Windows.

`computer-use-repair` turns a real Windows repair workflow into a reusable Codex skill. It helps Codex separate plugin visibility problems from `node_repl` runtime failures, stale `openai-bundled` marketplace paths, native-pipe issues, and provider/API reachability noise.

## When To Use It

Use this skill when Codex Desktop shows Browser or Computer Use as unavailable, or when you see symptoms like:

- Browser / Computer Use plugins are installed but still cannot be used.
- `node_repl` fails with `CreateProcessAsUserW failed: 5`.
- `openai-bundled` points to an old Codex Desktop package after an update.
- `CODEX_CLI_PATH`, `NODE_REPL_*`, or `SKY_CUA_*` values look stale.
- Computer Use settings look correct, but actual tool calls still fail.
- A custom provider or API endpoint check fails and you need to prove whether it is unrelated to Computer Use.

## What It Does

The skill follows a layered diagnosis:

1. Confirm `openai-bundled` and bundled plugins are discoverable.
2. Confirm Browser, Chrome, and Computer Use are `installed, enabled`.
3. Inspect `node_repl` MCP command, args, and runtime environment.
4. Check Computer Use native-pipe wiring.
5. Use actual tool behavior as the final acceptance standard.

Important: `args = []` in `config.toml` is not treated as a failure by itself. If Browser / Computer Use works, the repair stops.

## Install

Fast install:

```powershell
irm https://raw.githubusercontent.com/kon-owr/computer-use-repair/main/scripts/install.ps1 | iex
```

Review first, then install:

```powershell
$url = "https://raw.githubusercontent.com/kon-owr/computer-use-repair/main/scripts/install.ps1"
irm $url -OutFile install-computer-use-repair.ps1
notepad .\install-computer-use-repair.ps1
.\install-computer-use-repair.ps1
```

From a cloned repository:

```powershell
git clone https://github.com/kon-owr/computer-use-repair.git
cd computer-use-repair
.\scripts\install.ps1
```

Restart Codex Desktop after installing or updating the skill.

## Use In Codex

Invoke the skill explicitly:

```text
Use $computer-use-repair to diagnose Browser / Computer Use unavailable on Windows.
```

You can also run the bundled read-only diagnostic script directly:

```powershell
& "$env:USERPROFILE\.codex\skills\computer-use-repair\scripts\diagnose-computer-use.ps1" -SkipDoctor
```

Remove `-SkipDoctor` only when you also want provider/API reachability checks.

## Repository Layout

```text
skill/computer-use-repair/
  SKILL.md
  agents/openai.yaml
  scripts/diagnose-computer-use.ps1
scripts/
  install.ps1
```

## Safety

- The diagnostic script is read-only.
- The skill recommends backing up `config.toml` before any repair.
- Do not force `--disable-sandbox` unless real `node_repl` execution or direct initialization fails with `CreateProcessAsUserW failed: 5`.
- Provider/API reachability failures are diagnosed separately from Browser / Computer Use plugin health.

## License

MIT

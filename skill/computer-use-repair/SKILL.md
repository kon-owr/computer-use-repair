---
name: computer-use-repair
description: Diagnose and repair Codex Desktop Browser and Computer Use unavailable on Windows, especially after CCSwitch/provider changes, Codex updates, stale openai-bundled marketplace paths, CODEX_CLI_PATH drift, node_repl sandbox errors like CreateProcessAsUserW failed: 5, missing NODE_REPL_* or SKY_CUA native-pipe settings, or stale MCP sessions.
---

# Computer Use Repair

Use this skill to restore Codex Desktop Browser / Computer Use by proving each layer in order:

1. Marketplace and bundled plugins are discoverable.
2. `node_repl` MCP is wired to a real runtime.
3. Browser / Computer Use plugin scripts can import and reach their helpers.
4. The active Codex Desktop session has been restarted or refreshed after config changes.

Do not treat `doctor` provider reachability as plugin health. A custom provider endpoint can fail network checks while Browser / Computer Use wiring is still valid. Also do not treat `args = []` as a failure by itself; Codex Desktop can regenerate `node_repl` config and still make Computer Use work through the active Desktop runtime. Use real tool behavior as the acceptance standard.

## Quick Diagnosis

Run the bundled read-only script first when possible:

```powershell
& "$env:USERPROFILE\.codex\skills\computer-use-repair\scripts\diagnose-computer-use.ps1" -SkipDoctor
```

Use `-SkipDoctor` when provider/network checks are noisy. Remove it only when the user asks to verify API reachability too.

If the script is unavailable, run these checks manually:

```powershell
$CodexHome = "$env:USERPROFILE\.codex"
$CodexExe = Get-ChildItem -LiteralPath "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 -ExpandProperty FullName

& $CodexExe --version
Select-String -LiteralPath "$CodexHome\config.toml" -Pattern `
  '^model_provider','^base_url','^\[marketplaces\.openai-bundled\]','^source =',`
  '^\[mcp_servers\.node_repl\]','^command =','^args =','CODEX_CLI_PATH',`
  'NODE_REPL_NODE_MODULE_DIRS','NODE_REPL_NODE_PATH','SKY_CUA' -Context 0,2

$env:CODEX_HOME = $CodexHome
& $CodexExe plugin list | Select-String -Pattern 'Marketplace `openai-bundled`|browser@openai-bundled|chrome@openai-bundled|computer-use@openai-bundled'
& $CodexExe mcp list | Select-String -Pattern 'node_repl|disable-sandbox|SKY_CUA|enabled'
Get-ChildItem -Path '\\.\pipe\' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'codex-computer-use' }
```

Expected minimum proof:

- `browser@openai-bundled`, `chrome@openai-bundled`, and `computer-use@openai-bundled` are `installed, enabled`.
- `node_repl` appears in `mcp list` and references an existing command/runtime.
- `SKY_CUA_NATIVE_PIPE=1` and a current `SKY_CUA_NATIVE_PIPE_DIRECTORY` are present when Computer Use is expected to work.

## Repair Order

Back up config before any write:

```powershell
$Config = "$env:USERPROFILE\.codex\config.toml"
Copy-Item -LiteralPath $Config -Destination "$Config.bak-$(Get-Date -Format yyyyMMdd-HHmmss)" -Force
```

Then repair only the failed layer.

### 1. Marketplace Path

If `plugin list` reports a missing or unsupported `openai-bundled` manifest, find the current installed Codex package:

```powershell
Get-AppxPackage *Codex* | Select-Object Name,PackageFullName,InstallLocation,Version | Format-List
```

Set `[marketplaces.openai-bundled].source` to the current package's:

```text
<InstallLocation>\app\resources\plugins\openai-bundled
```

Do not leave it pointing at an older `OpenAI.Codex_26.xxx...` package after a Desktop update.

### 2. CLI And Runtime Drift

If `CODEX_CLI_PATH` points to a deleted hash directory, replace it with the newest `codex.exe` under:

```text
%LOCALAPPDATA%\OpenAI\Codex\bin\<hash>\codex.exe
```

If `node_repl.command` points to a deleted or access-denied runtime, update it to a resolvable `node_repl.exe`. Prefer Codex Desktop's generated runtime when accessible; use a stable copied runtime only as a workaround when WindowsApps/AppData permission boundaries prevent launch.

Use this workaround only when the actual `node_repl` JS tool or a direct `node_repl.exe` initialize check fails with `CreateProcessAsUserW failed: 5`:

```toml
[mcp_servers.node_repl]
args = [ "--disable-sandbox" ]
```

If Codex Desktop later rewrites `args` back to `[]` but Browser / Computer Use works, stop treating that rewrite as a problem.

Do not enable or rely on `js_repl`; in current Codex builds it is not the Browser / Computer Use runtime path.

### 3. NODE_REPL Environment

`NODE_REPL_NODE_MODULE_DIRS` must not be empty if plugin scripts need module resolution. `NODE_REPL_NODE_PATH` should point to an existing Node runtime. Re-check these in `mcp list`, not only by reading `config.toml`.

### 4. Computer Use Native Pipe

Computer Use needs the native helper pipe:

```toml
SKY_CUA_NATIVE_PIPE = "1"
SKY_CUA_NATIVE_PIPE_DIRECTORY = '\\.\pipe\codex-computer-use-...'
```

Never hard-code an old pipe GUID as a permanent fix. Pipe names are session-specific; refresh them from the active Desktop session or restart Codex Desktop so it regenerates the MCP environment.

### 5. Session Reload

After editing `config.toml`, fully restart Codex Desktop or open a fresh session. Existing `mcp__node_repl` transports can stay stale and continue to fail even after the file is correct.

## Error Map

Use these strings to decide the next action:

- `marketplace root does not contain a supported manifest`: update `[marketplaces.openai-bundled].source` to the current Codex package.
- `browser@openai-bundled` or `computer-use@openai-bundled` missing: fix marketplace before touching `node_repl`.
- `CreateProcessAsUserW failed: 5`: if this occurs during actual `node_repl` JS execution or direct initialize, add `--disable-sandbox` to `node_repl` args and verify the command points to an accessible runtime. If only `config.toml` shows `args = []` but Computer Use works, do not repair this.
- `node_repl stdio command not resolvable` or access denied: replace `node_repl.command` with a resolvable runtime path.
- `NODE_REPL_NODE_MODULE_DIRS = ""`: restore module directories for the current runtime.
- `Computer Use native pipe is unavailable`: restore `SKY_CUA_*` from the active Desktop session or restart Desktop.
- `Transport closed`: treat the current MCP connection as stale; verify from a fresh session.
- `OpenAI API base URL ... connect failed`: diagnose provider/network reachability separately from Browser / Computer Use.

## Runtime Import Proof

When `node_repl` is reachable, the final proof is importing the plugin client script and calling a helper:

```js
if (!globalThis.sky) {
  const { setupComputerUseRuntime } = await import("<openai-bundled>/computer-use/<version>/scripts/computer-use-client.mjs");
  await setupComputerUseRuntime({ globals: globalThis });
}
globalThis.apps = await sky.list_apps();
nodeRepl.write(JSON.stringify(apps, null, 2));
```

For Browser, use the equivalent `browser-client.mjs` and `setupBrowserRuntime`. A successful import plus a non-error helper call is stronger evidence than UI settings alone.


# computer-use-repair

[English](README.md) | 简体中文

一个用于诊断和修复 Windows 上 Codex Desktop Browser / Computer Use 运行时问题的 Codex skill。

`computer-use-repair` 把一次真实排障流程整理成可复用的 Codex skill。它帮助 Codex 区分插件可见性问题、`node_repl` 运行时失败、`openai-bundled` marketplace 路径过期、Computer Use native pipe 失效，以及 provider/API 连通性噪声。

## 什么时候使用

当 Codex Desktop 里 Browser 或 Computer Use 显示不可用，或者出现下面情况时使用：

- Browser / Computer Use 插件已经安装，但实际调用仍失败。
- `node_repl` 报 `CreateProcessAsUserW failed: 5`。
- Codex Desktop 更新后，`openai-bundled` 仍指向旧安装包。
- `CODEX_CLI_PATH`、`NODE_REPL_*`、`SKY_CUA_*` 看起来是旧值。
- 设置界面看起来正常，但真实工具调用失败。
- 自定义 provider 或 API endpoint 检查失败，需要判断它是否和 Computer Use 无关。

## 它会检查什么

这个 skill 按分层顺序诊断：

1. 确认 `openai-bundled` 和内置插件能被发现。
2. 确认 Browser、Chrome、Computer Use 是 `installed, enabled`。
3. 检查 `node_repl` MCP 的 command、args 和运行时环境。
4. 检查 Computer Use native pipe。
5. 以真实工具行为作为最终验收标准。

注意：`config.toml` 里的 `args = []` 本身不是故障证据。只要 Browser / Computer Use 实际可用，就不要继续修它。

## 安装

克隆仓库后运行：

```powershell
.\scripts\install.ps1
```

也可以手动复制 skill：

```powershell
Copy-Item -Recurse -Force .\skill\computer-use-repair "$env:USERPROFILE\.codex\skills\computer-use-repair"
```

安装或更新 skill 后，重启 Codex Desktop，让 skill 索引刷新。

## 在 Codex 中使用

显式调用 skill：

```text
Use $computer-use-repair to diagnose Browser / Computer Use unavailable on Windows.
```

也可以直接运行只读诊断脚本：

```powershell
& "$env:USERPROFILE\.codex\skills\computer-use-repair\scripts\diagnose-computer-use.ps1" -SkipDoctor
```

只有当你也想检查 provider/API 连通性时，才去掉 `-SkipDoctor`。

## 仓库结构

```text
skill/computer-use-repair/
  SKILL.md
  agents/openai.yaml
  scripts/diagnose-computer-use.ps1
scripts/
  install.ps1
```

## 安全边界

- 诊断脚本是只读的。
- skill 会建议在任何修复前备份 `config.toml`。
- 不要盲目强制加 `--disable-sandbox`；只有真实 `node_repl` 执行或直接初始化报 `CreateProcessAsUserW failed: 5` 时才使用。
- provider/API 连通性失败要和 Browser / Computer Use 插件健康分开判断。

## 许可证

MIT

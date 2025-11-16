# Claude Code Workflow (CCW) - Installation Guide

**English** | [中文](INSTALL_CN.md)

Interactive installation guide for Claude Code with Agent workflow coordination and distributed memory system.

## ⚡ Quick One-Line Installation

**Windows (PowerShell):**
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1" -UseBasicParsing).Content
```

**Linux/macOS (Bash/Zsh):**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.sh)
```

### Interactive Version Selection

After running the installation command, you'll see an interactive menu with real-time version information:

```
Detecting latest release and commits...
Latest stable: v4.6.0 (2025-10-19 04:27 UTC)
Latest commit: cdea58f (2025-10-19 08:15 UTC)

====================================================
            Version Selection Menu
====================================================

1) Latest Stable Release (Recommended)
   |-- Version: v4.6.0
   |-- Released: 2025-10-19 04:27 UTC
   \-- Production-ready

2) Latest Development Version
   |-- Branch: main
   |-- Commit: cdea58f
   |-- Updated: 2025-10-19 08:15 UTC
   |-- Cutting-edge features
   \-- May contain experimental changes

3) Specific Release Version
   |-- Install a specific tagged release
   \-- Recent: v4.6.0, v4.5.0, v4.4.0

====================================================

Select version to install (1-3, default: 1):
```

**Version Options:**
- **Option 1 (Recommended)**: Latest stable release with verified production quality
- **Option 2**: Latest development version from main branch with newest features
- **Option 3**: Specific version tag for controlled deployments

> 💡 **Pro Tip**: The installer automatically detects and displays the latest version numbers and release dates from GitHub. Just press Enter to select the recommended stable release.

## 📂 Local Installation (Install-Claude.ps1)

For local installation without network access, use the bundled PowerShell installer:

**Installation Modes:**
```powershell
# Interactive mode with prompts (recommended)
.\Install-Claude.ps1

# Quick install with automatic backup
.\Install-Claude.ps1 -Force -BackupAll

# Non-interactive install
.\Install-Claude.ps1 -NonInteractive -Force
```

**Installation Options:**

| Mode | Description | Installs To |
|------|-------------|-------------|
| **Global** | System-wide installation (default) | `~/.claude/`, `~/.codex/`, `~/.gemini/` |
| **Path** | Custom directory + global hybrid | Local: `agents/`, `commands/`<br>Global: `workflows/`, `scripts/` |

**Backup Behavior:**
- **Default**: Automatic backup enabled (`-BackupAll`)
- **Disable**: Use `-NoBackup` flag (⚠️ overwrites without backup)
- **Backup location**: `claude-backup-{timestamp}/` in installation directory

**⚠️ Important Warnings:**
- `-Force -BackupAll`: Silent file overwrite (with backup)
- `-NoBackup -Force`: Permanent file overwrite (no recovery)
- Global mode modifies user profile directories

### ✅ Verify Installation
After installation, open **Claude Code** and check if the workflow commands are available by running:
```bash
/workflow:session:list
```

This command should be recognized in Claude Code's interface. If you see the workflow slash commands (e.g., `/workflow:*`, `/cli:*`), the installation was successful.

> **📝 Installation Notes:**
> - The installer will automatically install/update `.codex/` and `.gemini/` directories
> - **Global mode**: Installs to `~/.codex` and `~/.gemini`
> - **Path mode**: Installs to your specified directory (e.g., `project/.codex`, `project/.gemini`)
> - **Backup**: Existing files are backed up by default to `claude-backup-{timestamp}/`
> - **Safety**: Use interactive mode for first-time installation to review changes

## Platform Requirements

- **Windows**: PowerShell 5.1+ or PowerShell Core 6+
- **Linux/macOS**: Bash/Zsh (for installer) or PowerShell Core 6+ (for manual Install-Claude.ps1)

**Install PowerShell Core (if needed):**
- **Ubuntu/Debian**: `sudo apt install powershell`
- **macOS**: `brew install powershell`
- **Download**: https://github.com/PowerShell/PowerShell

## ⚙️ Configuration

### Tool Control System

CCW uses a **configuration-based tool control system** that makes external CLI tools **optional** rather than required. This allows you to:

- ✅ **Start with Claude-only mode** - Work immediately without installing additional tools
- ✅ **Progressive enhancement** - Add external tools selectively as needed
- ✅ **Graceful degradation** - Automatic fallback when tools are unavailable
- ✅ **Flexible configuration** - Control tool availability per project

**Configuration File**: `~/.claude/workflows/tool-control.yaml`

```yaml
tools:
  gemini:
    enabled: false  # Optional: AI analysis & documentation
  qwen:
    enabled: true   # Optional: AI architecture & code generation
  codex:
    enabled: true   # Optional: AI development & implementation
```

**Behavior**:
- **When disabled**: CCW automatically falls back to other enabled tools or Claude's native capabilities
- **When enabled**: Uses specialized tools for their specific strengths
- **Default**: All tools disabled - Claude-only mode works out of the box

### Optional CLI Tools *(Enhanced Capabilities)*

While CCW works with Claude alone, installing these tools provides enhanced analysis and extended context:

#### System Utilities

| Tool | Purpose | Installation |
|------|---------|--------------|
| **ripgrep (rg)** | Fast code search | **macOS**: `brew install ripgrep`<br>**Linux**: `apt install ripgrep` (Ubuntu) / `dnf install ripgrep` (Fedora)<br>**Windows**: `winget install ripgrep` / `choco install ripgrep` / `scoop install ripgrep`<br>**Verify**: `rg --version` |
| **TOON CLI 工具链** | Inspect/convert `.toon` 任务文件并替代 jq | **Bundled**: 已包含在仓库中，运行 `npm install` 后使用 `npm run toon -- [encode|decode|detect|auto]` 或直接执行 `./scripts/toon-wrapper.sh`。需要 Node.js 18+ 与 `npx tsx`。<br>**Verify**: `npm run toon -- detect path/to/IMPL-004.toon` |

#### External AI Tools

Configure these tools in `~/.claude/workflows/tool-control.yaml` after installation:

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Gemini CLI** | AI analysis & documentation | Follow [official docs](https://ai.google.dev) - Free quota, extended context |
| **Codex CLI** | AI development & implementation | Follow [official docs](https://github.com/openai/codex) - Autonomous development |
| **Qwen Code** | AI architecture & code generation | Follow [official docs](https://github.com/QwenLM/qwen-code) - Large context window |

### Recommended: MCP Tools *(Enhanced Analysis)*

MCP (Model Context Protocol) tools provide advanced codebase analysis. **Recommended installation** - While CCW has fallback mechanisms, not installing MCP tools may lead to unexpected behavior or degraded performance in some workflows.

| MCP Server | Purpose | Installation Guide |
|------------|---------|-------------------|
| **Exa MCP** | External API patterns & best practices | [Install Guide](https://smithery.ai/server/exa) |
| **Code Index MCP** | Advanced internal code search | [Install Guide](https://github.com/johnhuang316/code-index-mcp) |
| **Chrome DevTools MCP** | ⚠️ **Required for UI workflows** - URL mode design extraction | [Install Guide](https://github.com/ChromeDevTools/chrome-devtools-mcp) |

⚠️ **Note**: Some workflows expect MCP tools to be available. Without them, you may experience:
- Slower code analysis and search operations
- Reduced context quality in some scenarios
- Fallback to less efficient traditional tools
- Potential unexpected behavior in advanced workflows

## Troubleshooting

### PowerShell Execution Policy (Windows)
If you get execution policy errors:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Workflow Commands Not Working
- Verify installation: `ls ~/.claude` (should show agents/, commands/, workflows/)
- Restart Claude Code after installation
- Check `/workflow:session:list` command is recognized

### Permission Errors
- **Windows**: Run PowerShell as Administrator
- **Linux/macOS**: May need `sudo` for global PowerShell installation

## Support

- **Issues**: [GitHub Issues](https://github.com/ding113/Claude-Code-Workflow/issues)
- **Getting Started**: [Quick Start Guide](GETTING_STARTED.md)
- **Documentation**: [Main README](README.md)

# Claude Code Workflow (CCW) - 安装指南

[English](INSTALL.md) | **中文**

Claude Code Agent 工作流协调和分布式内存系统的交互式安装指南。

> **版本 5.0：精简化安装** - 移除了外部 MCP 依赖，安装更简单、更稳定。使用标准工具（ripgrep/find）提供更好的性能和兼容性。

## ⚡ 一键远程安装（推荐）

### 所有平台 - 远程 PowerShell 安装
```powershell
# 从功能分支进行交互式远程安装（最新版本）
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1)

# 包含统一文件输出系统的全局安装
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -Global

# 强制覆盖（非交互式）- 包含所有新的工作流文件生成功能
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -Force -NonInteractive

# 一键备份所有现有文件（无需确认）
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -BackupAll
```

**远程安装器的功能：**
- ✅ 检查系统要求（PowerShell 版本、网络连接）
- ✅ 从 GitHub 下载最新版本（main 分支）
- ✅ 包含所有新的统一文件输出系统功能
- ✅ 自动解压并运行本地安装程序
- ✅ 安全确认和用户提示
- ✅ 自动清理临时文件
- ✅ 设置 .workflow/ 目录结构进行会话管理

**注意**：为了跨平台兼容性，界面使用英文

## 📂 本地安装

### 所有平台（PowerShell）
```powershell
# 克隆包含最新功能的仓库
cd Claude-Code-Workflow

# Windows PowerShell 5.1+ 或 PowerShell Core（仅支持全局安装）
.\Install-Claude.ps1

# Linux/macOS PowerShell Core（仅支持全局安装）
pwsh ./Install-Claude.ps1
```

**注意**：功能分支包含所有最新的统一文件输出系统增强功能，应用于新安装。

## 安装选项

### 远程安装参数

所有参数都可以传递给远程安装器：

```powershell
# 全局安装
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -Global

# 安装到指定目录
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -Directory "C:\MyProject"

# 强制覆盖而不提示
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -Force -NonInteractive

# 从特定分支安装
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -Branch "dev"

# 跳过备份（更快）
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -NoBackup
```

### 本地安装选项

### 全局安装（默认且唯一模式）
安装到用户主目录（`~/.claude`）：
```powershell
# 所有平台 - 全局安装（默认）
.\Install-Claude.ps1

# 自动备份（从 v1.1.0 开始默认）
.\Install-Claude.ps1 -BackupAll

# 禁用自动备份（不推荐）
.\Install-Claude.ps1 -NoBackup

# 自动化的非交互式模式
.\Install-Claude.ps1 -Force -NonInteractive
```

**全局安装结构：**
```
~/.claude/
├── agents/
├── commands/
├── output-styles/
├── settings.local.json
└── CLAUDE.md
```

**注意**：从 v1.2.0 开始，仅支持全局安装。移除了本地目录和自定义路径安装，以简化安装流程并确保所有平台的一致行为。

## 高级选项

### 强制安装
覆盖现有文件：
```powershell
.\Install-Claude.ps1 -Force
```

### 跳过备份
不创建备份文件：
```powershell
.\Install-Claude.ps1 -NoBackup
```

### 卸载
删除安装：
```powershell
.\Install-Claude.ps1 -Uninstall -Force
```

## 平台要求

### PowerShell（推荐）
- **Windows**：PowerShell 5.1+ 或 PowerShell Core 6+
- **Linux**：PowerShell Core 6+
- **macOS**：PowerShell Core 6+

安装 PowerShell Core：
- **Ubuntu/Debian**：`sudo apt install powershell`
- **CentOS/RHEL**：`sudo dnf install powershell`
- **macOS**：`brew install powershell`
- **或下载**：https://github.com/PowerShell/PowerShell

## 完整安装示例

### ⚡ 超快速（一键）
```powershell
# 一条命令完成安装
iex (iwr -useb https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1) -Global

# 完成！🎉
# 开始使用 Claude Code Agent 工作流！
```

### 📂 手动安装方法
```powershell
# 手动安装步骤：
# 1. 安装 PowerShell Core（如果需要）
# Windows：从 GitHub 下载
# Linux：sudo apt install powershell
# macOS：brew install powershell

# 2. 下载 Claude Code 工作流系统
git clone https://github.com/catlog22/Claude-CCW.git
cd Dmsflow

# 3. 全局安装（交互式）
.\Install-Claude.ps1 -Global

# 4. 开始使用 Claude Code Agent 工作流！
# 使用 /workflow 命令和内存系统进行开发
```

## 先决条件和推荐工具

为了充分发挥 CCW 的全部潜力，强烈建议安装这些额外工具。

### 系统工具 (推荐)

这些工具增强了文件搜索和数据处理能力。

-   **`ripgrep` (rg)**: 一款高速代码搜索工具。
    -   **Windows**:
        -   **WinGet**: `winget install ripgrep` (推荐，自动选择 MSVC 版本)
        -   **Chocolatey**: `choco install ripgrep`
        -   **Scoop**: `scoop install ripgrep`
        -   **手动下载**: 从 [GitHub Releases](https://github.com/BurntSushi/ripgrep/releases) 下载预编译二进制文件
    -   **macOS**: `brew install ripgrep`
    -   **Linux**: `sudo apt-get install ripgrep` (Debian/Ubuntu) 或 `sudo dnf install ripgrep` (Fedora)
    -   **验证**: `rg --version`

-   **`jq`**: 一款命令行 JSON 处理器。
    -   **Windows**:
        -   **WinGet**: `winget install jq` (推荐)
        -   **Chocolatey**: `choco install jq`
        -   **Scoop**: `scoop install jq`
        -   **手动下载**: 从 [GitHub Releases](https://github.com/jqlang/jq/releases) 下载 `jq-windows-amd64.exe` 并重命名为 `jq.exe`
    -   **macOS**: `brew install jq`
    -   **Linux**: `sudo apt-get install jq` (Debian/Ubuntu) 或 `sudo dnf install jq` (Fedora)
    -   **验证**: `jq --version`

### 模型上下文协议 (MCP) 工具 (可选)

MCP 工具从外部来源提供高级上下文检索，增强 AI 的理解能力。关于安装，请参考各个工具的官方文档。

| 工具 | 用途 | 官方源码 |
|---|---|---|
| **Exa MCP** | 用于搜索代码和网络。 | [exa-labs/exa-mcp-server](https://github.com/exa-labs/exa-mcp-server) |
| **Code Index MCP** | 用于索引和搜索本地代码库。 |[johnhuang316/code-index-mcp](https://github.com/johnhuang316/code-index-mcp) |
| **Chrome DevTools MCP** | 用于与网页交互以提取布局和样式信息。 | [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) |

-   **先决条件**: Node.js 和 npm (或兼容的 JavaScript 运行时)。
-   **验证**: 安装后，检查服务器是否可以启动 (具体请查阅 MCP 文档)。

### 可选的 AI CLI 工具

CCW 使用包装脚本与底层的 AI 模型进行交互。为了使这些包装器正常工作，必须在您的系统上安装和配置相应的 CLI 工具。

-   **Gemini CLI**: 用于分析、文档和探索。
    -   **用途**: 提供对 Google Gemini 模型的访问。
    -   **安装**: 请遵循 Google AI 官方文档来安装和配置 Gemini CLI。确保 `gemini` 命令在您的系统 PATH 中可用。

-   **Codex CLI**: 用于自主开发和实现。
    -   **用途**: 提供对 OpenAI Codex 模型的访问，用于代码生成和修改。
    -   **安装**: 请遵循您环境中使用的特定 Codex CLI 工具的安装说明。确保 `codex` 命令在您的系统 PATH 中可用。

-   **Qwen Code**: 用于架构和代码生成。
    -   **用途**: 提供对阿里巴巴通义千问模型的访问。
    -   **安装**: 请遵循通义千问官方文档来安装和配置其 CLI 工具。确保 `qwen` 命令在您的系统 PATH 中可用。

## 验证

安装后，验证：

1. **检查安装：**
   ```bash
   # 全局
   ls ~/.claude
   
   # 本地
   ls ./.claude
   ```

2. **测试 Claude Code：**
   - 在项目中打开 Claude Code
   - 检查全局 `.claude` 目录是否被识别
   - 验证工作流命令和内存命令是否可用
   - 测试 `/workflow` 命令的 Agent 协调功能
   - 测试 `/workflow version` 检查版本信息

## 故障排除

### PowerShell 执行策略
如果出现执行策略错误：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 工作流命令无效
- 确保项目中存在 `.claude` 目录
- 验证 workflow.md 和 agent 文件是否正确安装
- 检查 Claude Code 是否识别配置

### 权限错误
- **Windows**：以管理员身份运行
- **Linux/macOS**：如果需要全局 PowerShell 安装，使用 `sudo`

## 安装器功能说明

### 🛡️ 用户配置保护
安装器会智能处理现有文件：
- **新文件**：直接复制
- **非配置文件**：覆盖更新
- **用户配置文件**（如 `settings.local.json`）：提供选项
  - 保留现有文件（推荐）
  - 覆盖为新文件
  - 备份后覆盖

### 📦 安全卸载
卸载时保护用户数据：
- **选项 1**：仅删除安装的文件（保留用户配置）
- **选项 2**：删除整个目录（需要二次确认）
- **选项 3**：不删除任何内容

### 🔄 智能备份
- 自动为现有文件创建带时间戳的备份
- 备份文件格式：`filename.backup_yyyyMMdd_HHmmss`
- 可以使用 `-NoBackup` 跳过备份

## 常见问题

**Q：为什么安装器界面是英文的？**
A：为了确保跨平台兼容性并避免字符编码问题，安装器使用英文界面。

**Q：可以自定义安装位置吗？**
A：是的，使用 `-Directory` 参数指定任何位置。

**Q：如何更新到最新版本？**
A：再次运行一键安装命令，它会自动获取最新版本。

**Q：卸载会删除我的配置吗？**
A：默认情况下，卸载只删除我们安装的文件，保留您的个人配置。

## 支持

- **问题**：[GitHub Issues](https://github.com/catlog22/Claude-CCW/issues)
- **文档**：[主 README](README_CN.md)
- **工作流文档**：[.claude/commands/workflow.md](.claude/commands/workflow.md)
# 🚀 Claude Code Workflow (CCW)

<div align="center">

[![Version](https://img.shields.io/badge/version-v5.5.0-blue.svg)](https://github.com/ding113/Claude-Code-Workflow/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()

**语言:** [English](README.md) | [中文](README_CN.md)

</div>

---

**Claude Code Workflow (CCW)** 将 AI 开发从简单的提示词链接转变为一个强大的、上下文优先的编排系统。它通过结构化规划、确定性执行和智能多模型编排，解决了执行不确定性和误差累积的问题。

> **🎉 版本 5.5: 交互式命令指南与增强文档**
>
> **核心改进**:
> - ✨ **命令指南技能** - 交互式帮助系统，支持 CCW-help 和 CCW-issue 触发
> - ✨ **增强命令描述** - 所有 69 个命令更新了详细功能描述
> - ✨ **5 索引命令系统** - 按分类、使用场景、关系和核心命令组织
> - ✨ **智能推荐** - 基于上下文的工作流引导建议
>
> 详见 [CHANGELOG.md](CHANGELOG.md)。

> 📚 **第一次使用 CCW？** 查看 [**快速上手指南**](GETTING_STARTED_CN.md) 获取新手友好的 5 分钟教程！

---

## ✨ 核心概念

CCW 构建在一系列核心原则之上，这些原则使其与传统的 AI 开发方法区别开来：

- **上下文优先架构**: 通过预定义的上下文收集，消除了执行过程中的不确定性，确保智能体在实现*之前*就拥有正确的信息。
- **TOON 优先的状态管理**: 任务状态存储在 `.task/IMPL-*.toon` 包中，相比等效的 JSON 转储可节省 30-60% 的令牌（通过 `tests/integration/toon-format.test.ts` 基准测试），在保持人类可读性的同时扩展上下文容量。`src/utils/toon.ts` 中的工具通过 `autoDecode()` 保持 JSON 互操作性，使旧任务文件无需手动转换即可继续工作。
- **自主多阶段编排**: 命令链式调用专门的子命令和智能体，以零用户干预的方式自动化复杂的工作流。
- **多模型策略**: 充分利用不同 AI 模型（如 Gemini 用于分析，Codex 用于实现）的独特优势，以获得更优越的结果。
- **分层内存系统**: 一个 4 层文档系统，在适当的抽象级别上提供上下文，防止信息过载。
- **专门的基于角色的智能体**: 一套模拟真实软件团队的智能体（`@code-developer`, `@test-fix-agent` 等），用于处理多样化的任务。

---

## ⚙️ 安装

有关详细的安装说明，请参阅 [**INSTALL_CN.md**](INSTALL_CN.md) 指南。

### **🚀 一键快速安装**

**Windows (PowerShell):**
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1" -UseBasicParsing).Content
```

**Linux/macOS (Bash/Zsh):**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.sh)
```

### **✅ 验证安装**
安装后，打开 **Claude Code** 并通过运行以下命令检查工作流命令是否可用：
```bash
/workflow:session:list
```
如果斜杠命令（例如 `/workflow:*`）被识别，则表示安装成功。

---

## 🛠️ 命令参考

CCW 提供了一套丰富的命令，用于管理工作流、任务以及与 AI 工具的交互。有关所有可用命令的完整列表和详细说明，请参阅 [**COMMAND_REFERENCE.md**](COMMAND_REFERENCE.md) 文件。

有关每个命令的详细技术规范，请参阅 [**COMMAND_SPEC.md**](COMMAND_SPEC.md)。

---

### 💡 **需要帮助？使用交互式命令指南**

CCW 包含内置的**命令指南技能**，帮助您有效地发现和使用命令：

- **`CCW-help`** - 获取交互式帮助和命令推荐
- **`CCW-issue`** - 使用引导模板报告错误或请求功能

命令指南提供：
- 🔍 **智能命令搜索** - 按关键词、分类或使用场景查找命令
- 🤖 **下一步推荐** - 获取任何命令之后的操作建议
- 📖 **详细文档** - 查看参数、示例和最佳实践
- 🎓 **新手入门** - 通过引导式学习路径学习 14 个核心命令
- 📝 **问题报告** - 生成标准化的错误报告和功能请求

**使用示例**:
```
用户: "CCW-help"
→ 交互式菜单，包含命令搜索、推荐和文档

用户: "执行完 /workflow:plan 后做什么？"
→ 推荐 /workflow:execute、/workflow:action-plan-verify 及工作流模式

用户: "CCW-issue"
→ 引导式模板生成，用于错误、功能或问题咨询
```

---

## 🚀 快速入门

开始使用的最佳方式是遵循 [**快速上手指南**](GETTING_STARTED_CN.md) 中的 5 分钟教程。

以下是一个常见开发工作流的快速示例：

1.  **创建计划**（自动启动会话）:
    ```bash
    /workflow:plan "实现基于 JWT 的用户登录和注册"
    ```
2.  **执行计划**:
    ```bash
    /workflow:execute
    ```
3.  **查看状态**（可选）:
    ```bash
    /workflow:status
    ```

---

## 🤝 贡献与支持

- **仓库**: [GitHub - Claude-Code-Workflow](https://github.com/ding113/Claude-Code-Workflow)
- **问题**: 在 [GitHub Issues](https://github.com/ding113/Claude-Code-Workflow/issues) 上报告错误或请求功能。
- **讨论**: 加入 [社区论坛](https://github.com/ding113/Claude-Code-Workflow/discussions)。

## 📄 许可证

此项目根据 **MIT 许可证** 授权。详见 [LICENSE](LICENSE) 文件。
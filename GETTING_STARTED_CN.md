
# 🚀 Claude Code Workflow (CCW) - 快速上手指南

欢迎来到 Claude Code Workflow (CCW) v5.0！本指南将帮助您在 5 分钟内快速入门，体验由 AI 驱动的自动化软件开发流程，以及我们全新的精简化、零外部依赖的工作流系统。

**项目地址**：[ding113/Claude-Code-Workflow](https://github.com/ding113/Claude-Code-Workflow)

> **🎉 v5.0 新特性：少即是多**！我们移除了外部 MCP 依赖，简化了工作流程。CCW 现在使用标准工具（ripgrep/find）以获得更好的稳定性和性能。头脑风暴工作流专注于角色分析，使规划更加清晰。

---

## ⏱️ 5 分钟快速入门

让我们通过一个简单的例子，从零开始构建一个 "Hello World" Web 应用。

### 第 1 步：安装 CCW

首先，请确保您已经根据 [安装指南](INSTALL_CN.md) 完成了 CCW 的安装。

### 第 2 步：创建执行计划（会自动启动会话）

直接告诉 CCW 您想做什么。CCW 会分析您的需求，并自动生成一个详细的、可执行的任务计划。

```bash
/workflow:plan "创建一个简单的 Express API，在根路径返回 Hello World"
```

> **💡 提示**：`/workflow:plan` 会自动创建和启动工作流会话，无需手动执行 `/workflow:session:start`。会话会根据任务描述自动命名，例如 `WFS-创建一个简单的-express-api`。

这个命令会启动一个完全自动化的规划流程，包括：
1.  **上下文收集**：分析您的项目环境。
2.  **智能体分析**：AI 智能体思考最佳实现路径。
3.  **任务生成**：以 TOON 格式（如 `.toon` 文件）创建具体的任务文件。

### 第 3 步：执行计划

当计划创建完毕后，您就可以命令 AI 智能体开始工作了。

```bash
/workflow:execute
```

您会看到 CCW 的智能体（如 `@code-developer`）开始逐一执行任务。它会自动创建文件、编写代码、安装依赖。

### 第 4 步：查看状态

想知道进展如何？随时可以查看当前工作流的状态。

```bash
/workflow:status
```

这会显示任务的完成情况、当前正在执行的任务以及下一步计划。

---

## 🧠 核心概念解析

理解这几个概念，能帮助您更好地使用 CCW：

-   **工作流会话 (Workflow Session)**
    > 就像一个独立的沙盒或项目空间，用于隔离不同任务的上下文、文件和历史记录。所有相关文件都存放在 `.workflow/WFS-<会话名>/` 目录下。

-   **任务 (Task)**
    > 一个原子化的工作单元，例如“创建 API 路由”、“编写测试用例”。每个任务以 TOON 格式（如 `.toon`）存储，用紧凑、可读的结构描述目标、上下文和执行步骤。

    TOON 任务示例：
    ```toon
    id: IMPL-001
    title: 创建 Hello World 接口
    agent: @code-developer
    priority: medium
    status: pending
    steps[3]{name,status}:
      分析项目上下文,pending
      实现 GET / 处理器,pending
      添加请求测试,pending
    ```

    > **💡 TOON 格式优势**: TOON (Token-Oriented Object Notation) 相比 JSON 可节省 30-60% 的令牌使用，同时保持更好的人类可读性。所有任务文件现在都使用 `.toon` 扩展名。系统通过 `autoDecode()` 自动兼容旧的 JSON 格式文件。

-   **智能体 (Agent)**
    > 专门负责特定领域工作的 AI 助手。例如：
    > -   `@code-developer`: 负责编写和实现代码。
    > -   `@test-fix-agent`: 负责运行测试并自动修复失败的用例。
    > -   `@ui-design-agent`: 负责 UI 设计和原型创建。
    > -   `@cli-execution-agent`: 负责自主 CLI 任务处理（v4.5.0+）。

-   **工作流 (Workflow)**
    > 一系列预定义的、相互协作的命令，用于编排不同的智能体和工具，以完成一个复杂的开发目标（如 `plan`、`execute`、`test-gen`）。

---

## 🛠️ 常见场景示例

### 场景 1：快速功能开发

对于简单、明确的功能，使用直接的"规划 → 执行"模式：

```bash
# 创建计划（自动创建会话）
/workflow:plan "实现基于 JWT 的用户登录和注册功能"

# 执行
/workflow:execute
```

> **💡 提示**：`/workflow:plan` 会自动创建会话。您也可以先手动启动会话：`/workflow:session:start "功能名称"`。

### 场景 2：UI 设计探索

对于以 UI 为重点的项目，在实现前先进行设计探索：**ui-design → update → 规划 → 执行**

```bash
# 第 1 步：生成 UI 设计变体（自动创建会话）
/workflow:ui-design:explore-auto --prompt "一个现代、简洁的管理后台登录页面"

# 第 2 步：在 compare.html 中审查设计，然后同步设计系统到头脑风暴工件
/workflow:ui-design:design-sync --session <session-id> --selected-prototypes "login-v1,login-v2"

# 第 3 步：使用设计引用生成实现计划
/workflow:plan

# 第 4 步：执行实现
/workflow:execute
```

> **💡 提示**：`update` 命令将选定的设计原型集成到头脑风暴工件中，确保实现遵循批准的设计。

### 场景 3：复杂功能的多智能体头脑风暴

对于需要深入分析的复杂功能，使用完整工作流：**头脑风暴 → 规划 → 执行**

```bash
# 第 1 步：多智能体头脑风暴（自动创建会话）
/workflow:brainstorm:auto-parallel "设计一个支持冲突解决的实时协作文档编辑系统"

# 可选：指定专家角色数量（默认：3，最大：9）
/workflow:brainstorm:auto-parallel "构建可扩展的微服务平台" --count 5

# 第 2 步：从头脑风暴结果生成实现计划
/workflow:plan

# 第 3 步：执行计划
/workflow:execute
```

**头脑风暴优势**：
- **自动角色选择**：分析主题并选择 3-9 个相关专家角色（系统架构师、UI 设计师、产品经理等）
- **并行执行**：多个 AI 智能体从不同视角同时分析
- **综合规格说明**：生成整合的需求和设计文档

**何时使用头脑风暴**：
- 需要多视角分析的复杂功能
- 具有重大影响的架构决策
- 实现前需要详尽需求分析

### 场景 4：质量保证 - 行动计划验证

规划后，验证您的实现计划的一致性和完整性：

```bash
# /workflow:plan 完成后，验证任务质量
/workflow:action-plan-verify

# 该命令将：
# 1. 检查需求覆盖率（所有需求都有任务）
# 2. 验证任务依赖关系（无循环或损坏的依赖）
# 3. 确保综合对齐（任务符合架构决策）
# 4. 评估任务规范质量
# 5. 生成详细的验证报告和修复待办事项
```

**验证报告包括**：
- 需求覆盖率分析
- 依赖关系图验证
- 综合对齐检查
- 任务规范质量评估
- 优先级修复建议

**使用时机**：
- 在 `/workflow:plan` 生成 IMPL_PLAN.md 和任务文件后
- 在开始 `/workflow:execute` 之前
- 处理具有许多依赖关系的复杂项目时
- 当您想确保高质量的任务规范时

**优势**：
- 在执行前捕获规划错误
- 确保完整的需求覆盖
- 验证架构一致性
- 识别资源冲突和技能差距
- 提供可执行的修复计划，集成 TodoWrite

### 场景 6：Bug 修复

快速 Bug 分析和修复工作流：

```bash
# 分析 Bug
/cli:mode:bug-index "密码错误时仍显示成功消息"

# Claude 会分析后直接根据分析结果实现修复
```

---

## 🔧 无工作流协作：独立工具使用

除了完整的工作流模式，CCW 还提供独立的 CLI 工具和命令，适合快速分析、临时查询和日常维护任务。

### CLI 工具直接调用

CCW 支持通过统一的 CLI 接口直接调用外部 AI 工具（Gemini、Qwen、Codex），无需创建工作流会话。

#### 代码分析

快速分析项目代码结构和架构模式：

```bash
# 使用 Gemini 进行代码分析
/cli:analyze --tool gemini "分析认证模块的架构设计"

# 使用 Qwen 分析代码质量
/cli:analyze --tool qwen "检查数据库模型的设计是否合理"
```

#### 交互式对话

与 AI 工具进行直接交互式对话：

```bash
# 与 Gemini 交互
/cli:chat --tool gemini "解释一下 React Hook 的使用场景"

# 与 Codex 交互讨论实现方案
/cli:chat --tool codex "如何优化这个查询性能"
```

#### 专业模式分析

使用特定的分析模式进行深度探索：

```bash
# 架构分析模式
/cli:mode:plan --tool gemini "设计一个可扩展的微服务架构"

# 深度代码分析
/cli:mode:code-analysis --tool qwen "分析 src/utils/ 目录下的工具函数"

# Bug 分析模式
/cli:mode:bug-index --tool gemini "分析内存泄漏问题的可能原因"
```

### 工具语义调用

用户可以通过自然语言告诉 Claude 使用特定工具完成任务，Claude 会理解意图并自动执行相应的命令。

#### 语义调用示例

直接在对话中使用自然语言描述需求：

**示例 1：代码分析**
```
用户："使用 gemini 分析一下这个项目的模块化架构"
→ Claude 会自动执行 gemini-wrapper 进行分析
```

**示例 2：文档生成**
```
用户："用 gemini 生成 API 文档，包含所有端点的说明"
→ Claude 会理解需求，自动调用 gemini 的写入模式生成文档
```

**示例 3：代码实现**
```
用户："使用 codex 实现用户登录功能"
→ Claude 会调用 codex 工具进行自主开发
```

#### 语义调用的优势

- **自然交互**：无需记忆复杂的命令语法
- **智能理解**：Claude 会根据上下文选择合适的工具和参数
- **自动优化**：Claude 会自动添加必要的上下文和配置

### 内存管理：CLAUDE.md 更新

CCW 使用分层的 CLAUDE.md 文档系统维护项目上下文。定期更新这些文档对保证 AI 输出质量至关重要。

#### 完整项目重建索引

适用于大规模重构、架构变更或初次使用 CCW：

```bash
# 重建整个项目的文档索引
/memory:update-full

# 使用特定工具进行索引
/memory:update-full --tool gemini   # 全面分析（推荐）
/memory:update-full --tool qwen     # 架构重点
/memory:update-full --tool codex    # 实现细节
```

**执行时机**：
- 项目初始化时
- 架构重大变更后
- 每周定期维护
- 发现 AI 输出偏差时

#### 快速加载特定任务上下文

当您需要立即获取特定任务的上下文，而无需更新文档时：

```bash
# 为特定任务加载上下文到内存
/memory:load "在当前前端基础上开发用户认证功能"

# 使用其他 CLI 工具进行分析
/memory:load --tool qwen "重构支付模块API"
```

**工作原理**：
- 委托 AI 智能体进行自主项目分析
- 发现相关文件并提取任务特定关键词
- 使用 CLI 工具（Gemini/Qwen）进行深度分析以节省令牌
- 返回加载到内存中的结构化"核心内容包"
- 为后续智能体操作提供上下文

**使用时机**：
- 开始新功能或任务之前
- 需要快速获取上下文而无需完整文档重建时
- 针对特定任务的架构或模式发现
- 作为基于智能体开发工作流的准备工作

#### 增量更新相关模块

适用于日常开发，只更新变更影响的模块：

```bash
# 更新最近修改相关的文档
/memory:update-related

# 指定工具进行更新
/memory:update-related --tool gemini
```

**执行时机**：
- 完成功能开发后
- 重构某个模块后
- 更新 API 接口后
- 修改数据模型后

#### 内存质量的影响

| 更新频率 | 结果 |
|---------|------|
| ❌ 从不更新 | 过时的 API 引用、错误的架构假设、低质量输出 |
| ⚠️ 偶尔更新 | 部分上下文准确、可能出现不一致 |
| ✅ 及时更新 | 高质量输出、精确的上下文、正确的模式引用 |

### CLI 工具初始化

首次使用外部 CLI 工具时，可以使用初始化命令快速配置：

```bash
# 自动配置所有工具
/cli:cli-init

# 只配置特定工具
/cli:cli-init --tool gemini
/cli:cli-init --tool qwen
```

该命令会：
- 分析项目结构
- 生成工具配置文件
- 设置 `.geminiignore` / `.qwenignore`
- 创建上下文文件引用

---

## 🎯 进阶用法：智能体技能 (Agent Skills)

智能体技能是可扩展 AI 功能的模块化、可复用能力。它们存储在 `.claude/skills/` 目录中,通过特定的触发机制调用。

### 技能工作原理

-   **模型调用**：与斜杠命令不同,您不直接调用技能。AI 会根据对您目标的理解来决定何时使用技能。
-   **上下文化**：技能为 AI 提供特定的指令、脚本和模板,用于专门化任务。
-   **触发机制**：
    -   **对话触发**：在**自然对话**中使用 `-e` 或 `--enhance` 标识符来触发 `prompt-enhancer` 技能
    -   **CLI 命令增强**：在 **CLI 命令**中使用 `--enhance` 标识符进行提示词优化(这是 CLI 功能,不是技能触发)

### 使用示例

**对话触发** (激活 prompt-enhancer 技能):
```
用户: "分析认证模块 -e"
→ AI 使用 prompt-enhancer 技能扩展请求
```

**CLI 命令增强** (CLI 内置功能):
```bash
# 这里的 --enhance 标识符是 CLI 参数,不是技能触发器
/cli:analyze --enhance "检查安全问题"
```

**重要说明**：`-e` 标识符仅在自然对话中有效,而 CLI 命令中的 `--enhance` 是独立的增强机制,与技能系统无关。

---

## 🎨 进阶用法：UI 设计工作流

CCW 包含强大的多阶段 UI 设计和原型制作工作流,能够从简单的描述或参考图像生成完整的设计系统和交互式原型。

### 核心命令

-   `/workflow:ui-design:explore-auto`: 探索性工作流,基于提示词生成多种不同的设计变体。
-   `/workflow:ui-design:imitate-auto`: 复制工作流,从参考 URL 创建高保真原型。

### 示例：从提示词生成 UI

您可以使用单个命令为网页生成多种设计选项:

```bash
# 此命令将为登录页面生成 3 种不同的样式和布局变体
/workflow:ui-design:explore-auto --prompt "一个现代简洁的 SaaS 应用登录页面" --targets "login" --style-variants 3 --layout-variants 3
```

工作流完成后,会提供一个 `compare.html` 文件,让您可以可视化地查看和选择最佳设计组合。

---

## ❓ 常见问题排查 (Troubleshooting)

-   **问题：提示 "No active session found" (未找到活动会话)**
    > **原因**：您还没有启动一个工作流会话，或者当前会话已完成。
    > **解决方法**：使用 `/workflow:session:start "您的任务描述"` 来开始一个新会话。

-   **问题：命令执行失败或卡住**
    > **原因**：可能是网络问题、AI 模型限制或任务过于复杂。
    > **解决方法**：
    > 1.  首先尝试使用 `/workflow:status` 检查当前状态。
    > 2.  查看 `.workflow/WFS-<会话名>/.chat/` 目录下的日志文件，获取详细错误信息。
    > 3.  如果任务过于复杂，尝试将其分解为更小的任务，然后使用 `/workflow:plan` 重新规划。

---

## 📚 进阶学习路径

当您掌握了基础用法后，可以探索 CCW 更强大的功能：

1.  **测试驱动开发 (TDD)**: 使用 `/workflow:tdd-plan` 来创建一个完整的 TDD 工作流，AI 会先编写失败的测试，然后编写代码让测试通过，最后进行重构。

2.  **多智能体头脑风暴**: 使用 `/workflow:brainstorm:auto-parallel` 让多个不同角色的 AI 智能体（如系统架构师、产品经理、安全专家）同时对一个主题进行分析，并生成一份综合报告。

3.  **自定义智能体和命令**: 您可以修改 `.claude/agents/` 和 `.claude/commands/` 目录下的文件，来定制符合您团队特定需求的智能体行为和工作流。


希望本指南能帮助您顺利开启 CCW 之旅！

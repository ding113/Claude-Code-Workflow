# Command Flow Expression Standard

**用途**：规范命令文档中Task、SlashCommand、Skill和Bash调用的标准表达方式

**版本**：v2.1.0

---

## 核心原则

1. **统一格式** - 所有调用使用标准化格式
2. **清晰参数** - 必需参数明确标注，可选参数加方括号
3. **减少冗余** - 避免不必要的echo命令和管道操作
4. **工具优先** - 优先使用专用工具（Write/Read/Edit）而非Bash变通
5. **可读性** - 保持缩进和换行的一致性

---

## 1. Task调用标准（Agent启动）

### 标准格式

```javascript
Task(
  subagent_type="agent-type",
  description="Brief description",
  prompt=`
FULL TASK PROMPT HERE
  `
)
```

### 规范要求

- `subagent_type`: Agent类型（字符串）
- `description`: 简短描述（5-10词，动词开头）
- `prompt`: 完整任务提示（使用反引号包裹多行内容）
- 参数字段缩进2空格

### 正确示例

```javascript
// CLI执行agent
Task(
  subagent_type="cli-execution-agent",
  description="Analyze codebase patterns",
  prompt=`
PURPOSE: Identify code patterns for refactoring
TASK: Scan project files and extract common patterns
MODE: analysis
CONTEXT: @src/**/*
EXPECTED: Pattern list with usage examples
  `
)

// 代码开发agent
Task(
  subagent_type="code-developer",
  description="Implement authentication module",
  prompt=`
GOAL: Build JWT-based authentication
SCOPE: User login, token validation, session management
CONTEXT: @src/auth/**/* @CLAUDE.md
  `
)
```

---

## 2. SlashCommand调用标准

### 标准格式

```javascript
SlashCommand(command="/category:command-name [flags] arguments")
```

### 规范要求

单行调用 | 双引号包裹 | 完整路径`/category:command-name` | 参数顺序: 标志→参数值

### 正确示例

```javascript
// 无参数
SlashCommand(command="/workflow:status")

// 带标志和参数
SlashCommand(command="/workflow:session:start --auto \"task description\"")

// 变量替换
SlashCommand(command="/workflow:tools:context-gather --session [sessionId] \"description\"")

// 多个标志
SlashCommand(command="/workflow:plan --agent --cli-execute \"feature description\"")
```

---

## 3. Skill调用标准

### 标准格式

```javascript
Skill(command: "skill-name")
```

### 规范要求

单行调用 | 冒号语法`command:` | 双引号包裹skill-name

### 正确示例

```javascript
// 项目SKILL
Skill(command: "claude_dms3")

// 技术栈SKILL
Skill(command: "react-dev")

// 工作流SKILL
Skill(command: "workflow-progress")

// 变量替换
Skill(command: "${skill_name}")
```

---

## 4. Bash命令标准

### 核心原则：优先使用专用工具

**工具优先级**:
1. **Write工具** → 创建/覆盖文件内容
2. **Edit工具** → 修改现有文件内容
3. **Read工具** → 读取文件内容
4. **Bash命令** → 仅用于真正的系统操作（git, npm, test等）

### 标准格式

```javascript
bash(command args)
```

### 合理使用Bash的场景

```javascript
// ✅ Git操作
bash(git status --short)
bash(git commit -m "commit message")

// ✅ 包管理器和测试
bash(npm install)
bash(npm test)

// ✅ 文件系统查询和文本处理
bash(find .workflow -name "*.toon" -type f)
bash(rg "pattern" --type js --files-with-matches)
```

### 避免Bash的场景

```javascript
// ❌ 文件创建/写入 → 使用Write工具
bash(echo "content" > file.txt)  // 错误
Write({file_path: "file.txt", content: "content"})  // 正确

// ❌ 文件读取 → 使用Read工具
bash(cat file.txt)  // 错误
Read({file_path: "file.txt"})  // 正确

// ❌ 简单字符串处理 → 在代码中处理
bash(echo "text" | tr '[:upper:]' '[:lower:]')  // 错误
"text".toLowerCase()  // 正确
```

---

## 5. 组合调用模式（伪代码准则）

### 核心准则

直接写执行逻辑（无FUNCTION/END包裹）| 用`#`注释分段 | 变量赋值`variable = value` | 条件`IF/ELSE` | 循环`FOR` | 验证`VALIDATE` | 错误`ERROR + EXIT 1`

### 顺序调用（依赖关系）

```pseudo
# Phase 1-2: Session and Context
sessionId = SlashCommand(command="/workflow:session:start --auto \"description\"")
PARSE sessionId from output
VALIDATE: bash(test -d .workflow/{sessionId})

contextPath = SlashCommand(command="/workflow:tools:context-gather --session {sessionId} \"desc\"")
context_json = READ(contextPath)

# Phase 3-4: Conditional and Agent
IF context_json.conflict_risk IN ["medium", "high"]:
    SlashCommand(command="/workflow:tools:conflict-resolution --session {sessionId}")

Task(subagent_type="action-planning-agent", description="Generate tasks", prompt=`SESSION: {sessionId}`)

VALIDATE: bash(test -f .workflow/{sessionId}/IMPL_PLAN.md)
RETURN summary
```

### 并行调用（无依赖）

```pseudo
PARALLEL_START:
    check_git = bash(git status)
    check_count = bash(find .workflow -name "*.toon" | wc -l)
    check_skill = Skill(command: "project-name")
WAIT_ALL_COMPLETE
VALIDATE results
RETURN summary
```

### 条件分支调用

```pseudo
IF task_type CONTAINS "test": agent = "test-fix-agent"
ELSE IF task_type CONTAINS "implement": agent = "code-developer"
ELSE: agent = "universal-executor"

Skill(command: "project-name")
Task(subagent_type=agent, description="Execute task", prompt=build_prompt(task_type))
VALIDATE output
RETURN result
```

---

## 6. 变量和占位符规范

| 上下文 | 格式 | 示例 |
|--------|------|------|
| **Markdown说明** | `[variableName]` | `[sessionId]`, `[contextPath]` |
| **JavaScript代码** | `${variableName}` | `${sessionId}`, `${contextPath}` |
| **Bash命令** | `$variable` | `$session_id`, `$context_path` |

---

## 7. 快速检查清单

**Task**: subagent_type已指定 | description≤10词 | prompt用反引号 | 缩进2空格

**SlashCommand**: 完整路径 `/category:command` | 标志在前 | 变量用`[var]` | 双引号包裹

**Skill**: 冒号语法 `command:` | 双引号包裹 | 单行格式

**Bash**: 能用Write/Edit/Read工具吗？| 避免不必要echo | 真正的系统操作

---

## 8. 常见错误及修复

```javascript
// ❌ 错误1: Bash中不必要的echo
bash(echo 'status: active' > status.toon)
// ✅ 正确: 使用Write工具（TOON格式）
Write({file_path: "status.toon", content: 'status: active'})

// ❌ 错误2: Task单行格式
Task(subagent_type="agent", description="Do task", prompt=`...`)
// ✅ 正确: 多行格式
Task(subagent_type="agent", description="Do task", prompt=`...`)

// ❌ 错误3: Skill使用等号
Skill(command="skill-name")
// ✅ 正确: 使用冒号
Skill(command: "skill-name")
```


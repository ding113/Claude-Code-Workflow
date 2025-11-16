
# 🚀 Claude Code Workflow (CCW) - Getting Started Guide

Welcome to Claude Code Workflow (CCW) v5.0! This guide will help you get up and running in 5 minutes and experience AI-driven automated software development with our streamlined, dependency-free workflow system.

**Project Repository**: [ding113/Claude-Code-Workflow](https://github.com/ding113/Claude-Code-Workflow)

> **🎉 What's New in v5.0**: Less is more! We've removed external MCP dependencies and simplified workflows. CCW now uses standard tools (ripgrep/find) for better stability and performance. The brainstorming workflow focuses on role analysis for clearer planning.

---

## ⏱️ 5-Minute Quick Start

Let's build a "Hello World" web application from scratch with a simple example.

### Step 1: Install CCW

First, make sure you have installed CCW according to the [Installation Guide](INSTALL.md).

### Step 2: Create an Execution Plan (Automatically Starts a Session)

Now, tell CCW what you want to do. CCW will analyze your request and automatically generate a detailed, executable task plan.

```bash
/workflow:plan "Create a simple Express API that returns Hello World at the root path"
```

> **💡 Note**: `/workflow:plan` automatically creates and starts a workflow session. No need to manually run `/workflow:session:start`. The session will be auto-named based on your task description, e.g., `WFS-create-a-simple-express-api`.

This command kicks off a fully automated planning process, which includes:
1.  **Context Gathering**: Analyzing your project environment.
2.  **Agent Analysis**: AI agents think about the best implementation path.
3.  **Task Generation**: Creating specific task files in TOON format (e.g., `.toon` files).

### Step 3: Execute the Plan

Once the plan is created, you can command the AI agents to start working.

```bash
/workflow:execute
```

You will see CCW's agents (like `@code-developer`) begin to execute tasks one by one. It will automatically create files, write code, and install dependencies.

### Step 4: Check the Status

Want to know the progress? You can check the status of the current workflow at any time.

```bash
/workflow:status
```

This will show the completion status of tasks, the currently executing task, and the next steps.

---

## 🧠 Core Concepts Explained

Understanding these concepts will help you use CCW more effectively:

-   **Workflow Session**
    > Like an independent sandbox or project space, used to isolate the context, files, and history of different tasks. All related files are stored in the `.workflow/WFS-<session-name>/` directory.

-   **Task**
    > An atomic unit of work, such as "create API route" or "write test case." Each task is stored in TOON format (e.g., `.toon`) to capture the goal, context, and execution steps in a compact, human-friendly layout.

    TOON task example:
    ```toon
    id: IMPL-001
    title: Create Hello World endpoint
    agent: @code-developer
    priority: medium
    status: pending
    steps[3]{name,status}:
      Analyze project context,pending
      Implement GET / handler,pending
      Add request tests,pending
    ```

-   **Agent**
    > An AI assistant specialized in a specific domain. For example:
    > -   `@code-developer`: Responsible for writing and implementing code.
    > -   `@test-fix-agent`: Responsible for running tests and automatically fixing failures.
    > -   `@ui-design-agent`: Responsible for UI design and prototype creation.
    > -   `@cli-execution-agent`: Responsible for autonomous CLI task handling (v4.5.0+).

-   **Workflow**
    > A series of predefined, collaborative commands used to orchestrate different agents and tools to achieve a complex development goal (e.g., `plan`, `execute`, `test-gen`).

---

## 🛠️ Common Scenarios

### Scenario 1: Quick Feature Development

For simple, well-defined features, use the direct "plan → execute" pattern:

```bash
# Create plan (auto-creates session)
/workflow:plan "Implement JWT-based user login and registration"

# Execute
/workflow:execute
```

> **💡 Note**: `/workflow:plan` automatically creates a session. You can also manually start a session first with `/workflow:session:start "Feature Name"`.

### Scenario 2: UI Design Exploration

For UI-focused projects, start with design exploration before implementation: **ui-design → update → plan → execute**

```bash
# Step 1: Generate UI design variations (auto-creates session)
/workflow:ui-design:explore-auto --prompt "A modern, clean admin dashboard login page"

# Step 2: Review designs in compare.html, then sync design system to brainstorming artifacts
/workflow:ui-design:design-sync --session <session-id> --selected-prototypes "login-v1,login-v2"

# Step 3: Generate implementation plan with design references
/workflow:plan

# Step 4: Execute the implementation
/workflow:execute
```

> **💡 Tip**: The `update` command integrates selected design prototypes into brainstorming artifacts, ensuring implementation follows the approved designs.

### Scenario 3: Complex Feature with Multi-Agent Brainstorming

For complex features requiring thorough analysis, use the complete workflow: **brainstorm → plan → execute**

```bash
# Step 1: Multi-agent brainstorming (auto-creates session)
/workflow:brainstorm:auto-parallel "Design a real-time collaborative document editing system with conflict resolution"

# Optional: Specify number of expert roles (default: 3, max: 9)
/workflow:brainstorm:auto-parallel "Build scalable microservices platform" --count 5

# Step 2: Generate implementation plan from brainstorming results
/workflow:plan

# Step 3: Execute the plan
/workflow:execute
```

**Brainstorming Benefits**:
- **Auto role selection**: Analyzes your topic and selects 3-9 relevant expert roles (system-architect, ui-designer, product-manager, etc.)
- **Parallel execution**: Multiple AI agents analyze simultaneously from different perspectives
- **Comprehensive specification**: Generates integrated requirements and design document

**When to Use Brainstorming**:
- Complex features requiring multiple perspectives
- Architectural decisions with significant impact
- When you need thorough requirements before implementation

### Scenario 4: Quality Assurance - Action Plan Verification

After planning, validate your implementation plan for consistency and completeness:

```bash
# After /workflow:plan completes, verify task quality
/workflow:action-plan-verify

# The command will:
# 1. Check requirements coverage (all requirements have tasks)
# 2. Validate task dependencies (no circular or broken dependencies)
# 3. Ensure synthesis alignment (tasks match architectural decisions)
# 4. Assess task specification quality
# 5. Generate detailed verification report with remediation todos
```

**The verification report includes**:
- Requirements coverage analysis
- Dependency graph validation
- Synthesis alignment checks
- Task specification quality assessment
- Prioritized remediation recommendations

**When to Use**:
- After `/workflow:plan` generates IMPL_PLAN.md and task files
- Before starting `/workflow:execute`
- When working on complex projects with many dependencies
- When you want to ensure high-quality task specifications

**Benefits**:
- Catches planning errors before execution
- Ensures complete requirements coverage
- Validates architectural consistency
- Identifies resource conflicts and skill gaps
- Provides actionable remediation plan with TodoWrite integration

### Scenario 6: Bug Fixing

Quick bug analysis and fix workflow:

```bash
# Analyze the bug
/cli:mode:bug-index "Incorrect success message with wrong password"

# Claude will analyze and then directly implement the fix based on the analysis
```

---

## 🔧 Workflow-Free Usage: Standalone Tools

Beyond the full workflow mode, CCW provides standalone CLI tools and commands suitable for quick analysis, ad-hoc queries, and routine maintenance tasks.

### Direct CLI Tool Invocation

CCW supports direct invocation of external AI tools (Gemini, Codex) through a unified CLI interface without creating workflow sessions.

#### Code Analysis

Quickly analyze project code structure and architectural patterns:

```bash
# Code analysis with Gemini
/cli:analyze --tool gemini "Analyze authentication module architecture"

# Code quality analysis with Qwen
/cli:analyze --tool gemini "Review database model design for best practices"
```

#### Interactive Chat

Direct interactive dialogue with AI tools:

```bash
# Chat with Gemini
/cli:chat --tool gemini "Explain React Hook use cases"

# Discuss implementation with Codex
/cli:chat --tool codex "How to optimize this query performance"
```

#### Specialized Analysis Modes

Use specific analysis modes for in-depth exploration:

```bash
# Architecture planning mode
/cli:mode:plan --tool gemini "Design a scalable microservices architecture"

# Deep code analysis
/cli:mode:code-analysis --tool gemini "Analyze utility functions in src/utils/"

# Bug analysis mode
/cli:mode:bug-index --tool gemini "Analyze potential causes of memory leak"
```

### Semantic Tool Invocation

Users can tell Claude to use specific tools through natural language, and Claude will understand the intent and automatically execute the appropriate commands.

#### Semantic Invocation Examples

Describe needs directly in conversation using natural language:

**Example 1: Code Analysis**
```
User: "Use gemini to analyze the modular architecture of this project"
→ Claude will automatically execute gemini-wrapper for analysis
```

**Example 2: Document Generation**
```
User: "Use gemini to generate API documentation with all endpoint descriptions"
→ Claude will understand the need and automatically invoke gemini's write mode
```

**Example 3: Code Implementation**
```
User: "Use codex to implement user login functionality"
→ Claude will invoke the codex tool for autonomous development
```

#### Advantages of Semantic Invocation

- **Natural Interaction**: No need to memorize complex command syntax
- **Intelligent Understanding**: Claude selects appropriate tools and parameters based on context
- **Automatic Optimization**: Claude automatically adds necessary context and configuration

### Memory Management: CLAUDE.md Updates

CCW uses a hierarchical CLAUDE.md documentation system to maintain project context. Regular updates to these documents are critical for ensuring high-quality AI outputs.

#### Full Project Index Rebuild

Suitable for large-scale refactoring, architectural changes, or first-time CCW usage:

```bash
# Rebuild entire project documentation index
/memory:update-full

# Use specific tool for indexing
/memory:update-full --tool gemini   # Comprehensive analysis (recommended)
/memory:update-full --tool gemini     # Architecture focus
/memory:update-full --tool codex    # Implementation details
```

**When to Execute**:
- During project initialization
- After major architectural changes
- Weekly routine maintenance
- When AI output drift is detected

#### Quick Context Loading for Specific Tasks

When you need immediate, task-specific context without updating documentation:

```bash
# Load context for a specific task into memory
/memory:load "在当前前端基础上开发用户认证功能"

# Use alternative CLI tool for analysis
/memory:load --tool gemini "重构支付模块API"
```

**How It Works**:
- Delegates to an AI agent for autonomous project analysis
- Discovers relevant files and extracts task-specific keywords
- Uses CLI tools (Gemini) for deep analysis to save tokens
- Returns a structured "Core Content Pack" loaded into memory
- Provides context for subsequent agent operations

**When to Use**:
- Before starting a new feature or task
- When you need quick context without full documentation rebuild
- For task-specific architectural or pattern discovery
- As preparation for agent-based development workflows

#### Incremental Related Module Updates

Suitable for daily development, updating only modules affected by changes:

```bash
# Update recently modified related documentation
/memory:update-related

# Specify tool for update
/memory:update-related --tool gemini
```

**When to Execute**:
- After feature development completion
- After module refactoring
- After API interface updates
- After data model modifications

#### Memory Quality Impact

| Update Frequency | Result |
|-----------------|--------|
| ❌ Never update | Outdated API references, incorrect architectural assumptions, low-quality output |
| ⚠️ Occasional updates | Partial context accuracy, potential inconsistencies |
| ✅ Timely updates | High-quality output, precise context, correct pattern references |

### CLI Tool Initialization

When using external CLI tools for the first time, initialization commands provide quick configuration:

```bash
# Auto-configure all tools
/cli:cli-init

# Configure specific tools only
/cli:cli-init --tool gemini
/cli:cli-init --tool qwen
```

This command will:
- Analyze project structure
- Generate tool configuration files
- Set up `.geminiignore` / `.qwenignore`
- Create context file references

---

## Advanced Usage: Agent Skills

Agent Skills are modular, reusable capabilities that extend the AI's functionality. They are stored in the `.claude/skills/` directory and are invoked through specific trigger mechanisms.

### How Skills Work

-   **Model-Invoked**: Unlike slash commands, you don't call Skills directly. The AI decides when to use a Skill based on its understanding of your goal.
-   **Contextual**: Skills provide specific instructions, scripts, and templates to the AI for specialized tasks.
-   **Trigger Mechanisms**:
    -   **Conversational Trigger**: Use `-e` or `--enhance` flag in **natural conversation** to trigger the `prompt-enhancer` skill
    -   **CLI Command Enhancement**: Use `--enhance` flag in **CLI commands** for prompt refinement (this is a CLI feature, not a skill trigger)

### Examples

**Conversational Trigger** (activates prompt-enhancer skill):
```
User: "Analyze authentication module -e"
→ AI uses prompt-enhancer skill to expand the request
```

**CLI Command Enhancement** (built-in CLI feature):
```bash
# The --enhance flag here is a CLI parameter, not a skill trigger
/cli:analyze --enhance "check for security issues"
```

**Important Note**: The `-e` flag works in natural conversation, but `--enhance` in CLI commands is a separate enhancement mechanism, not the skill system.

---

## Advanced Usage: UI Design Workflow

CCW includes a powerful, multi-phase workflow for UI design and prototyping, capable of generating complete design systems and interactive prototypes from simple descriptions or reference images.

### Key Commands

-   `/workflow:ui-design:explore-auto`: An exploratory workflow that generates multiple, distinct design variations based on a prompt.
-   `/workflow:ui-design:imitate-auto`: A replication workflow that creates high-fidelity prototypes from reference URLs.

### Example: Generating a UI from a Prompt

You can generate multiple design options for a web page with a single command:

```bash
# This command will generate 3 different style and layout variations for a login page.
/workflow:ui-design:explore-auto --prompt "A modern, clean login page for a SaaS application" --targets "login" --style-variants 3 --layout-variants 3
```

After the workflow completes, it provides a `compare.html` file, allowing you to visually review and select the best design combination.

---

## ❓ Troubleshooting

-   **Problem: Prompt shows "No active session found"**
    > **Reason**: You haven't started a workflow session, or the current session is complete.
    > **Solution**: Use `/workflow:session:start "Your task description"` to start a new session.

-   **Problem: Command execution fails or gets stuck**
    > **Reason**: It could be a network issue, AI model limitation, or the task is too complex.
    > **Solution**:
    > 1.  First, try using `/workflow:status` to check the current state.
    > 2.  Check the log files in the `.workflow/WFS-<session-name>/.chat/` directory for detailed error messages.
    > 3.  If the task is too complex, try breaking it down into smaller tasks and then use `/workflow:plan` to create a new plan.

---

## 📚 Next Steps for Advanced Learning

Once you've mastered the basics, you can explore CCW's more powerful features:

1.  **Test-Driven Development (TDD)**: Use `/workflow:tdd-plan` to create a complete TDD workflow. The AI will first write failing tests, then write code to make them pass, and finally refactor.

2.  **Multi-Agent Brainstorming**: Use `/workflow:brainstorm:auto-parallel` to have multiple AI agents with different roles (like System Architect, Product Manager, Security Expert) analyze a topic simultaneously and generate a comprehensive report.

3.  **Custom Agents and Commands**: You can modify the files in the `.claude/agents/` and `.claude/commands/` directories to customize agent behavior and workflows to fit your team's specific needs.


Hope this guide helps you get started smoothly with CCW!

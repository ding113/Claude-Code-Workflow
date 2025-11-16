# Command Reference

This document provides a comprehensive reference for all commands available in the Claude Code Workflow (CCW) system.

> **Version 5.0 Update**: Streamlined command structure focusing on essential tools. Removed MCP code-index dependency for better stability and performance.

## Unified CLI Commands (`/cli:*`)

These commands provide direct access to AI tools for quick analysis and interaction without initiating a full workflow.

| Command | Description |
|---|---|
| `/cli:analyze` | Quick codebase analysis using CLI tools (codex/gemini/qwen). |
| `/cli:chat` | Simple CLI interaction command for direct codebase analysis. |
| `/cli:cli-init`| Initialize CLI tool configurations (Gemini and Qwen) based on workspace analysis. |
| `/cli:codex-execute` | Automated task decomposition and execution with Codex using resume mechanism. |
| `/cli:discuss-plan` | Orchestrates an iterative, multi-model discussion for planning and analysis without implementation. |
| `/cli:execute` | Auto-execution of implementation tasks with YOLO permissions and intelligent context inference. |
| `/cli:mode:bug-index` | Bug analysis and fix suggestions using CLI tools. |
| `/cli:mode:code-analysis` | Deep code analysis and debugging using CLI tools with specialized template. |
| `/cli:mode:plan` | Project planning and architecture analysis using CLI tools. |

## Workflow Commands (`/workflow:*`)

These commands orchestrate complex, multi-phase development processes, from planning to execution.

### Session Management

| Command | Description |
|---|---|
| `/workflow:session:start` | Discover existing sessions or start a new workflow session with intelligent session management. |
| `/workflow:session:list` | List all workflow sessions with status. |
| `/workflow:session:resume` | Resume the most recently paused workflow session. |
| `/workflow:session:complete` | Mark the active workflow session as complete and remove active flag. |

### Core Workflow

| Command | Description |
|---|---|
| `/workflow:plan` | Orchestrate 5-phase planning workflow with quality gate, executing commands and passing context between phases. |
| `/workflow:execute` | Coordinate agents for existing workflow tasks with automatic discovery. |
| `/workflow:resume` | Intelligent workflow session resumption with automatic progress analysis. |
| `/workflow:review` | Optional specialized review (security, architecture, docs) for completed implementation. |
| `/workflow:status` | Generate on-demand views from TOON task data. |

### Brainstorming

| Command | Description |
|---|---|
| `/workflow:brainstorm:artifacts` | Generate role-specific guidance-specification.md dynamically based on selected roles. |
| `/workflow:brainstorm:auto-parallel` | Parallel brainstorming automation with dynamic role selection and concurrent execution. |
| `/workflow:brainstorm:synthesis` | Clarify and refine role analyses through intelligent Q&A and targeted updates. |
| `/workflow:brainstorm:api-designer` | Generate or update api-designer/analysis.md addressing guidance-specification discussion points. |
| `/workflow:brainstorm:data-architect` | Generate or update data-architect/analysis.md addressing guidance-specification discussion points. |
| `/workflow:brainstorm:product-manager` | Generate or update product-manager/analysis.md addressing guidance-specification discussion points. |
| `/workflow:brainstorm:product-owner` | Generate or update product-owner/analysis.md addressing guidance-specification discussion points. |
| `/workflow:brainstorm:scrum-master` | Generate or update scrum-master/analysis.md addressing guidance-specification discussion points. |
| `/workflow:brainstorm:subject-matter-expert` | Generate or update subject-matter-expert/analysis.md addressing guidance-specification discussion points. |
| `/workflow:brainstorm:system-architect` | Generate or update system-architect/analysis.md addressing guidance-specification discussion points. |
| `/workflow:brainstorm:ui-designer` | Generate or update ui-designer/analysis.md addressing guidance-specification discussion points. |
| `/workflow:brainstorm:ux-expert` | Generate or update ux-expert/analysis.md addressing guidance-specification discussion points. |

### Quality & Verification

| Command | Description |
|---|---|
| `/workflow:action-plan-verify`| Perform non-destructive cross-artifact consistency and quality analysis of IMPL_PLAN.md and TOON task files before execution. |

### Test-Driven Development (TDD)

| Command | Description |
|---|---|
| `/workflow:tdd-plan` | Orchestrate TDD workflow planning with Red-Green-Refactor task chains. |
| `/workflow:tdd-verify` | Verify TDD workflow compliance and generate quality report. |

### Test Generation & Execution

| Command | Description |
|---|---|
| `/workflow:test-gen` | Generate test plan and tasks by analyzing completed implementation. Use `/workflow:execute` to run generated tasks. |
| `/workflow:test-fix-gen` | Generate test-fix plan and tasks from existing implementation or prompt. Use `/workflow:execute` to run generated tasks. |
| `/workflow:test-cycle-execute` | Execute test-fix workflow with dynamic task generation and iterative fix cycles. Tasks are executed by `/workflow:execute`. |

### UI Design Workflow

| Command | Description |
|---|---|
| `/workflow:ui-design:explore-auto` | Exploratory UI design workflow with style-centric batch generation. |
| `/workflow:ui-design:imitate-auto` | High-speed multi-page UI replication with batch screenshot capture. |
| `/workflow:ui-design:capture` | Batch screenshot capture for UI design workflows using MCP or local fallback. |
| `/workflow:ui-design:explore-layers` | Interactive deep UI capture with depth-controlled layer exploration. |
| `/workflow:ui-design:style-extract` | Extract design style from reference images or text prompts using Claude's analysis. |
| `/workflow:ui-design:layout-extract` | Extract structural layout information from reference images, URLs, or text prompts. |
| `/workflow:ui-design:generate` | Assemble UI prototypes by combining layout templates with design tokens (pure assembler). |
| `/workflow:ui-design:design-sync` | Synchronize finalized design system references to brainstorming artifacts. |
| `/workflow:ui-design:animation-extract` | Extract animation and transition patterns from URLs, CSS, or interactive questioning. |

### Internal Tools

These commands are primarily used internally by other workflow commands but can be used manually.

| Command | Description |
|---|---|
| `/workflow:tools:concept-enhanced` | Enhanced intelligent analysis with parallel CLI execution and design blueprint generation. |
| `/workflow:tools:conflict-resolution` | Detect and resolve conflicts between plan and existing codebase using CLI-powered analysis. |
| `/workflow:tools:context-gather` | Intelligently collect project context using universal-executor agent based on task description and package into standardized TOON bundles. |
| `/workflow:tools:task-generate` | Generate TOON task files and IMPL_PLAN.md from analysis results with artifacts integration. |
| `/workflow:tools:task-generate-agent` | Autonomous task generation using action-planning-agent with discovery and output phases. |
| `/workflow:tools:task-generate-tdd` | Generate TDD task chains with Red-Green-Refactor dependencies. |
| `/workflow:tools:tdd-coverage-analysis` | Analyze test coverage and TDD cycle execution. |
| `/workflow:tools:test-concept-enhanced` | Analyze test requirements and generate test generation strategy using Gemini. |
| `/workflow:tools:test-context-gather` | Collect test coverage context and identify files requiring test generation. |
| `/workflow:tools:test-task-generate` | Generate test-fix TOON task files with iterative test-fix-retest cycle specification. |

## Task Commands (`/task:*`)

Commands for managing individual tasks within a workflow session.

| Command | Description |
|---|---|
| `/task:create` | Create implementation tasks with automatic context awareness. |
| `/task:breakdown` | Intelligent task decomposition with context-aware subtask generation. |
| `/task:execute` | Execute tasks with appropriate agents and context-aware orchestration. |
| `/task:replan` | Replan individual tasks with detailed user input and change tracking. |

## Memory and Versioning Commands

| Command | Description |
|---|---|
| `/memory:update-full` | Complete project-wide CLAUDE.md documentation update. |
| `/memory:load` | Quickly load key project context into memory based on a task description. |
| `/memory:update-related` | Context-aware CLAUDE.md documentation updates based on recent changes. |
| `/version` | Display version information and check for updates. |
| `/enhance-prompt` | Context-aware prompt enhancement using session memory and codebase analysis. |

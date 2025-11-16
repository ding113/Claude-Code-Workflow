---
name: execute
description: Autonomous code implementation with YOLO auto-approval using Gemini/Codex, supports task ID or description input with automatic file pattern detection
argument-hint: "[--tool codex|gemini] [--enhance] description or task-id"
allowed-tools: SlashCommand(*), Bash(*), Task(*)
---

# CLI Execute Command (/cli:execute)

## Purpose

Execute implementation tasks with **YOLO permissions** (auto-approves all confirmations). **MODIFIES CODE**.

**Intent**: Autonomous code implementation, modification, and generation
**Supported Tools**: codex, gemini (default)
**Key Feature**: Automatic context inference and file pattern detection

## Core Behavior

1. **Code Modification**: This command MODIFIES, CREATES, and DELETES code files
2. **Auto-Approval**: YOLO mode bypasses confirmation prompts for all operations
3. **Implementation Focus**: Executes actual code changes, not just recommendations
4. **Requires Explicit Intent**: Use only when implementation is intended

## Core Concepts

### YOLO Permissions
Auto-approves: file pattern inference, execution, **file modifications**, summary generation

**WARNING**: This command will make actual code changes without manual confirmation

### Execution Modes

**1. Description Mode** (supports `--enhance`):
- Input: Natural language description
- Process: [Optional: Enhance] → Keyword analysis → Pattern inference → Execute

**2. Task ID Mode** (no `--enhance`):
- Input: Workflow task identifier (e.g., `IMPL-001`)
- Process: Task JSON parsing → Scope analysis → Execute

**3. Agent Mode** (default):
- Input: Description or task-id
- Process: 5-Phase Workflow → Context Discovery → Optimal Tool Selection → Execute

### Context Inference

Auto-selects files based on keywords and technology (each @ references one pattern):
- "auth" → `@**/*auth* @**/*user*`
- "React" → `@src/**/*.jsx @src/**/*.tsx`
- "api" → `@**/api/**/* @**/routes/**/*`
- Always includes: `@CLAUDE.md @**/*CLAUDE.md`

For precise file targeting, use `rg` or MCP tools to discover files first.

### Codex Session Continuity

**Resume Pattern** for related tasks:
```bash
# First task - establish session
codex -C [dir] --full-auto exec "[task]" --skip-git-repo-check -s danger-full-access

# Related task - continue session
codex --full-auto exec "[related-task]" resume --last --skip-git-repo-check -s danger-full-access
```

Use `resume --last` when current task extends/relates to previous execution. See intelligent-tools-strategy.md for auto-resume rules.

## Parameters

- `--tool <codex|gemini>` - Select CLI tool (default: auto-select by agent based on complexity)
- `--enhance` - Enhance input with `/enhance-prompt` first (Description Mode only)
- `<description|task-id>` - Natural language description or task identifier
- `--debug` - Verbose logging
- `--save-session` - Save execution to workflow session

## Workflow Integration

**Session Management**: Auto-detects `.workflow/.active-*` marker
- Active session: Save to `.workflow/WFS-[id]/.chat/execute-[timestamp].md`
- No session: Create new session or save to scratchpad

**Task Integration**: Load from `.task/[TASK-ID].json`, update status, generate summary

## Execution Flow

Uses **cli-execution-agent** (default) for automated implementation:

```javascript
Task(
  subagent_type="cli-execution-agent",
  description="Autonomous code implementation with YOLO auto-approval",
  prompt=`
    Task: ${description_or_task_id}
    Mode: execute
    Tool: ${tool_flag || 'auto-select'}
    Enhance: ${enhance_flag}
    Task-ID: ${task_id}

    Execute autonomous code implementation with full modification permissions:

    1. Task Analysis:
       ${task_id ? '- Load task spec from .task/' + task_id + '.json' : ''}
       - Parse requirements and implementation scope
       - Classify complexity (simple/medium/complex)
       - Extract keywords for context discovery

    2. Context Discovery:
       - Discover implementation files using MCP/ripgrep
       - Identify existing patterns and conventions (CLAUDE.md)
       - Map dependencies and integration points
       - Gather related tests and documentation
       - Auto-detect file patterns from keywords

    3. Tool Selection & Execution:
       - Complexity assessment:
         * Simple/Medium → Gemini (MODE=write, --approval-mode yolo)
         * Complex → Codex (MODE=auto, --skip-git-repo-check -s danger-full-access)
       - Tool preference: ${tool_flag || 'auto-select based on complexity'}
       - Apply appropriate implementation template
       - Execute with YOLO auto-approval (bypasses all confirmations)

    4. Implementation:
       - Modify/create/delete code files per requirements
       - Follow existing code patterns and conventions
       - Include comprehensive context in CLI command
       - Ensure working implementation with proper error handling

    5. Output & Documentation:
       - Save execution log: .workflow/WFS-[id]/.chat/execute-[timestamp].md
       ${task_id ? '- Generate task summary: .workflow/WFS-[id]/.summaries/' + task_id + '-summary.md' : ''}
       ${task_id ? '- Update task status in .task/' + task_id + '.json' : ''}
       - Document all code changes made

    ⚠️ YOLO Mode: All file operations auto-approved without confirmation
  `
)
```

**Output**: `.workflow/WFS-[id]/.chat/execute-[timestamp].md` + `.summaries/[TASK-ID]-summary.md` (or `.scratchpad/` if no session)

## Examples

**Basic Implementation** (modifies code):
```bash
/cli:execute "implement JWT authentication with middleware"
# Agent Phase 1: Classifies intent=execute, complexity=medium, keywords=['jwt', 'auth', 'middleware']
# Agent Phase 2: Discovers auth patterns, existing middleware structure
# Agent Phase 3: Selects Gemini (medium complexity)
# Agent Phase 4: Executes with auto-approval
# Result: NEW/MODIFIED code files with JWT implementation
```

**Complex Implementation** (modifies code):
```bash
/cli:execute "implement OAuth2 authentication with token refresh"
# Agent Phase 1: Classifies intent=execute, complexity=complex, keywords=['oauth2', 'auth', 'token', 'refresh']
# Agent Phase 2: MCP discovers auth patterns, existing middleware, JWT dependencies
# Agent Phase 3: Enhances prompt with discovered patterns and best practices
# Agent Phase 4: Selects Codex (complex task), executes with comprehensive context
# Agent Phase 5: Saves execution log + generates implementation summary
# Result: Complete OAuth2 implementation + detailed execution log
```

**Enhanced Implementation** (modifies code):
```bash
/cli:execute --enhance "implement JWT authentication"
# Step 1: Enhance to expand requirements
# Step 2: Execute implementation with auto-approval
# Result: Complete auth system with MODIFIED code files
```

**Task Execution** (modifies code):
```bash
/cli:execute IMPL-001
# Reads: .task/IMPL-001.json for requirements
# Executes: Implementation based on task spec
# Result: Code changes per task definition
```

**Codex Implementation** (modifies code):
```bash
/cli:execute --tool codex "optimize database queries"
# Executes: Codex with full file access
# Result: MODIFIED query code, new indexes, updated tests
```

**Gemini Code Generation** (modifies code):
```bash
/cli:execute --tool gemini --enhance "refactor auth module"
# Step 1: Enhanced refactoring plan
# Step 2: Execute with MODE=write
# Result: REFACTORED auth code with structural changes
```

## Comparison with Analysis Commands

| Command | Intent | Code Changes | Auto-Approve |
|---------|--------|--------------|--------------|
| `/cli:analyze` | Understand code | NO | N/A |
| `/cli:chat` | Ask questions | NO | N/A |
| `/cli:execute` | **Implement** | **YES** | **YES** |

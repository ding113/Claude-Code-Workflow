---
name: bug-diagnosis
description: Read-only bug root cause analysis using Gemini/Codex with systematic diagnosis template for fix suggestions
argument-hint: "[--tool codex|gemini] [--enhance] [--cd path] bug description"
allowed-tools: SlashCommand(*), Bash(*), Task(*)
---

# CLI Mode: Bug Diagnosis (/cli:mode:bug-diagnosis)

## Purpose

Systematic bug diagnosis with root cause analysis template (`~/.claude/workflows/cli-templates/prompts/analysis/01-diagnose-bug-root-cause.txt`).

**Tool Selection**:
- **gemini** (default) - Best for bug diagnosis
- **qwen** - Fallback when Gemini unavailable
- **codex** - Alternative for complex bug analysis

## Parameters

- `--tool <gemini|codex>` - Tool selection (default: gemini)
- `--enhance` - Enhance bug description with `/enhance-prompt`
- `--cd "path"` - Target directory for focused diagnosis
- `<bug-description>` (Required) - Bug description or error details

## Tool Usage

**Gemini** (Primary):
```bash
# Uses gemini by default, or specify explicitly
--tool gemini
```

**Qwen** (Fallback):
```bash
--tool qwen
```

**Codex** (Alternative):
```bash
--tool codex
```

## Execution Flow

Uses **cli-execution-agent** (default) for automated bug diagnosis:

```javascript
Task(
  subagent_type="cli-execution-agent",
  description="Bug root cause diagnosis with fix suggestions",
  prompt=`
    Task: ${bug_description}
    Mode: bug-diagnosis
    Tool: ${tool_flag || 'gemini'}
    Directory: ${cd_path || '.'}
    Enhance: ${enhance_flag}
    Template: ~/.claude/workflows/cli-templates/prompts/analysis/01-diagnose-bug-root-cause.txt

    Execute systematic bug diagnosis and root cause analysis:

    1. Context Discovery:
       - Locate error traces, stack traces, and log messages
       - Find related code sections and affected modules
       - Identify data flow paths leading to the bug
       - Discover test cases related to bug area
       - Use MCP/ripgrep for comprehensive context gathering

    2. Root Cause Analysis:
       - Apply diagnostic template methodology
       - Trace execution to identify failure point
       - Analyze state, data, and logic causing issue
       - Document potential root causes with evidence
       - Assess bug severity and impact scope

    3. CLI Command Construction:
       - Tool: ${tool_flag || 'gemini'} (qwen fallback, codex for complex bugs)
       - Directory: cd ${cd_path || '.'} &&
       - Context: @**/* + error traces + affected code
       - Mode: analysis (read-only)
       - Template: analysis/01-diagnose-bug-root-cause.txt

    4. Output Generation:
       - Root cause diagnosis with evidence
       - Fix suggestions and recommendations
       - Prevention strategies
       - Save to .workflow/WFS-[id]/.chat/bug-diagnosis-[timestamp].md (or .scratchpad/)
  `
)
```

## Core Rules

- **Read-only**: Diagnoses bugs, does NOT modify code
- **Template**: `~/.claude/workflows/cli-templates/prompts/analysis/01-diagnose-bug-root-cause.txt`
- **Output**: `.workflow/WFS-[id]/.chat/bug-diagnosis-[timestamp].md` (or `.scratchpad/` if no session)

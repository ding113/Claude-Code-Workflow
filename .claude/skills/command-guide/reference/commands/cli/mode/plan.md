---
name: plan
description: Read-only architecture planning using Gemini/Codex with strategic planning template for modification plans and impact analysis
argument-hint: "[--tool codex|gemini] [--enhance] [--cd path] topic"
allowed-tools: SlashCommand(*), Bash(*), Task(*)
---

# CLI Mode: Plan (/cli:mode:plan)

## Purpose

Strategic software architecture planning template (`~/.claude/workflows/cli-templates/prompts/planning/01-plan-architecture-design.txt`).

**Tool Selection**:
- **gemini** (default) - Best for architecture planning

- **codex** - Alternative for implementation planning

## Parameters

- `--tool <gemini|codex>` - Tool selection (default: gemini)
- `--enhance` - Enhance task with `/enhance-prompt`
- `--cd "path"` - Target directory for focused planning
- `<planning-task>` (Required) - Architecture planning task or modification requirements

## Tool Usage

**Gemini** (Primary):
```bash
--tool gemini  # or omit (default)
```


```bash
--tool gemini
```

**Codex** (Alternative):
```bash
--tool codex
```

## Execution Flow

Uses **cli-execution-agent** (default) for automated planning:

```javascript
Task(
  subagent_type="cli-execution-agent",
  description="Architecture planning with impact analysis",
  prompt=`
    Task: ${planning_task}
    Mode: plan
    Tool: ${tool_flag || 'gemini'}
    Directory: ${cd_path || '.'}
    Enhance: ${enhance_flag}
    Template: ~/.claude/workflows/cli-templates/prompts/planning/01-plan-architecture-design.txt

    Execute strategic architecture planning:

    1. Context Discovery:
       - Analyze current architecture structure
       - Identify affected components and modules
       - Map dependencies and integration points
       - Assess modification impacts (scope, complexity, risks)

    2. Planning Analysis:
       - Apply strategic planning template
       - Generate modification plan with phases
       - Document architectural decisions and rationale
       - Identify potential conflicts and mitigation strategies

    3. CLI Command Construction:
       - Directory: cd ${cd_path || '.'} &&
       - Context: @**/* (full architecture context)
       - Mode: analysis (read-only, no code generation)
       - Template: planning/01-plan-architecture-design.txt

    4. Output Generation:
       - Strategic modification plan
       - Impact analysis and risk assessment
       - Implementation roadmap
       - Save to .workflow/WFS-[id]/.chat/plan-[timestamp].md (or .scratchpad/)
  `
)
```

## Core Rules

- **Read-only**: Creates modification plans, does NOT generate code
- **Template**: `~/.claude/workflows/cli-templates/prompts/planning/01-plan-architecture-design.txt`
- **Output**: `.workflow/WFS-[id]/.chat/plan-[timestamp].md` (or `.scratchpad/` if no session)

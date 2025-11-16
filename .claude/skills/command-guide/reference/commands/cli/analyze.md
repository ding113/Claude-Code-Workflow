---
name: analyze
description: Read-only codebase analysis using Gemini (default) or Codex with auto-pattern detection and template selection
argument-hint: "[--tool codex|gemini] [--enhance] analysis target"
allowed-tools: SlashCommand(*), Bash(*), TodoWrite(*), Read(*), Glob(*), Task(*)
---

# CLI Analyze Command (/cli:analyze)

## Purpose

Quick codebase analysis using CLI tools. **Read-only - does NOT modify code**.

**Tool Selection**:
- **gemini** (default) - Best for code analysis

- **codex** - Alternative for deep analysis

## Parameters

- `--tool <gemini|codex>` - Tool selection (default: gemini)
- `--enhance` - Use `/enhance-prompt` for context-aware enhancement
- `<analysis-target>` - Description of what to analyze

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

Uses **cli-execution-agent** (default) for automated analysis:

```javascript
Task(
  subagent_type="cli-execution-agent",
  description="Codebase analysis with pattern detection",
  prompt=`
    Task: ${analysis_target}
    Mode: analyze
    Tool: ${tool_flag || 'gemini'}
    Enhance: ${enhance_flag}

    Execute codebase analysis with auto-pattern detection:

    1. Context Discovery:
       - Extract keywords from analysis target
       - Auto-detect file patterns (auth→auth files, component→components, etc.)
       - Discover additional relevant files using MCP
       - Build comprehensive file context

    2. Template Selection:
       - Auto-select analysis template based on keywords
       - Apply appropriate analysis methodology
       - Include @CLAUDE.md for project context

    3. CLI Command Construction:
       - Context: @CLAUDE.md + auto-detected patterns + discovered files
       - Mode: analysis (read-only)
       - Expected: Insights, recommendations, pattern analysis

    4. Execution & Output:
       - Execute CLI tool with assembled context
       - Generate comprehensive analysis report
       - Save to .workflow/WFS-[id]/.chat/analyze-[timestamp].md (or .scratchpad/)
  `
)
```

## Core Rules

- **Read-only**: Analyzes code, does NOT modify files
- **Auto-pattern**: Detects file patterns from keywords (auth→auth files, component→components, API→api/routes, test→test files)
- **Output**: `.workflow/WFS-[id]/.chat/analyze-[timestamp].md` (or `.scratchpad/` if no session)

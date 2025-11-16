---
name: code-analysis
description: Read-only execution path tracing using Gemini/Codex with specialized analysis template for call flow and optimization
argument-hint: "[--tool codex|gemini] [--enhance] [--cd path] analysis target"
allowed-tools: SlashCommand(*), Bash(*), Task(*)
---

# CLI Mode: Code Analysis (/cli:mode:code-analysis)

## Purpose

Systematic code analysis with execution path tracing template (`~/.claude/workflows/cli-templates/prompts/analysis/01-trace-code-execution.txt`).

**Tool Selection**:
- **gemini** (default) - Best for code analysis and tracing

- **codex** - Alternative for complex analysis tasks

**Key Feature**: `--cd` flag for directory-scoped analysis

## Parameters

- `--tool <gemini|codex>` - Tool selection (default: gemini)
- `--enhance` - Enhance analysis target with `/enhance-prompt` first
- `--cd "path"` - Target directory for focused analysis
- `<analysis-target>` (Required) - Code analysis target or question

## Tool Usage

**Gemini** (Primary):
```bash
/cli:mode:code-analysis --tool gemini "trace auth flow"
# OR (default)
/cli:mode:code-analysis "trace auth flow"
```


```bash
/cli:mode:code-analysis --tool gemini "trace auth flow"
```

**Codex** (Alternative):
```bash
/cli:mode:code-analysis --tool codex "trace auth flow"
```

## Execution Flow

Uses **cli-execution-agent** (default) for automated code analysis:

```javascript
Task(
  subagent_type="cli-execution-agent",
  description="Execution path tracing and call flow analysis",
  prompt=`
    Task: ${analysis_target}
    Mode: code-analysis
    Tool: ${tool_flag || 'gemini'}
    Directory: ${cd_path || '.'}
    Enhance: ${enhance_flag}
    Template: ~/.claude/workflows/cli-templates/prompts/analysis/01-trace-code-execution.txt

    Execute systematic code analysis with execution path tracing:

    1. Context Discovery:
       - Identify entry points and function signatures
       - Trace call chains and execution flows
       - Discover related files (implementations, dependencies, tests)
       - Map data flow and state transformations
       - Use MCP/ripgrep for comprehensive file discovery

    2. Analysis Execution:
       - Apply execution tracing template
       - Generate call flow diagrams (textual)
       - Document execution paths and branching logic
       - Identify optimization opportunities

    3. CLI Command Construction:
       - Directory: cd ${cd_path || '.'} &&
       - Context: @**/* + discovered execution context
       - Mode: analysis (read-only)
       - Template: analysis/01-trace-code-execution.txt

    4. Output Generation:
       - Execution trace documentation
       - Call flow analysis with diagrams
       - Performance and optimization insights
       - Save to .workflow/WFS-[id]/.chat/code-analysis-[timestamp].md (or .scratchpad/)
  `
)
```

## Core Rules

- **Read-only**: Analyzes code, does NOT modify files
- **Template**: `~/.claude/workflows/cli-templates/prompts/analysis/01-trace-code-execution.txt`
- **Output**: `.workflow/WFS-[id]/.chat/code-analysis-[timestamp].md` (or `.scratchpad/` if no session)

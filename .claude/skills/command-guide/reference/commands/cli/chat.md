---
name: chat
description: Read-only Q&A interaction with Gemini/Codex for codebase questions with automatic context inference
argument-hint: "[--tool codex|gemini] [--enhance] inquiry"
allowed-tools: SlashCommand(*), Bash(*), Task(*)
---

# CLI Chat Command (/cli:chat)

## Purpose

Direct Q&A interaction with CLI tools for codebase analysis. **Read-only - does NOT modify code**.

**Tool Selection**:
- **gemini** (default) - Best for Q&A and explanations

- **codex** - Alternative for technical deep-dives

## Parameters

- `--tool <gemini|codex>` - Tool selection (default: gemini)
- `--enhance` - Enhance inquiry with `/enhance-prompt`
- `<inquiry>` (Required) - Question or analysis request

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

Uses **cli-execution-agent** (default) for automated Q&A:

```javascript
Task(
  subagent_type="cli-execution-agent",
  description="Codebase Q&A with intelligent context discovery",
  prompt=`
    Task: ${inquiry}
    Mode: chat
    Tool: ${tool_flag || 'gemini'}
    Enhance: ${enhance_flag}

    Execute codebase Q&A with intelligent context discovery:

    1. Context Discovery:
       - Parse inquiry to identify relevant topics/keywords
       - Discover related files using MCP/ripgrep (prioritize precision)
       - Include @CLAUDE.md + discovered files
       - Validate context relevance to question

    2. CLI Command Construction:
       - Context: @CLAUDE.md + discovered file patterns
       - Mode: analysis (read-only)
       - Expected: Clear, accurate answer with code references

    3. Execution & Output:
       - Execute CLI tool with assembled context
       - Validate answer completeness
       - Save to .workflow/WFS-[id]/.chat/chat-[timestamp].md (or .scratchpad/)
  `
)
```

## Core Rules

- **Read-only**: Provides answers, does NOT modify code
- **Context**: `@CLAUDE.md` + inferred or all files (`@**/*`)
- **Output**: `.workflow/WFS-[id]/.chat/chat-[timestamp].md` (or `.scratchpad/` if no session)

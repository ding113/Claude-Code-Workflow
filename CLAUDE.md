# Development Guidelines

## Overview

This document defines project-specific coding standards and development principles.

### TOON Format (Token-Oriented Object Notation)

This project uses **TOON format** for LLM interactions to achieve 30-60% token savings compared to JSON. TOON is a compact, human-readable serialization format optimized for structured data.

**What is TOON?**
TOON combines YAML's indentation-based structure with CSV's tabular format, optimized for LLM token efficiency. It excels with uniform arrays of objects (same fields, primitive values), which are common in workflow tasks, configuration data, and structured logs.

**Basic Syntax Examples:**
```toon
# Simple object
id: 123
name: Ada
active: true

# Nested object
user:
  id: 123
  name: Ada

# Uniform array (tabular format) - declares length [N] and fields {field1,field2}
users[2]{id,name,role}:
  1,Alice,admin
  2,Bob,user

# Primitive array (inline)
tags[3]: admin,ops,dev
```

**Key Benefits:**
- 30-60% fewer tokens vs formatted JSON (benchmarked: 73.9% LLM accuracy vs JSON's 69.7%)
- Explicit structure with `[N]` length declarations and `{fields}` headers improves LLM reliability
- Self-documenting format reduces parsing errors
- Minimal syntax: no redundant braces, brackets, or repeated keys

**Using TOON in This Project:**
- Use `encodeTOON(data)` to convert JavaScript objects to TOON format (see `src/utils/toon.ts`)
- Use `decodeTOON(input)` to parse TOON back to JavaScript
- Use `autoDecode(input)` for automatic format detection (supports both JSON and TOON)
- Workflow tasks, agent configs, and structured data should prefer TOON format
- Backward compatibility maintained: JSON files still work via auto-detection

**When to Use TOON:**
- ✅ Workflow task definitions with uniform structures
- ✅ Configuration files with repeated object patterns
- ✅ Large datasets with consistent field sets
- ❌ Deeply nested or non-uniform data (JSON may be more efficient)
- ❌ External API contracts (stick with JSON for interoperability)

**References:**
- Utilities: `src/utils/toon.ts`
- Tests: `tests/integration/toon-format.test.ts`
- Official docs: [TOON Specification](https://github.com/toon-format/spec)

### CLI Tool Context Protocols
For all CLI tool usage, command syntax, and integration guidelines:
- **MCP Tool Strategy**: @~/.claude/workflows/mcp-tool-strategy.md
- **Intelligent Context Strategy**: @~/.claude/workflows/intelligent-tools-strategy.md
- **Context Search Commands**: @~/.claude/workflows/context-search-strategy.md

**Context Requirements**:
- Identify 3+ existing similar patterns before implementation
- Map dependencies and integration points
- Understand testing framework and coding conventions


## Philosophy

### Core Beliefs

- **Pursue good taste** - Eliminate edge cases to make code logic natural and elegant
- **Embrace extreme simplicity** - Complexity is the root of all evil
- **Be pragmatic** - Code must solve real-world problems, not hypothetical ones
- **Data structures first** - Bad programmers worry about code; good programmers worry about data structures
- **Never break backward compatibility** - Existing functionality is sacred and inviolable
- **Incremental progress over big bangs** - Small changes that compile and pass tests
- **Learning from existing code** - Study and plan before implementing
- **Clear intent over clever code** - Be boring and obvious
- **Follow existing code style** - Match import patterns, naming conventions, and formatting of existing codebase
- **No unsolicited reports** - Task summaries can be performed internally, but NEVER generate additional reports, documentation files, or summary files without explicit user permission

### Simplicity Means

- Single responsibility per function/class
- Avoid premature abstractions
- No clever tricks - choose the boring solution
- If you need to explain it, it's too complex

## Project Integration

### Learning the Codebase

- Find 3 similar features/components
- Identify common patterns and conventions
- Use same libraries/utilities when possible
- Follow existing test patterns

### Tooling

- Use project's existing build system
- Use project's test framework  
- Use project's formatter/linter settings
- Don't introduce new tools without strong justification

## Important Reminders

**NEVER**:
- Make assumptions - verify with existing code
- Generate reports, summaries, or documentation files without explicit user request

**ALWAYS**:
- Plan complex tasks thoroughly before implementation
- Generate task decomposition for multi-module work (>3 modules or >5 subtasks)
- Track progress using TODO checklists for complex tasks
- Validate planning documents before starting development
- Commit working code incrementally
- Update plan documentation and progress tracking as you go
- Learn from existing implementations
- Stop after 3 failed attempts and reassess

## Platform-Specific Guidelines

### Windows Path Format Guidelines
- always use complete absolute Windows paths with drive letters and backslashes for ALL file operations
- **MCP Tools**: Use double backslash `D:\\path\\file.txt` (MCP doesn't support POSIX `/d/path`)
- **Bash Commands**: Use forward slash `D:/path/file.txt` or POSIX `/d/path/file.txt`
- **Relative Paths**: No conversion needed `./src`, `../config`
- **Quick Ref**: `C:\Users` → MCP: `C:\\Users` | Bash: `/c/Users` or `C:/Users`

#### **Content Uniqueness Rules**

- **Each layer owns its abstraction level** - no content sharing between layers
- **Reference, don't duplicate** - point to other layers, never copy content
- **Maintain perspective** - each layer sees the system at its appropriate scale
- **Avoid implementation creep** - higher layers stay architectural


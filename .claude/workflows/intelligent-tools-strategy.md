# Intelligent Tools Selection Strategy

## 📋 Table of Contents
1. [Quick Start](#-quick-start)
2. [Tool Specifications](#-tool-specifications)
3. [Command Templates](#-command-templates)
4. [Execution Configuration](#-execution-configuration)
5. [Best Practices](#-best-practices)

---

## ⚡ Quick Start

### Universal Prompt Template

All CLI tools (Gemini, Codex) share this template structure:

```
PURPOSE: [objective + why + success criteria]
TASK: • [step 1] • [step 2] • [step 3]
MODE: [analysis|write|auto]
CONTEXT: @**/* | Memory: [session/tech/module context]
EXPECTED: [format + quality + structure]
RULES: $(cat ~/.claude/workflows/cli-templates/prompts/analysis/pattern.txt) | [constraints] | MODE=[permission level]
```

### Tool Selection

- **Analysis/Documentation** → Gemini
- **Implementation/Testing** → Codex

### Quick Command Syntax

```bash
# Gemini
cd [dir] && gemini -p "[prompt]" [-m model] [--approval-mode yolo]

# Codex
codex -C [dir] --full-auto exec "[prompt]" [-m model] [--skip-git-repo-check -s danger-full-access]
```

### Model Selection

**Gemini**:
- `gemini-2.5-pro` - Analysis (default)
- `gemini-2.5-flash` - Documentation updates

 

**Codex**:
- `gpt-5.1-codex` - Analysis & execution (default)
- `gpt-5.1-codex` - Large context tasks

**Note**: `-m` parameter placed AFTER prompt

### Quick Decision Matrix

| Scenario | Tool | MODE | Template |
|----------|------|------|----------|
| Execution Tracing | Gemini | analysis | `analysis/01-trace-code-execution.txt` |
| Bug Diagnosis | Gemini | analysis | `analysis/01-diagnose-bug-root-cause.txt` |
| Architecture Planning | Gemini | analysis | `planning/01-plan-architecture-design.txt` |
| Code Pattern Analysis | Gemini | analysis | `analysis/02-analyze-code-patterns.txt` |
| Architecture Review | Gemini | analysis | `analysis/02-review-architecture.txt` |
| Feature Implementation | Codex | auto | `development/02-implement-feature.txt` |
| Component Development | Codex | auto | `development/02-implement-component-ui.txt` |
| Test Generation | Codex | write | `development/02-generate-tests.txt` |

### Core Principles

- **Use tools early and often** - Tools are faster and more thorough
- **When in doubt, use both** - Parallel usage provides comprehensive coverage
- **Default to tools** - Use for most coding tasks, no matter how small
- **Minimize context noise** - Use `cd` + `--include-directories` to focus on relevant files
- **⚠️ Choose templates by need** - Select templates based on task requirements:
  - `00-*` for universal fallback when no specific template matches
  - `01-*` for general exploratory/diagnostic work
  - `02-*` for common implementation/analysis tasks
  - `03-*` for specialized domains
- **⚠️ Always specify templates** - Include appropriate template in RULES field via `$(cat ~/.claude/workflows/cli-templates/prompts/.../...txt)`
- **⚠️ Universal templates as fallback** - Use universal templates when no specific template matches your needs:
  - `universal/00-universal-rigorous-style.txt` for precision-critical tasks
  - `universal/00-universal-creative-style.txt` for exploratory/innovative tasks
- **⚠️ Write protection** - Require EXPLICIT MODE=write or MODE=auto specification

---

## 🎯 Tool Specifications

### MODE Options

**analysis** (default for Gemini)
- Read-only operations, no file modifications
- Analysis output returned as text response
- Use for: code review, architecture analysis, pattern discovery
- Permission: Default, no special parameters needed

**write** (Gemini/Codex)
- File creation/modification/deletion allowed
- Requires explicit MODE=write specification
- Use for: documentation generation, code creation, file modifications
- Permission:
  - Gemini: `--approval-mode yolo`
  - Codex: `--skip-git-repo-check -s danger-full-access`

**auto** (Codex only)
- Full autonomous development operations
- Requires explicit MODE=auto specification
- Use for: feature implementation, bug fixes, autonomous development
- Permission: `--skip-git-repo-check -s danger-full-access`

### Gemini

**Command**: `gemini`

**Strengths**: Large context window, pattern recognition

**Best For**: Analysis, documentation generation, code exploration, architecture review

**Default MODE**: `analysis` (read-only)

**Priority**: Prefer Gemini; use Gemini as fallback when Gemini unavailable

**Error Handling**:
- **HTTP 429**: May show error but still return results - check if results exist (results present = success, no results = retry)

### Codex

**Command**: `codex --full-auto exec`

**Strengths**: Autonomous development, mathematical reasoning

**Best For**: Implementation, testing, automation

**Default MODE**: No default, must be explicitly specified

**Session Management**:
- `codex resume` - Resume previous session (picker)
- `codex resume --last` - Resume most recent session
- `codex -i <image_file>` - Attach image to prompt

**Multi-task Pattern**:
- **First task**: MUST use full Standard Prompt Template with `exec` to establish complete context
- **Subsequent tasks**: Can use brief prompt with `exec "..." resume --last` (inherits context from session)

**Prompt Requirements**:
- **Without `resume --last`**: ALWAYS use full Standard Prompt Template
- **With `resume --last`**: Brief description sufficient (previous template context inherited)

**Auto-Resume Rules**:
- **Use `resume --last`**: Related tasks, extending previous work, multi-step workflow
- **Don't use**: First task, new independent work, different module

---

## 🎯 Command Templates

### Universal Template Structure

Every command MUST follow this structure:

- [ ] **PURPOSE** - Clear goal and intent
  - State the high-level objective of this execution
  - Explain why this task is needed
  - Define success criteria
  - Example: "Analyze authentication module to identify security vulnerabilities"

- [ ] **TASK** - Specific execution task (use list format: • Task item 1 • Task item 2 • Task item 3)
  - Break down PURPOSE into concrete, actionable steps
  - Use bullet points (•) for multiple sub-tasks
  - Order tasks by execution sequence
  - Example: "• Review auth implementation patterns • Identify potential security risks • Document findings with recommendations"

- [ ] **MODE** - Execution mode and permission level
  - `analysis` (default): Read-only operations, no file modifications
  - `write`: File creation/modification/deletion allowed (requires explicit specification)
  - `auto`: Full autonomous development operations (Codex only, requires explicit specification)
  - Example: "MODE: analysis" or "MODE: write"

- [ ] **CONTEXT** - File references and memory context from previous sessions
  - **File Patterns**: Use @ syntax for file references (default: `@**/*` for all files)
    - `@**/*` - All files in current directory tree
    - `@src/**/*.ts` - TypeScript files in src directory
    - `@../shared/**/*` - Files from sibling directory (requires `--include-directories`)
  - **Memory Context**: Reference previous session findings and context
    - Related tasks: `Building on previous analysis from [session/commit]`
    - Tech stack: `Using patterns from [tech-stack-name] documentation`
    - Cross-reference: `Related to implementation in [module/file]`
  - **Memory Sources**: Include relevant memory sources
    - Documentation: `CLAUDE.md`, module-specific docs
  - Example: "CONTEXT: @src/auth/**/* @CLAUDE.md | Memory: Building on previous auth refactoring (commit abc123)"

- [ ] **EXPECTED** - Clear expected results
  - Specify deliverable format (report, code, documentation, list)
  - Define quality criteria
  - State output structure requirements
  - Example: "Comprehensive security report with categorized findings, risk levels, and actionable recommendations"

- [ ] **RULES** - Template reference and constraints (include mode constraints: analysis=READ-ONLY | write=CREATE/MODIFY/DELETE | auto=FULL operations)
  - Reference templates: `$(cat ~/.claude/workflows/cli-templates/prompts/[category]/[template].txt)`
  - Specify constraints and boundaries
  - Include mode-specific constraints:
    - `analysis=READ-ONLY` - No file modifications
    - `write=CREATE/MODIFY/DELETE` - File operations allowed
    - `auto=FULL operations` - Autonomous development
  - Example: "$(cat ~/.claude/workflows/cli-templates/prompts/analysis/security.txt) | Focus on authentication flows only | analysis=READ-ONLY"

### Standard Prompt Template

```
PURPOSE: [clear goal - state objective, why needed, success criteria]
TASK:
• [specific task - actionable step 1]
• [specific task - actionable step 2]
• [specific task - actionable step 3]
MODE: [analysis|write|auto]
CONTEXT: @**/* | Memory: [previous session findings, related implementations, tech stack patterns, workflow context]
EXPECTED: [deliverable format, quality criteria, output structure, testing requirements (if applicable)]
RULES: $(cat ~/.claude/workflows/cli-templates/prompts/[category]/[0X-template-name].txt) | [additional constraints] | [MODE]=[READ-ONLY|CREATE/MODIFY/DELETE|FULL operations]
```

**Template Selection Guide**:
- Choose template based on your specific task, not by sequence number
- `01-*` templates: General-purpose, broad applicability
- `02-*` templates: Common specialized scenarios
- `03-*` templates: Domain-specific needs

### Tool-Specific Configuration

Use the **[Standard Prompt Template](#standard-prompt-template)** for all tools. This section only covers tool-specific command syntax.

#### Gemini

**Command Format**: `cd [directory] && [tool] -p "[Standard Prompt Template]" [options]`

**Syntax Elements**:
- **Directory**: `cd [directory] &&` (navigate to target directory)
- **Tool**: `gemini` (primary) | `gemini` (fallback)
- **Prompt**: `-p "[Standard Prompt Template]"` (prompt BEFORE options)
- **Model**: `-m [model-name]` (optional, placed AFTER prompt)
  - Gemini: `gemini-2.5-pro` (default) | `gemini-2.5-flash`

- **Write Permission**: `--approval-mode yolo` (ONLY for MODE=write, placed AFTER prompt)

**Command Examples**:
```bash
# Analysis Mode (default, read-only)
cd [directory] && gemini -p "[Standard Prompt Template]" -m gemini-2.5-pro

# Write Mode (requires MODE=write in template + --approval-mode yolo)
cd [directory] && gemini -p "[Standard Prompt Template with MODE: write]" -m gemini-2.5-flash --approval-mode yolo

# Fallback
cd [directory] && gemini -p "[Standard Prompt Template]" -m coder-model

# Multi-directory support
cd [directory] && gemini -p "[Standard Prompt Template]" -m gemini-2.5-pro --include-directories ../shared,../types
```

#### Codex

**Command Format**: `codex -C [directory] --full-auto exec "[Standard Prompt Template]" [options]`

**Syntax Elements**:
- **Directory**: `-C [directory]` (target directory parameter)
- **Execution Mode**: `--full-auto exec` (required for autonomous execution)
- **Prompt**: `exec "[Standard Prompt Template]"` (prompt BEFORE options)
- **Model**: `-m [model-name]` (optional, placed AFTER prompt, BEFORE flags)
  - `gpt-5.1-codex` (default) | `gpt-5.1-codex` (large context)
- **Write Permission**: `--skip-git-repo-check -s danger-full-access` (ONLY for MODE=auto or MODE=write, placed at command END)
- **Session Resume**: `resume --last` (placed AFTER prompt, BEFORE flags)

**Command Examples**:
```bash
# Auto Mode (requires MODE=auto in template + permission flags)
codex -C [directory] --full-auto exec "[Standard Prompt Template with MODE: auto]" -m gpt-5.1-codex --skip-git-repo-check -s danger-full-access

# Write Mode (requires MODE=write in template + permission flags)
codex -C [directory] --full-auto exec "[Standard Prompt Template with MODE: write]" -m gpt-5.1-codex --skip-git-repo-check -s danger-full-access

# Session continuity
# First task - MUST use full Standard Prompt Template to establish context
codex -C project --full-auto exec "[Standard Prompt Template with MODE: auto]" -m gpt-5.1-codex --skip-git-repo-check -s danger-full-access

# Subsequent tasks - Can use brief prompt ONLY when using 'resume --last'
# (inherits full context from previous session, no need to repeat template)
codex --full-auto exec "Add JWT refresh token validation" resume --last --skip-git-repo-check -s danger-full-access

# With image attachment
codex -C [directory] -i design.png --full-auto exec "[Standard Prompt Template]" -m gpt-5.1-codex --skip-git-repo-check -s danger-full-access
```

**Complete Example (Codex with full template)**:
```bash
# First task - establish session with full template
codex -C project --full-auto exec "
PURPOSE: Implement authentication module
TASK: • Create auth service • Add user validation • Setup JWT tokens
MODE: auto
CONTEXT: @**/* | Memory: Following security patterns from project standards
EXPECTED: Complete auth module with tests
RULES: $(cat ~/.claude/workflows/cli-templates/prompts/development/02-implement-feature.txt) | Follow existing patterns | auto=FULL operations
" -m gpt-5.1-codex --skip-git-repo-check -s danger-full-access

# Subsequent tasks - brief description with resume
codex --full-auto exec "Add JWT refresh token validation" resume --last --skip-git-repo-check -s danger-full-access
```

### Directory Context Configuration

**Tool Directory Navigation**:
- **Gemini**: `cd path/to/project && gemini -p "prompt"`
- **Codex**: `codex -C path/to/project --full-auto exec "task"`
- **Path types**: Supports both relative (`../project`) and absolute (`/full/path`)

#### Critical Directory Scope Rules

**Once `cd` to a directory**:
- @ references ONLY apply to current directory and subdirectories
- `@**/*` = All files within current directory tree
- `@*.ts` = TypeScript files in current directory tree
- `@src/**/*` = Files within src subdirectory
- CANNOT reference parent/sibling directories via @ alone

**To reference files outside current directory (TWO-STEP REQUIREMENT)**:
1. Add `--include-directories` parameter to make external directories ACCESSIBLE
2. Explicitly reference external files in CONTEXT field with @ patterns
3. ⚠️ BOTH steps are MANDATORY

Example: `cd src/auth && gemini -p "CONTEXT: @**/* @../shared/**/*" -m gemini-2.5-pro --include-directories ../shared`

**Rule**: If CONTEXT contains `@../dir/**/*`, command MUST include `--include-directories ../dir`

#### Multi-Directory Support (Gemini)

**Parameter**: `--include-directories <dir1,dir2,...>`
- Includes additional directories beyond current `cd` directory
- Can be specified multiple times or comma-separated
- Maximum 5 directories
- REQUIRED when working in subdirectory but needing parent/sibling context

**Syntax**:
```bash
# Comma-separated format
gemini -p "prompt" -m gemini-2.5-pro --include-directories /path/to/project1,/path/to/project2

# Multiple flags format
gemini -p "prompt" -m gemini-2.5-pro --include-directories /path/to/project1 --include-directories /path/to/project2

# Recommended: cd + --include-directories
cd src/auth && gemini -p "
PURPOSE: Analyze authentication with shared utilities context
TASK: Review auth implementation and its dependencies
MODE: analysis
CONTEXT: @**/* @../shared/**/* @../types/**/*
EXPECTED: Complete analysis with cross-directory dependencies
RULES: $(cat ~/.claude/workflows/cli-templates/prompts/analysis/02-analyze-code-patterns.txt) | Focus on integration patterns | analysis=READ-ONLY
" -m gemini-2.5-pro --include-directories ../shared,../types
```

**Best Practices**:
- Use `cd` to navigate to primary focus directory
- Use `--include-directories` for additional context
- ⚠️ CONTEXT must explicitly list external files AND command must include `--include-directories`
- Benefits: Minimizes irrelevant file interference, more precise file references
- Pattern matching rule: `@../dir/**/*` in CONTEXT → `--include-directories ../dir` in command (MANDATORY)

### CONTEXT Field Configuration

CONTEXT field consists of: **File Patterns** + **Memory Context**

#### File Pattern Reference

**Default**: `@**/*` (all files - use as default for comprehensive context)

**Common Patterns**:
- Source files: `@src/**/*`
- TypeScript: `@*.ts @*.tsx`
- With docs: `@CLAUDE.md @**/*CLAUDE.md`
- Tests: `@src/**/*.test.*`

#### Memory Context Integration

**Purpose**: Leverage previous session findings, related implementations, and established patterns to provide continuity

**Format**: `CONTEXT: [file patterns] | Memory: [memory context]`

**Memory Sources**:

1. **Related Tasks** - Cross-task context
   - Previous refactoring, task extensions, conflict resolution

2. **Tech Stack Patterns** - Framework and library conventions
   - React hooks patterns, TypeScript utilities, security guidelines

3. **Cross-Module References** - Inter-module dependencies
   - Integration points, shared utilities, type dependencies

**Memory Context Examples**:

```bash
# Example 1: Building on related task
CONTEXT: @src/auth/**/* @CLAUDE.md | Memory: Building on previous auth refactoring (commit abc123), implementing refresh token mechanism following React hooks patterns

# Example 2: Cross-module integration
CONTEXT: @src/payment/**/* @src/shared/types/**/* | Memory: Integration with auth module from previous implementation, using shared error handling patterns from @shared/utils/errors.ts
```

**Best Practices**:
- **Always include memory context** when building on previous work
- **Reference commits/tasks**: Use commit hashes or task IDs for traceability
- **Document dependencies** with explicit file references
- **Cross-reference implementations** with file paths
- **Use consistent format**: `CONTEXT: [file patterns] | Memory: [memory context]`

#### Complex Pattern Discovery

For complex file pattern requirements, use semantic discovery BEFORE CLI execution:

**Tools**:
- `rg (ripgrep)` - Content-based file discovery with regex
- `mcp__code-index__search_code_advanced` - Semantic file search

**Workflow**: Discover → Extract precise paths → Build CONTEXT field

**Example**:
```bash
# Step 1: Discover files semantically
rg "export.*Component" --files-with-matches --type ts
mcp__code-index__search_code_advanced(pattern="interface.*Props", file_pattern="*.tsx")

# Step 2: Build precise CONTEXT with file patterns + memory
CONTEXT: @src/components/Auth.tsx @src/types/auth.d.ts @src/hooks/useAuth.ts | Memory: Previous refactoring identified type inconsistencies, following React hooks patterns

# Step 3: Execute CLI with precise references
cd src && gemini -p "
PURPOSE: Analyze authentication components for type safety improvements
TASK:
• Review auth component patterns and props interfaces
• Identify type inconsistencies in auth components
• Recommend improvements following React best practices
MODE: analysis
CONTEXT: @components/Auth.tsx @types/auth.d.ts @hooks/useAuth.ts | Memory: Previous refactoring identified type inconsistencies, following React hooks patterns, related implementation in @hooks/useAuth.ts (commit abc123)
EXPECTED: Comprehensive analysis report with type safety recommendations, code examples, and references to previous findings
RULES: $(cat ~/.claude/workflows/cli-templates/prompts/analysis/02-analyze-code-patterns.txt) | Focus on type safety and component composition | analysis=READ-ONLY
" -m gemini-2.5-pro
```

### RULES Field Configuration

**Basic Format**: `RULES: $(cat ~/.claude/workflows/cli-templates/prompts/[category]/[template].txt) | [constraints]`

**⚠️ Command Substitution Rules**:
- **Template reference only, never read**: Use `$(cat ...)` directly, do NOT read template content first
- **NEVER use escape characters**: `\$`, `\"`, `\'` will break command substitution
- **In prompt context**: Path needs NO quotes (tilde expands correctly)
- **Correct**: `RULES: $(cat ~/.claude/workflows/cli-templates/prompts/analysis/01-trace-code-execution.txt)`
- **WRONG**: `RULES: \$(cat ...)` or `RULES: $(cat \"...\")`
- **Why**: Shell executes `$(...)` in subshell where path is safe

**Examples**:
- Universal rigorous: `$(cat ~/.claude/workflows/cli-templates/prompts/universal/00-universal-rigorous-style.txt) | Critical production refactoring`
- Universal creative: `$(cat ~/.claude/workflows/cli-templates/prompts/universal/00-universal-creative-style.txt) | Explore alternative architecture approaches`
- General template: `$(cat ~/.claude/workflows/cli-templates/prompts/analysis/01-diagnose-bug-root-cause.txt) | Focus on authentication module`
- Specialized template: `$(cat ~/.claude/workflows/cli-templates/prompts/analysis/02-analyze-code-patterns.txt) | React hooks only`
- Multiple: `$(cat template1.txt) $(cat template2.txt) | Enterprise standards`
- No template: `Focus on security patterns, include dependency analysis`

### Template System

**Base**: `~/.claude/workflows/cli-templates/`

**Naming Convention**:
- `00-*` - **Universal fallback templates** (use when no specific template matches)
- `01-*` - Universal, high-frequency templates
- `02-*` - Common specialized templates
- `03-*` - Domain-specific, less frequent templates

**Note**: Number prefix indicates category and frequency, not required usage order. Choose based on task needs.

**Universal Templates (Fallback)**:

When no specific template matches your task requirements, use one of these universal templates based on the desired execution style:

1. **Rigorous Style** (`universal/00-universal-rigorous-style.txt`)
   - **Use for**: Precision-critical tasks requiring systematic methodology
   - **Characteristics**:
     - Strict adherence to standards and specifications
     - Comprehensive validation and edge case handling
     - Defensive programming and error prevention
     - Full documentation and traceability
   - **Best for**: Production code, critical systems, refactoring, compliance tasks
   - **Thinking mode**: Systematic, methodical, standards-driven

2. **Creative Style** (`universal/00-universal-creative-style.txt`)
   - **Use for**: Exploratory tasks requiring innovative solutions
   - **Characteristics**:
     - Multi-perspective problem exploration
     - Pattern synthesis from different domains
     - Alternative approach generation
     - Elegant simplicity pursuit
   - **Best for**: New feature design, architecture exploration, optimization, problem-solving
   - **Thinking mode**: Exploratory, synthesis-driven, innovation-focused

**Selection Guide**:
- **Rigorous**: When correctness, reliability, and compliance are paramount
- **Creative**: When innovation, flexibility, and elegant solutions are needed
- **Specific template**: When task matches predefined category (analysis, development, planning, etc.)

**Available Templates**:
```
prompts/
├── universal/                          # ← NEW: Universal fallback templates
│   ├── 00-universal-rigorous-style.txt # Precision & standards-driven
│   └── 00-universal-creative-style.txt # Innovation & exploration-focused
├── analysis/
│   ├── 01-trace-code-execution.txt
│   ├── 01-diagnose-bug-root-cause.txt
│   ├── 02-analyze-code-patterns.txt
│   ├── 02-review-architecture.txt
│   ├── 02-review-code-quality.txt
│   ├── 03-analyze-performance.txt
│   ├── 03-assess-security-risks.txt
│   └── 03-review-quality-standards.txt
├── development/
│   ├── 02-implement-feature.txt
│   ├── 02-refactor-codebase.txt
│   ├── 02-generate-tests.txt
│   ├── 02-implement-component-ui.txt
│   └── 03-debug-runtime-issues.txt
└── planning/
    ├── 01-plan-architecture-design.txt
    ├── 02-breakdown-task-steps.txt
    ├── 02-design-component-spec.txt
    ├── 03-evaluate-concept-feasibility.txt
    └── 03-plan-migration-strategy.txt
```

**Task-Template Matrix**:

| Task Type | Tool | Template |
|-----------|------|----------|
| **Universal Fallbacks** | | |
| Precision-Critical Tasks | Gemini/Codex | `universal/00-universal-rigorous-style.txt` |
| Exploratory/Innovative Tasks | Gemini/Codex | `universal/00-universal-creative-style.txt` |
| **Analysis Tasks** | | |
| Execution Tracing | Gemini | `analysis/01-trace-code-execution.txt` |
| Bug Diagnosis | Gemini | `analysis/01-diagnose-bug-root-cause.txt` |
| Code Pattern Analysis | Gemini | `analysis/02-analyze-code-patterns.txt` |
| Architecture Review | Gemini | `analysis/02-review-architecture.txt` |
| Code Review | Gemini | `analysis/02-review-code-quality.txt` |
| Performance Analysis | Gemini | `analysis/03-analyze-performance.txt` |
| Security Assessment | Gemini | `analysis/03-assess-security-risks.txt` |
| Quality Standards | Gemini | `analysis/03-review-quality-standards.txt` |
| **Planning Tasks** | | |
| Architecture Planning | Gemini | `planning/01-plan-architecture-design.txt` |
| Task Breakdown | Gemini | `planning/02-breakdown-task-steps.txt` |
| Component Design | Gemini | `planning/02-design-component-spec.txt` |
| Concept Evaluation | Gemini | `planning/03-evaluate-concept-feasibility.txt` |
| Migration Planning | Gemini | `planning/03-plan-migration-strategy.txt` |
| **Development Tasks** | | |
| Feature Development | Codex | `development/02-implement-feature.txt` |
| Refactoring | Codex | `development/02-refactor-codebase.txt` |
| Test Generation | Codex | `development/02-generate-tests.txt` |
| Component Implementation | Codex | `development/02-implement-component-ui.txt` |
| Debugging | Codex | `development/03-debug-runtime-issues.txt` |

---

## ⚙️ Execution Configuration

### Dynamic Timeout Allocation

**Timeout Ranges**:
- **Simple** (analysis, search): 20-40min (1200000-2400000ms)
- **Medium** (refactoring, documentation): 40-60min (2400000-3600000ms)
- **Complex** (implementation, migration): 60-120min (3600000-7200000ms)

**Codex Multiplier**: 1.5x of allocated time

**Application**: All bash() wrapped commands including Gemini, Gemini and Codex executions

**Auto-detection**: Analyze PURPOSE and TASK fields to determine timeout

### Permission Framework

**⚠️ Single-Use Explicit Authorization**: Each CLI execution requires explicit user command instruction - one command authorizes ONE execution only. Analysis does NOT authorize write operations. Previous authorization does NOT carry over. Each operation needs NEW explicit user directive.

**Mode Hierarchy**:
- **analysis** (default): Read-only, safe for auto-execution
- **write**: Requires explicit MODE=write specification
- **auto**: Requires explicit MODE=auto specification
- **Exception**: User provides clear instructions like "modify", "create", "implement"

**Tool-Specific Permissions**:
- **Gemini**: Use `--approval-mode yolo` ONLY when MODE=write (placed AFTER prompt)
- **Codex**: Use `--skip-git-repo-check -s danger-full-access` ONLY when MODE=auto or MODE=write (placed at command END)
- **Default**: All tools default to analysis/read-only mode

---

## 🔧 Best Practices

### Workflow Principles

- **Start with templates** - Use predefined templates for consistency
- **Be specific** - Clear PURPOSE, TASK, and EXPECTED fields with detailed descriptions
- **Include constraints** - File patterns, scope, requirements in RULES
- **Leverage memory context** - ALWAYS include Memory field when building on previous work
  - Cross-reference tasks with file paths and commit hashes
  - Document dependencies with explicit file references
  - Reference related implementations and patterns
- **Discover patterns first** - Use rg/MCP for complex file discovery before CLI execution
- **Build precise CONTEXT** - Convert discovery to explicit file references with memory
  - Format: `CONTEXT: [file patterns] | Memory: [memory context]`
  - File patterns: `@**/*` (default) or specific patterns
  - Memory: Previous sessions, tech stack patterns, cross-references
- **Document context** - Always reference CLAUDE.md and relevant documentation
- **Default to full context** - Use `@**/*` unless specific files needed
- **⚠️ No escape characters** - NEVER use `\$`, `\"`, `\'` in CLI commands

### Context Optimization Strategy

**Directory Navigation**: Use `cd [directory] &&` pattern to reduce irrelevant context

**When to change directory**:
- Specific directory mentioned → Use `cd directory &&`
- Focused analysis needed → Target specific directory
- Multi-directory scope → Use `cd` + `--include-directories`

**When to use `--include-directories`**:
- Working in subdirectory but need parent/sibling context
- Cross-directory dependency analysis required
- Multiple related modules need simultaneous access
- **Key benefit**: Excludes unrelated directories, reduces token usage

### Workflow Integration

When planning any coding task, **ALWAYS** integrate CLI tools:

1. **Understanding Phase**: Use Gemini for analysis
2. **Architecture Phase**: Use Gemini for design and analysis
3. **Implementation Phase**: Use Codex for development
4. **Quality Phase**: Use Codex for testing and validation

### Planning Checklist

For every development task:
- [ ] **Purpose defined** - Clear goal and intent
- [ ] **Mode selected** - Execution mode and permission level determined
- [ ] **Context gathered** - File references and session memory documented (default `@**/*`)
- [ ] **Directory navigation** - Determine if `cd` or `cd + --include-directories` needed
- [ ] **Gemini analysis** completed for understanding
- [ ] **Template applied** - Use Standard Prompt Template (universal for all tools)
- [ ] **Constraints specified** - File patterns, scope, requirements
- [ ] **Implementation approach** - Tool selection and workflow

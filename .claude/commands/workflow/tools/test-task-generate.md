---
name: test-task-generate
description: Autonomous test-fix task generation using action-planning-agent with test-fix-retest cycle specification and discovery phase
argument-hint: "[--use-codex] [--cli-execute] --session WFS-test-session-id"
examples:
  - /workflow:tools:test-task-generate --session WFS-test-auth
  - /workflow:tools:test-task-generate --use-codex --session WFS-test-auth
  - /workflow:tools:test-task-generate --cli-execute --session WFS-test-auth
  - /workflow:tools:test-task-generate --cli-execute --use-codex --session WFS-test-auth
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Autonomous Test Task Generation Command

## Overview
Autonomous test-fix task TOON generation using action-planning-agent with two-phase execution: discovery and document generation. Supports both agent-driven execution (default) and CLI tool execution modes. Generates specialized test-fix tasks with comprehensive test-fix-retest cycle specification.

## Core Philosophy
- **Agent-Driven**: Delegate execution to action-planning-agent for autonomous operation
- **Two-Phase Flow**: Discovery (context gathering) → Output (document generation)
- **Memory-First**: Reuse loaded documents from conversation memory
- **MCP-Enhanced**: Use MCP tools for advanced code analysis and test research
- **Pre-Selected Templates**: Command selects correct test template based on `--cli-execute` flag **before** invoking agent
- **Agent Simplicity**: Agent receives pre-selected template and focuses only on content generation
- **Path Clarity**: All `focus_paths` prefer absolute paths (e.g., `D:\\project\\src\\module`), or clear relative paths from project root
- **Test-First**: Generate comprehensive test coverage before execution
- **Iterative Refinement**: Test-fix-retest cycle until all tests pass
- **Surgical Fixes**: Minimal code changes, no refactoring during test fixes
- **Auto-Revert**: Rollback all changes if max iterations reached

## Execution Modes

### Test Generation (IMPL-001)
- **Agent Mode (Default)**: @code-developer generates tests within agent context
- **CLI Execute Mode (`--cli-execute`)**: Use Codex CLI for autonomous test generation

### Test Fix (IMPL-002)
- **Manual Mode (Default)**: Gemini diagnosis → user applies fixes
- **Codex Mode (`--use-codex`)**: Gemini diagnosis → Codex applies fixes with resume mechanism

## Execution Lifecycle

### Phase 1: Discovery & Context Loading
**⚡ Memory-First Rule**: Skip file loading if documents already in conversation memory

**Agent Context Package**:
```javascript
{
  "session_id": "WFS-test-[session-id]",
  "execution_mode": "agent-mode" | "cli-execute-mode",  // Determined by flag
  "task_json_template_path": "~/.claude/workflows/cli-templates/prompts/workflow/task-json-agent-mode.txt"
                           | "~/.claude/workflows/cli-templates/prompts/workflow/task-json-cli-mode.txt",
  // Path selected by command based on --cli-execute flag, agent reads it
  "workflow_type": "test_session",
  "use_codex": true | false,  // Determined by --use-codex flag
  "session_metadata": {
    // If in memory: use cached content
    // Else: Load from .workflow/{test-session-id}/workflow-session.toon
  },
  "test_analysis_results_path": ".workflow/{test-session-id}/.process/TEST_ANALYSIS_RESULTS.md",
  "test_analysis_results": {
    // If in memory: use cached content
    // Else: Load from TEST_ANALYSIS_RESULTS.md
  },
  "test_context_package_path": ".workflow/{test-session-id}/.process/test-context-package.toon",
  "test_context_package": {
    // Existing test patterns and coverage analysis
  },
  "source_session_id": "[source-session-id]",  // if exists
  "source_session_summaries": {
    // Implementation context from source session
  },
  "mcp_capabilities": {
    "code_index": true,
    "exa_code": true,
    "exa_web": true
  }
}
```

**Discovery Actions**:
1. **Load Test Session Context** (if not in memory)
   ```javascript
   if (!memory.has("workflow-session.toon")) {
     Read(.workflow/{test-session-id}/workflow-session.toon)
   }
   ```

2. **Load TEST_ANALYSIS_RESULTS.md** (if not in memory, REQUIRED)
   ```javascript
   if (!memory.has("TEST_ANALYSIS_RESULTS.md")) {
     Read(.workflow/{test-session-id}/.process/TEST_ANALYSIS_RESULTS.md)
   }
   ```

3. **Load Test Context Package** (if not in memory)
   ```javascript
   if (!memory.has("test-context-package.toon")) {
     Read(.workflow/{test-session-id}/.process/test-context-package.toon)
   }
   ```

4. **Load Source Session Summaries** (if source_session_id exists)
   ```javascript
   if (sessionMetadata.source_session_id) {
     const summaryFiles = Bash("find .workflow/{source-session-id}/.summaries/ -name 'IMPL-*-summary.md'")
     summaryFiles.forEach(file => Read(file))
   }
   ```

5. **Code Analysis with Native Tools** (optional - enhance understanding)
   ```bash
   # Find test files and patterns
   find . -name "*test*" -type f
   rg "describe|it\(|test\(" -g "*.ts"
   ```

6. **MCP External Research** (optional - gather test best practices)
   ```javascript
   // Get external test examples and patterns
   mcp__exa__get_code_context_exa(
     query="TypeScript test generation best practices jest",
     tokensNum="dynamic"
   )
   ```

### Phase 2: Agent Execution (Document Generation)

**Pre-Agent Template Selection** (Command decides path before invoking agent):
```javascript
// Command checks flag and selects template PATH (not content)
const templatePath = hasCliExecuteFlag
  ? "~/.claude/workflows/cli-templates/prompts/workflow/task-json-cli-mode.txt"
  : "~/.claude/workflows/cli-templates/prompts/workflow/task-json-agent-mode.txt";
```

**Agent Invocation**:
```javascript
Task(
  subagent_type="action-planning-agent",
  description="Generate test-fix task TOON and implementation plan",
  prompt=`
## Execution Context

**Session ID**: WFS-test-{session-id}
**Workflow Type**: Test Session
**Execution Mode**: {agent-mode | cli-execute-mode}
**Task TOON Template Path**: {template_path}
**Use Codex**: {true | false}

## Phase 1: Discovery Results (Provided Context)

### Test Session Metadata
{session_metadata_content}
- source_session_id: {source_session_id} (if exists)
- workflow_type: "test_session"

### TEST_ANALYSIS_RESULTS.md (REQUIRED)
{test_analysis_results_content}
- Coverage Assessment
- Test Framework & Conventions
- Test Requirements by File
- Test Generation Strategy
- Implementation Targets
- Success Criteria

### Test Context Package
{test_context_package_summary}
- Existing test patterns, framework config, coverage analysis

### Source Session Implementation Context (Optional)
{source_session_summaries}
- Implementation context from completed session

### MCP Analysis Results (Optional)
**Code Structure**: {mcp_code_index_results}
**External Research**: {mcp_exa_research_results}

## Phase 2: Test Task Document Generation

**Agent Configuration Reference**: All test task generation rules, test-fix cycle structure, quality standards, and execution details are defined in action-planning-agent.

Refer to: @.claude/agents/action-planning-agent.md for:
- Test Task Decomposition Standards
- Test-Fix-Retest Cycle Requirements
- 5-Field Task TOON Schema
- IMPL_PLAN.md Structure (Test variant)
- TODO_LIST.md Format
- Test Execution Flow & Quality Validation

### Test-Specific Requirements Summary

#### Task Structure Philosophy
- **Minimum 2 tasks**: IMPL-001 (test generation) + IMPL-002 (test execution & fix)
- **Expandable**: Add IMPL-003+ for complex projects (per-module, integration, etc.)
- IMPL-001: Uses @code-developer or CLI execution
- IMPL-002: Uses @test-fix-agent with iterative fix cycle

#### Test-Fix Cycle Configuration
- **Max Iterations**: 5 (for IMPL-002)
- **Diagnosis Tool**: Gemini with bug-fix template
- **Fix Application**: Manual (default) or Codex (if --use-codex flag)
- **Cycle Pattern**: test → gemini_diagnose → manual_fix (or codex) → retest
- **Exit Conditions**: All tests pass OR max iterations reached (auto-revert)

#### Required Outputs Summary

##### 1. Test Task TOON Files (.task/IMPL-*.toon)
- **Location**: `.workflow/{test-session-id}/.task/`
- **Template**: Read from `{template_path}` (pre-selected by command based on `--cli-execute` flag)
- **Schema**: 5-field structure with test-specific metadata
  - IMPL-001: `meta.type: "test-gen"`, `meta.agent: "@code-developer"`
  - IMPL-002: `meta.type: "test-fix"`, `meta.agent: "@test-fix-agent"`, `meta.use_codex: {use_codex}`
  - `flow_control`: Test generation approach (IMPL-001) or test-fix cycle (IMPL-002)
- **Details**: See action-planning-agent.md § Test Task TOON Generation

##### 2. IMPL_PLAN.md (Test Variant)
- **Location**: `.workflow/{test-session-id}/IMPL_PLAN.md`
- **Template**: `~/.claude/workflows/cli-templates/prompts/workflow/impl-plan-template.txt`
- **Test-Specific Frontmatter**: workflow_type="test_session", test_framework, source_session_id
- **Test-Fix-Retest Cycle Section**: Iterative fix cycle with Gemini diagnosis
- **Details**: See action-planning-agent.md § Test Implementation Plan Creation

##### 3. TODO_LIST.md
- **Location**: `.workflow/{test-session-id}/TODO_LIST.md`
- **Format**: Task list with test generation and execution phases
- **Status**: [ ] (pending), [x] (completed)
- **Details**: See action-planning-agent.md § TODO List Generation

### Agent Execution Summary

**Key Steps** (Detailed instructions in action-planning-agent.md):
1. Load task TOON template from provided path
2. Parse TEST_ANALYSIS_RESULTS.md for test requirements
3. Generate IMPL-001 (test generation) task TOON
4. Generate IMPL-002 (test execution & fix) task TOON with use_codex flag
5. Generate additional IMPL-*.toon if project complexity requires
6. Create IMPL_PLAN.md using test template variant
7. Generate TODO_LIST.md with test task indicators
8. Update session state with test metadata

**Quality Gates** (Full checklist in action-planning-agent.md):
- ✓ Minimum 2 tasks created (IMPL-001 + IMPL-002)
- ✓ IMPL-001 has test generation approach from TEST_ANALYSIS_RESULTS.md
- ✓ IMPL-002 has test-fix cycle with correct use_codex flag
- ✓ Test framework configuration integrated
- ✓ Source session context referenced (if exists)
- ✓ MCP tool integration added
- ✓ Documents follow test template structure

## Output

Generate all three documents and report completion status:
- Test task TOON files created: N files (minimum 2)
- Test requirements integrated: TEST_ANALYSIS_RESULTS.md
- Test context integrated: existing patterns and coverage
- Source session context: {source_session_id} summaries (if exists)
- MCP enhancements: code-index, exa-research
- Session ready for test execution: /workflow:execute or /workflow:test-cycle-execute
`
)
```

### Agent Context Passing

**Memory-Aware Context Assembly**:
```javascript
// Assemble context package for agent
const agentContext = {
  session_id: "WFS-test-[id]",
  workflow_type: "test_session",
  use_codex: hasUseCodexFlag,

  // Use memory if available, else load
  session_metadata: memory.has("workflow-session.toon")
    ? memory.get("workflow-session.toon")
    : Read(.workflow/WFS-test-[id]/workflow-session.toon),

  test_analysis_results_path: ".workflow/WFS-test-[id]/.process/TEST_ANALYSIS_RESULTS.md",

  test_analysis_results: memory.has("TEST_ANALYSIS_RESULTS.md")
    ? memory.get("TEST_ANALYSIS_RESULTS.md")
    : Read(".workflow/WFS-test-[id]/.process/TEST_ANALYSIS_RESULTS.md"),

  test_context_package_path: ".workflow/WFS-test-[id]/.process/test-context-package.toon",

  test_context_package: memory.has("test-context-package.toon")
    ? memory.get("test-context-package.toon")
    : Read(".workflow/WFS-test-[id]/.process/test-context-package.toon"),

  // Load source session summaries if exists
  source_session_id: session_metadata.source_session_id || null,

  source_session_summaries: session_metadata.source_session_id
    ? loadSourceSummaries(session_metadata.source_session_id)
    : null,

  // Optional MCP enhancements
  mcp_analysis: executeMcpDiscovery()
}
```

## Test Task Structure Reference

This section provides quick reference for test task TOON structure. For complete implementation details, see the agent invocation prompt in Phase 2 above.

**Quick Reference**:
- Minimum 2 tasks: IMPL-001 (test-gen) + IMPL-002 (test-fix)
- Expandable for complex projects (IMPL-003+)
- IMPL-001: `meta.agent: "@code-developer"`, test generation approach
- IMPL-002: `meta.agent: "@test-fix-agent"`, `meta.use_codex: {flag}`, test-fix cycle
- See Phase 2 agent prompt for full schema and requirements

## Output Files Structure
```
.workflow/WFS-test-[session]/
├── workflow-session.toon           # Test session metadata
├── IMPL_PLAN.md                    # Test validation plan
├── TODO_LIST.md                    # Progress tracking
├── .task/
│   └── IMPL-001.toon               # Test-fix task with cycle spec
├── .process/
│   ├── ANALYSIS_RESULTS.md         # From concept-enhanced (optional)
│   ├── context-package.toon        # From context-gather
│   ├── initial-test.log            # Phase 1: Initial test results
│   ├── fix-iteration-1-diagnosis.md # Gemini diagnosis iteration 1
│   ├── fix-iteration-1-changes.log  # Codex changes iteration 1
│   ├── fix-iteration-1-retest.log   # Retest results iteration 1
│   ├── fix-iteration-N-*.md/log    # Subsequent iterations
│   └── final-test.log              # Phase 3: Final validation
└── .summaries/
    └── IMPL-001-summary.md         # Success report OR failure report
```

## Error Handling

### Input Validation Errors
| Error | Cause | Resolution |
|-------|-------|------------|
| Not a test session | Missing workflow_type: "test_session" | Verify session created by test-gen |
| Source session not found | Invalid source_session_id | Check source session exists |
| No implementation summaries | Source session incomplete | Ensure source session has completed tasks |

### Test Framework Discovery Errors
| Error | Cause | Resolution |
|-------|-------|------------|
| No test command found | Unknown framework | Manual test command specification |
| No test files found | Tests not written | Request user to write tests first |
| Test dependencies missing | Incomplete setup | Run dependency installation |

### Generation Errors
| Error | Cause | Resolution |
|-------|-------|------------|
| Invalid JSON structure | Template error | Fix task generation logic |
| Missing required fields | Incomplete metadata | Validate session metadata |

## Integration & Usage

### Command Chain
- **Called By**: `/workflow:test-gen` (Phase 4), `/workflow:test-fix-gen` (Phase 4)
- **Invokes**: `action-planning-agent` for autonomous task generation
- **Followed By**: `/workflow:execute` or `/workflow:test-cycle-execute` (user-triggered)

### Basic Usage
```bash
# Agent mode (default, autonomous execution)
/workflow:tools:test-task-generate --session WFS-test-auth

# With automated Codex fixes for IMPL-002
/workflow:tools:test-task-generate --use-codex --session WFS-test-auth

# CLI execution mode for IMPL-001 test generation
/workflow:tools:test-task-generate --cli-execute --session WFS-test-auth

# Both flags combined
/workflow:tools:test-task-generate --cli-execute --use-codex --session WFS-test-auth
```

### Execution Modes
- **Agent mode** (default): Uses `action-planning-agent` with agent-mode task template
- **CLI mode** (`--cli-execute`): Uses Gemini/Codex with cli-mode task template for IMPL-001
- **Codex fixes** (`--use-codex`): Enables automated fixes in IMPL-002 task

### Flag Behavior
- **No flags**: `meta.use_codex=false` (manual fixes), agent-mode generation
- **--use-codex**: `meta.use_codex=true` (Codex automated fixes with resume mechanism in IMPL-002)
- **--cli-execute**: Uses CLI tool execution mode for IMPL-001 test generation
- **Both flags**: CLI generation + automated Codex fixes

### Output
- Test task TOON files in `.task/` directory (minimum 2: IMPL-001.toon + IMPL-002.toon)
- IMPL_PLAN.md with test generation and fix cycle strategy
- TODO_LIST.md with test task indicators
- Session state updated with test metadata
- MCP enhancements integrated (if available)

## Agent Execution Notes

The `@test-fix-agent` will execute the task by following the `flow_control.implementation_approach` specification:

1. **Load task TOON**: Read complete test-fix task from `.task/IMPL-002.toon`
2. **Check meta.use_codex**: Determine fix mode (manual or automated)
3. **Execute pre_analysis**: Load source context, discover framework, analyze tests
4. **Phase 1**: Run initial test suite
5. **Phase 2**: If failures, enter iterative loop:
   - Use Gemini for diagnosis (analysis mode with bug-fix template)
   - Check meta.use_codex flag:
     - If false (default): Present fix suggestions to user for manual application
     - If true (--use-codex): Use Codex resume for automated fixes (maintains context)
   - Retest and check for regressions
   - Repeat max 5 times
6. **Phase 3**: Generate summary and certify code
7. **Error Recovery**: Revert changes if max iterations reached

**Bug Diagnosis Template**: Uses `~/.claude/workflows/cli-templates/prompts/analysis/01-diagnose-bug-root-cause.txt` template for systematic root cause analysis, code path tracing, and targeted fix recommendations.

**Codex Usage**: The agent uses `codex exec "..." resume --last` pattern ONLY when meta.use_codex=true (--use-codex flag present) to maintain conversation context across multiple fix iterations, ensuring consistency and learning from previous attempts.

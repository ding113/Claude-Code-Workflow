---
name: task-generate-agent
description: Autonomous task generation using action-planning-agent with discovery and output phases for workflow planning
argument-hint: "--session WFS-session-id [--cli-execute]"
examples:
  - /workflow:tools:task-generate-agent --session WFS-auth
  - /workflow:tools:task-generate-agent --session WFS-auth --cli-execute
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Autonomous Task Generation Command

## Overview
Autonomous task TOON and IMPL_PLAN.md generation using action-planning-agent with two-phase execution: discovery and document generation. Supports both agent-driven execution (default) and CLI tool execution modes.

## Core Philosophy
- **Agent-Driven**: Delegate execution to action-planning-agent for autonomous operation
- **Two-Phase Flow**: Discovery (context gathering) → Output (document generation)
- **Memory-First**: Reuse loaded documents from conversation memory
- **MCP-Enhanced**: Use MCP tools for advanced code analysis and research
- **Pre-Selected Templates**: Command selects correct template based on `--cli-execute` flag **before** invoking agent
- **Agent Simplicity**: Agent receives pre-selected template and focuses only on content generation
- **Path Clarity**: All `focus_paths` prefer absolute paths (e.g., `D:\\project\\src\\module`), or clear relative paths from project root (e.g., `./src/module`)

## Execution Lifecycle

### Phase 1: Discovery & Context Loading
**⚡ Memory-First Rule**: Skip file loading if documents already in conversation memory

**Agent Context Package**:
```javascript
{
  "session_id": "WFS-[session-id]",
  "execution_mode": "agent-mode" | "cli-execute-mode",  // Determined by flag
  "task_json_template_path": "~/.claude/workflows/cli-templates/prompts/workflow/task-json-agent-mode.txt"
                           | "~/.claude/workflows/cli-templates/prompts/workflow/task-json-cli-mode.txt",
  // Path selected by command based on --cli-execute flag, agent reads it
  "session_metadata": {
    // If in memory: use cached content
    // Else: Load from .workflow/{session-id}/workflow-session.toon
  },
  "brainstorm_artifacts": {
    // Loaded from context-package.toon → brainstorm_artifacts section
    "role_analyses": [
      {
        "role": "system-architect",
        "files": [{"path": "...", "type": "primary|supplementary"}]
      }
    ],
    "guidance_specification": {"path": "...", "exists": true},
    "synthesis_output": {"path": "...", "exists": true},
    "conflict_resolution": {"path": "...", "exists": true}  // if conflict_risk >= medium
  },
  "context_package_path": ".workflow/{session-id}/.process/context-package.toon",
  "context_package": {
    // If in memory: use cached content
    // Else: Load from .workflow/{session-id}/.process/context-package.toon
  },
  "mcp_capabilities": {
    "code_index": true,
    "exa_code": true,
    "exa_web": true
  }
}
```

**Discovery Actions**:
1. **Load Session Context** (if not in memory)
   ```javascript
   if (!memory.has("workflow-session.toon")) {
     Read(.workflow/{session-id}/workflow-session.toon)
   }
   ```

2. **Load Context Package** (if not in memory)
   ```javascript
   if (!memory.has("context-package.toon")) {
     Read(.workflow/{session-id}/.process/context-package.toon)
   }
   ```

3. **Extract & Load Role Analyses** (from context-package.toon)
   ```javascript
   // Extract role analysis paths from context package
   const roleAnalysisPaths = contextPackage.brainstorm_artifacts.role_analyses
     .flatMap(role => role.files.map(f => f.path));

   // Load each role analysis file
   roleAnalysisPaths.forEach(path => Read(path));
   ```

4. **Load Conflict Resolution** (from context-package.toon, if exists)
   ```javascript
   if (contextPackage.brainstorm_artifacts.conflict_resolution?.exists) {
     Read(contextPackage.brainstorm_artifacts.conflict_resolution.path)
   }
   ```

5. **Code Analysis with Native Tools** (optional - enhance understanding)
   ```bash
   # Find relevant files for task context
   find . -name "*auth*" -type f
   rg "authentication|oauth" -g "*.ts"
   ```

6. **MCP External Research** (optional - gather best practices)
   ```javascript
   // Get external examples for implementation
   mcp__exa__get_code_context_exa(
     query="TypeScript JWT authentication best practices",
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
  description="Generate task TOON and implementation plan",
  prompt=`
## Execution Context

**Session ID**: WFS-{session-id}
**Execution Mode**: {agent-mode | cli-execute-mode}
**Task TOON Template Path**: {template_path}

## Phase 1: Discovery Results (Provided Context)

### Session Metadata
{session_metadata_content}

### Role Analyses (Enhanced by Synthesis)
{role_analyses_content}
- Includes requirements, design specs, enhancements, and clarifications from synthesis phase

### Artifacts Inventory
- **Guidance Specification**: {guidance_spec_path}
- **Role Analyses**: {role_analyses_list}

### Context Package
{context_package_summary}
- Includes conflict_risk assessment

### Conflict Resolution (Conditional)
If conflict_risk was medium/high, modifications have been applied to:
- **guidance-specification.md**: Design decisions updated to resolve conflicts
- **Role analyses (*.md)**: Recommendations adjusted for compatibility
- **context-package.toon**: Marked as "resolved" with conflict IDs
- NO separate CONFLICT_RESOLUTION.md file (conflicts resolved in-place)

### MCP Analysis Results (Optional)
**Code Structure**: {mcp_code_index_results}
**External Research**: {mcp_exa_research_results}

## Phase 2: Document Generation Task

**Agent Configuration Reference**: All task generation rules, quantification requirements, quality standards, and execution details are defined in action-planning-agent.

Refer to: @.claude/agents/action-planning-agent.md for:
- Task Decomposition Standards
- Quantification Requirements (MANDATORY)
- 5-Field Task TOON Schema
- IMPL_PLAN.md Structure
- TODO_LIST.md Format
- Execution Flow & Quality Validation

### Required Outputs Summary

#### 1. Task TOON Files (.task/IMPL-*.toon)
- **Location**: `.workflow/{session-id}/.task/`
- **Template**: Read from `{template_path}` (pre-selected by command based on `--cli-execute` flag)
- **Schema**: 5-field structure (id, title, status, meta, context, flow_control) with artifacts integration
- **Details**: See action-planning-agent.md § Task TOON Generation

#### 2. IMPL_PLAN.md
- **Location**: `.workflow/{session-id}/IMPL_PLAN.md`
- **Template**: `~/.claude/workflows/cli-templates/prompts/workflow/impl-plan-template.txt`
- **Details**: See action-planning-agent.md § Implementation Plan Creation

#### 3. TODO_LIST.md
- **Location**: `.workflow/{session-id}/TODO_LIST.md`
- **Format**: Hierarchical task list with status indicators (▸, [ ], [x]) and JSON links
- **Details**: See action-planning-agent.md § TODO List Generation

### Agent Execution Summary

**Key Steps** (Detailed instructions in action-planning-agent.md):
1. Load task TOON template from provided path
2. Extract and decompose tasks with quantification
3. Generate task TOON files enforcing quantification requirements
4. Create IMPL_PLAN.md using template
5. Generate TODO_LIST.md matching task TOON files
6. Update session state

**Quality Gates** (Full checklist in action-planning-agent.md):
- ✓ Quantification requirements enforced (explicit counts, measurable acceptance, exact targets)
- ✓ Task count ≤10 (hard limit)
- ✓ Artifact references mapped correctly
- ✓ MCP tool integration added
- ✓ Documents follow template structure

## Output

Generate all three documents and report completion status:
- Task TOON files created: N files
- Artifacts integrated: synthesis-spec, guidance-specification, N role analyses
- MCP enhancements: code-index, exa-research
- Session ready for execution: /workflow:execute
`
)
```


### Agent Context Passing

**Memory-Aware Context Assembly**:
```javascript
// Assemble context package for agent
const agentContext = {
  session_id: "WFS-[id]",

  // Use memory if available, else load
  session_metadata: memory.has("workflow-session.toon")
    ? memory.get("workflow-session.toon")
    : Read(.workflow/WFS-[id]/workflow-session.toon),

  context_package_path: ".workflow/WFS-[id]/.process/context-package.toon",

  context_package: memory.has("context-package.toon")
    ? memory.get("context-package.toon")
    : Read(".workflow/WFS-[id]/.process/context-package.toon"),

  // Extract brainstorm artifacts from context package
  brainstorm_artifacts: extractBrainstormArtifacts(context_package),

  // Load role analyses using paths from context package
  role_analyses: brainstorm_artifacts.role_analyses
    .flatMap(role => role.files)
    .map(file => Read(file.path)),

  // Load conflict resolution if exists (from context package)
  conflict_resolution: brainstorm_artifacts.conflict_resolution?.exists
    ? Read(brainstorm_artifacts.conflict_resolution.path)
    : null,

  // Optional MCP enhancements
  mcp_analysis: executeMcpDiscovery()
}
```

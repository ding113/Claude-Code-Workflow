---
name: auto-parallel
description: Parallel brainstorming automation with dynamic role selection and concurrent execution across multiple perspectives
argument-hint: "topic or challenge description" [--count N]
allowed-tools: SlashCommand(*), Task(*), TodoWrite(*), Read(*), Write(*), Bash(*), Glob(*)
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Workflow Brainstorm Parallel Auto Command

## Coordinator Role

**This command is a pure orchestrator**: Execute 3 phases in sequence (interactive framework → parallel role analysis → synthesis), coordinating specialized commands/agents through task attachment model.

**Task Attachment Model**:
- SlashCommand invocation **expands workflow** by attaching sub-tasks to current TodoWrite
- Task agent execution **attaches analysis tasks** to orchestrator's TodoWrite
- Phase 1: artifacts command attaches its internal tasks (Phase 1-5)
- Phase 2: N conceptual-planning-agent tasks attached in parallel
- Phase 3: synthesis command attaches its internal tasks
- Orchestrator **executes these attached tasks** sequentially (Phase 1, 3) or in parallel (Phase 2)
- After completion, attached tasks are **collapsed** back to high-level phase summary
- This is **task expansion**, not external delegation

**Execution Model - Auto-Continue Workflow**:

This workflow runs **fully autonomously** once triggered. Phase 1 (artifacts) handles user interaction, Phase 2 (role agents) runs in parallel.

1. **User triggers**: `/workflow:brainstorm:auto-parallel "topic" [--count N]`
2. **Phase 1 executes** → artifacts command (tasks ATTACHED) → Auto-continues
3. **Phase 2 executes** → Parallel role agents (N tasks ATTACHED concurrently) → Auto-continues
4. **Phase 3 executes** → Synthesis command (tasks ATTACHED) → Reports final summary

**Auto-Continue Mechanism**:
- TodoList tracks current phase status and dynamically manages task attachment/collapse
- When Phase 1 (artifacts) finishes executing, automatically load roles and launch Phase 2 agents
- When Phase 2 (all agents) finishes executing, automatically execute Phase 3 synthesis
- **⚠️ CONTINUOUS EXECUTION** - Do not stop until all phases complete

## Core Rules

1. **Start Immediately**: First action is TodoWrite initialization, second action is Phase 1 command execution
2. **No Preliminary Analysis**: Do not analyze topic before Phase 1 - artifacts handles all analysis
3. **Parse Every Output**: Extract selected_roles from workflow-session.toon after Phase 1
4. **Auto-Continue via TodoList**: Check TodoList status to execute next pending phase automatically
5. **Track Progress**: Update TodoWrite dynamically with task attachment/collapse pattern
6. **Task Attachment Model**: SlashCommand and Task invocations **attach** sub-tasks to current workflow. Orchestrator **executes** these attached tasks itself, then **collapses** them after completion
7. **⚠️ CRITICAL: DO NOT STOP**: Continuous multi-phase workflow. After executing all attached tasks, immediately collapse them and execute next phase
8. **Parallel Execution**: Phase 2 attaches multiple agent tasks simultaneously for concurrent execution

## Usage

```bash
/workflow:brainstorm:auto-parallel "<topic>" [--count N] [--style-skill package-name]
```

**Recommended Structured Format**:
```bash
/workflow:brainstorm:auto-parallel "GOAL: [objective] SCOPE: [boundaries] CONTEXT: [background]" [--count N] [--style-skill package-name]
```

**Parameters**:
- `topic` (required): Topic or challenge description (structured format recommended)
- `--count N` (optional): Number of roles to select (default: 3, max: 9)
- `--style-skill package-name` (optional): Style SKILL package to load for UI design (located at `.claude/skills/style-{package-name}/`)

## 3-Phase Execution

### Phase 1: Interactive Framework Generation

**Command**: `SlashCommand(command="/workflow:brainstorm:artifacts \"{topic}\" --count {N}")`

**What It Does**:
- Topic analysis: Extract challenges, generate task-specific questions
- Role selection: Recommend count+2 roles, user selects via AskUserQuestion
- Role questions: Generate 3-4 questions per role, collect user decisions
- Conflict resolution: Detect and resolve cross-role conflicts
- Guidance generation: Transform Q&A to declarative guidance-specification.md

**Parse Output**:
- **⚠️ Memory Check**: If `selected_roles[]` already in conversation memory from previous load, skip file read
- Extract: `selected_roles[]` from workflow-session.toon (if not in memory)
- Extract: `session_id` from workflow-session.toon (if not in memory)
- Verify: guidance-specification.md exists

**Validation**:
- guidance-specification.md created with confirmed decisions
- workflow-session.toon contains selected_roles[] (metadata only, no content duplication)
- Session directory `.workflow/WFS-{topic}/.brainstorming/` exists

**TodoWrite Update (Phase 1 SlashCommand invoked - tasks attached)**:
```json
[
  {"content": "Parse --count parameter from user input", "status": "completed", "activeForm": "Parsing count parameter"},
  {"content": "Phase 1.1: Topic analysis and question generation (artifacts)", "status": "in_progress", "activeForm": "Analyzing topic"},
  {"content": "Phase 1.2: Role selection and user confirmation (artifacts)", "status": "pending", "activeForm": "Selecting roles"},
  {"content": "Phase 1.3: Role questions and user decisions (artifacts)", "status": "pending", "activeForm": "Collecting role questions"},
  {"content": "Phase 1.4: Conflict detection and resolution (artifacts)", "status": "pending", "activeForm": "Resolving conflicts"},
  {"content": "Phase 1.5: Guidance specification generation (artifacts)", "status": "pending", "activeForm": "Generating guidance"},
  {"content": "Execute parallel role analysis", "status": "pending", "activeForm": "Executing parallel role analysis"},
  {"content": "Execute synthesis integration", "status": "pending", "activeForm": "Executing synthesis integration"}
]
```

**Note**: SlashCommand invocation **attaches** artifacts' 5 internal tasks. Orchestrator **executes** these tasks sequentially.

**Next Action**: Tasks attached → **Execute Phase 1.1-1.5** sequentially

**TodoWrite Update (Phase 1 completed - tasks collapsed)**:
```json
[
  {"content": "Parse --count parameter from user input", "status": "completed", "activeForm": "Parsing count parameter"},
  {"content": "Execute artifacts interactive framework generation", "status": "completed", "activeForm": "Executing artifacts interactive framework"},
  {"content": "Execute parallel role analysis", "status": "pending", "activeForm": "Executing parallel role analysis"},
  {"content": "Execute synthesis integration", "status": "pending", "activeForm": "Executing synthesis integration"}
]
```

**Note**: Phase 1 tasks completed and collapsed to summary.

**After Phase 1**: Auto-continue to Phase 2 (parallel role agent execution)

---

### Phase 2: Parallel Role Analysis Execution

**For Each Selected Role**:
```bash
Task(conceptual-planning-agent): "
[FLOW_CONTROL]

Execute {role-name} analysis for existing topic framework

## Context Loading
ASSIGNED_ROLE: {role-name}
OUTPUT_LOCATION: .workflow/WFS-{session}/.brainstorming/{role}/
TOPIC: {user-provided-topic}

## Flow Control Steps
1. **load_topic_framework**
   - Action: Load structured topic discussion framework
   - Command: Read(.workflow/WFS-{session}/.brainstorming/guidance-specification.md)
   - Output: topic_framework_content

2. **load_role_template**
   - Action: Load {role-name} planning template
   - Command: Read(~/.claude/workflows/cli-templates/planning-roles/{role}.md)
   - Output: role_template_guidelines

3. **load_session_metadata**
   - Action: Load session metadata and original user intent
   - Command: Read(.workflow/WFS-{session}/workflow-session.toon)
   - Output: session_context (contains original user prompt as PRIMARY reference)

4. **load_style_skill** (ONLY for ui-designer role when style_skill_package exists)
   - Action: Load style SKILL package for design system reference
   - Command: Read(.claude/skills/style-{style_skill_package}/SKILL.md) AND Read(.workflow/reference_style/{style_skill_package}/design-tokens.toon)
   - Output: style_skill_content, design_tokens
   - Usage: Apply design tokens in ui-designer analysis and artifacts

## Analysis Requirements
**Primary Reference**: Original user prompt from workflow-session.toon is authoritative
**Framework Source**: Address all discussion points in guidance-specification.md from {role-name} perspective
**Role Focus**: {role-name} domain expertise aligned with user intent
**Structured Approach**: Create analysis.md addressing framework discussion points
**Template Integration**: Apply role template guidelines within framework structure

## Expected Deliverables
1. **analysis.md**: Comprehensive {role-name} analysis addressing all framework discussion points
   - **File Naming**: MUST start with `analysis` prefix (e.g., `analysis.md`, `analysis-1.md`, `analysis-2.md`)
   - **FORBIDDEN**: Never use `recommendations.md` or any filename not starting with `analysis`
   - **Auto-split if large**: If content >800 lines, split to `analysis-1.md`, `analysis-2.md` (max 3 files: analysis.md, analysis-1.md, analysis-2.md)
   - **Content**: Includes both analysis AND recommendations sections within analysis files
2. **Framework Reference**: Include @../guidance-specification.md reference in analysis
3. **User Intent Alignment**: Validate analysis aligns with original user objectives from session_context

## Completion Criteria
- Address each discussion point from guidance-specification.md with {role-name} expertise
- Provide actionable recommendations from {role-name} perspective within analysis files
- All output files MUST start with `analysis` prefix (no recommendations.md or other naming)
- Reference framework document using @ notation for integration
- Update workflow-session.toon with completion status
"
```

**Parallel Execution**:
- Launch N agents simultaneously (one message with multiple Task calls)
- Each agent task **attached** to orchestrator's TodoWrite
- All agents execute concurrently, each attaching their own analysis sub-tasks
- Each agent operates independently reading same guidance-specification.md

**Input**:
- `selected_roles[]` from Phase 1
- `session_id` from Phase 1
- guidance-specification.md path

**Validation**:
- Each role creates `.workflow/WFS-{topic}/.brainstorming/{role}/analysis.md` (primary file)
- If content is large (>800 lines), may split to `analysis-1.md`, `analysis-2.md` (max 3 files total)
- **File naming pattern**: ALL files MUST start with `analysis` prefix (use `analysis*.md` for globbing)
- **FORBIDDEN naming**: No `recommendations.md`, `recommendations-*.md`, or any non-`analysis` prefixed files
- All N role analyses completed

**TodoWrite Update (Phase 2 agents invoked - tasks attached in parallel)**:
```json
[
  {"content": "Parse --count parameter from user input", "status": "completed", "activeForm": "Parsing count parameter"},
  {"content": "Execute artifacts interactive framework generation", "status": "completed", "activeForm": "Executing artifacts interactive framework"},
  {"content": "Phase 2.1: Execute system-architect analysis [conceptual-planning-agent]", "status": "in_progress", "activeForm": "Executing system-architect analysis"},
  {"content": "Phase 2.2: Execute ui-designer analysis [conceptual-planning-agent]", "status": "in_progress", "activeForm": "Executing ui-designer analysis"},
  {"content": "Phase 2.3: Execute product-manager analysis [conceptual-planning-agent]", "status": "in_progress", "activeForm": "Executing product-manager analysis"},
  {"content": "Execute synthesis integration", "status": "pending", "activeForm": "Executing synthesis integration"}
]
```

**Note**: Multiple Task invocations **attach** N role analysis tasks simultaneously. Orchestrator **executes** these tasks in parallel.

**Next Action**: Tasks attached → **Execute Phase 2.1-2.N** concurrently

**TodoWrite Update (Phase 2 completed - tasks collapsed)**:
```json
[
  {"content": "Parse --count parameter from user input", "status": "completed", "activeForm": "Parsing count parameter"},
  {"content": "Execute artifacts interactive framework generation", "status": "completed", "activeForm": "Executing artifacts interactive framework"},
  {"content": "Execute parallel role analysis", "status": "completed", "activeForm": "Executing parallel role analysis"},
  {"content": "Execute synthesis integration", "status": "pending", "activeForm": "Executing synthesis integration"}
]
```

**Note**: Phase 2 parallel tasks completed and collapsed to summary.

**After Phase 2**: Auto-continue to Phase 3 (synthesis)

---

### Phase 3: Synthesis Generation

**Command**: `SlashCommand(command="/workflow:brainstorm:synthesis --session {sessionId}")`

**What It Does**:
- Load original user intent from workflow-session.toon
- Read all role analysis.md files
- Integrate role insights into synthesis-specification.md
- Validate alignment with user's original objectives

**Input**: `sessionId` from Phase 1

**Validation**:
- `.workflow/WFS-{topic}/.brainstorming/synthesis-specification.md` exists
- Synthesis references all role analyses

**TodoWrite Update (Phase 3 SlashCommand invoked - tasks attached)**:
```json
[
  {"content": "Parse --count parameter from user input", "status": "completed", "activeForm": "Parsing count parameter"},
  {"content": "Execute artifacts interactive framework generation", "status": "completed", "activeForm": "Executing artifacts interactive framework"},
  {"content": "Execute parallel role analysis", "status": "completed", "activeForm": "Executing parallel role analysis"},
  {"content": "Phase 3.1: Load role analysis files (synthesis)", "status": "in_progress", "activeForm": "Loading role analyses"},
  {"content": "Phase 3.2: Integrate insights across roles (synthesis)", "status": "pending", "activeForm": "Integrating insights"},
  {"content": "Phase 3.3: Generate synthesis specification (synthesis)", "status": "pending", "activeForm": "Generating synthesis"}
]
```

**Note**: SlashCommand invocation **attaches** synthesis' internal tasks. Orchestrator **executes** these tasks sequentially.

**Next Action**: Tasks attached → **Execute Phase 3.1-3.3** sequentially

**TodoWrite Update (Phase 3 completed - tasks collapsed)**:
```json
[
  {"content": "Parse --count parameter from user input", "status": "completed", "activeForm": "Parsing count parameter"},
  {"content": "Execute artifacts interactive framework generation", "status": "completed", "activeForm": "Executing artifacts interactive framework"},
  {"content": "Execute parallel role analysis", "status": "completed", "activeForm": "Executing parallel role analysis"},
  {"content": "Execute synthesis integration", "status": "completed", "activeForm": "Executing synthesis integration"}
]
```

**Note**: Phase 3 tasks completed and collapsed to summary.

**Return to User**:
```
Brainstorming complete for session: {sessionId}
Roles analyzed: {count}
Synthesis: .workflow/WFS-{topic}/.brainstorming/synthesis-specification.md

✅ Next Steps:
1. /workflow:concept-clarify --session {sessionId}  # Optional refinement
2. /workflow:plan --session {sessionId}  # Generate implementation plan
```

## TodoWrite Pattern

**Core Concept**: Dynamic task attachment and collapse for parallel brainstorming workflow with interactive framework generation and concurrent role analysis.

### Key Principles

1. **Task Attachment** (when SlashCommand/Task invoked):
   - Sub-command's or agent's internal tasks are **attached** to orchestrator's TodoWrite
   - Phase 1: `/workflow:brainstorm:artifacts` attaches 5 internal tasks (Phase 1.1-1.5)
   - Phase 2: Multiple `Task(conceptual-planning-agent)` calls attach N role analysis tasks simultaneously
   - Phase 3: `/workflow:brainstorm:synthesis` attaches 3 internal tasks (Phase 3.1-3.3)
   - First attached task marked as `in_progress`, others as `pending`
   - Orchestrator **executes** these attached tasks (sequentially for Phase 1, 3; in parallel for Phase 2)

2. **Task Collapse** (after sub-tasks complete):
   - Remove detailed sub-tasks from TodoWrite
   - **Collapse** to high-level phase summary
   - Example: Phase 1.1-1.5 collapse to "Execute artifacts interactive framework generation: completed"
   - Phase 2: Multiple role tasks collapse to "Execute parallel role analysis: completed"
   - Phase 3: Synthesis tasks collapse to "Execute synthesis integration: completed"
   - Maintains clean orchestrator-level view

3. **Continuous Execution**:
   - After collapse, automatically proceed to next pending phase
   - No user intervention required between phases
   - TodoWrite dynamically reflects current execution state

**Lifecycle Summary**: Initial pending tasks → Phase 1 invoked (artifacts tasks ATTACHED) → Artifacts sub-tasks executed → Phase 1 completed (tasks COLLAPSED) → Phase 2 invoked (N role tasks ATTACHED in parallel) → Role analyses executed concurrently → Phase 2 completed (tasks COLLAPSED) → Phase 3 invoked (synthesis tasks ATTACHED) → Synthesis sub-tasks executed → Phase 3 completed (tasks COLLAPSED) → Workflow complete.

### Brainstorming Workflow Specific Features

- **Phase 1**: Interactive framework generation with user Q&A (SlashCommand attachment)
- **Phase 2**: Parallel role analysis execution with N concurrent agents (Task agent attachments)
- **Phase 3**: Cross-role synthesis integration (SlashCommand attachment)
- **Dynamic Role Count**: `--count N` parameter determines number of Phase 2 parallel tasks (default: 3, max: 9)
- **Mixed Execution**: Sequential (Phase 1, 3) and Parallel (Phase 2) task execution

**Benefits**:
- Real-time visibility into attached tasks during execution
- Clean orchestrator-level summary after tasks complete
- Clear mental model: SlashCommand/Task = attach tasks, not delegate work
- Parallel execution support for concurrent role analysis
- Dynamic attachment/collapse maintains clarity

**Note**: See individual Phase descriptions (Phase 1, 2, 3) for detailed TodoWrite Update examples with full JSON structures.

## Input Processing

**Count Parameter Parsing**:
```javascript
// Extract --count from user input
IF user_input CONTAINS "--count":
    EXTRACT count_value FROM "--count N" pattern
    IF count_value > 9:
        count_value = 9  // Cap at maximum 9 roles
ELSE:
    count_value = 3  // Default to 3 roles

// Pass to artifacts command
EXECUTE: /workflow:brainstorm:artifacts "{topic}" --count {count_value}
```

**Style-Skill Parameter Parsing**:
```javascript
// Extract --style-skill from user input
IF user_input CONTAINS "--style-skill":
    EXTRACT style_skill_name FROM "--style-skill package-name" pattern

    // Validate SKILL package exists
    skill_path = ".claude/skills/style-{style_skill_name}/SKILL.md"
    IF file_exists(skill_path):
        style_skill_package = style_skill_name
        style_reference_path = ".workflow/reference_style/{style_skill_name}"
        echo("✓ Style SKILL package found: style-{style_skill_name}")
        echo("  Design reference: {style_reference_path}")
    ELSE:
        echo("⚠ WARNING: Style SKILL package not found: {style_skill_name}")
        echo("  Expected location: {skill_path}")
        echo("  Continuing without style reference...")
        style_skill_package = null
ELSE:
    style_skill_package = null
    echo("No style-skill specified, ui-designer will use default workflow")

// Store for Phase 2 ui-designer context
CONTEXT_VARS:
    - style_skill_package: {style_skill_package}
    - style_reference_path: {style_reference_path}
```

**Topic Structuring**:
1. **Already Structured** → Pass directly to artifacts
   ```
   User: "GOAL: Build platform SCOPE: 100 users CONTEXT: Real-time"
   → Pass as-is to artifacts
   ```

2. **Simple Text** → Pass directly (artifacts handles structuring)
   ```
   User: "Build collaboration platform"
   → artifacts will analyze and structure
   ```

## Session Management

**⚡ FIRST ACTION**: Check for `.workflow/.active-*` markers before Phase 1

**Multiple Sessions Support**:
- Different Claude instances can have different active brainstorming sessions
- If multiple active sessions found, prompt user to select
- If single active session found, use it
- If no active session exists, create `WFS-[topic-slug]`

**Session Continuity**:
- MUST use selected active session for all phases
- Each role's context stored in session directory
- Session isolation: Each session maintains independent state

## Output Structure

**Phase 1 Output**:
- `.workflow/WFS-{topic}/.brainstorming/guidance-specification.md` (framework content)
- `.workflow/WFS-{topic}/workflow-session.toon` (metadata: selected_roles[], topic, timestamps, style_skill_package)

**Phase 2 Output**:
- `.workflow/WFS-{topic}/.brainstorming/{role}/analysis.md` (one per role)
- `.superdesign/design_iterations/` (ui-designer artifacts, if --style-skill provided)

**Phase 3 Output**:
- `.workflow/WFS-{topic}/.brainstorming/synthesis-specification.md` (integrated analysis)

**⚠️ Storage Separation**: Guidance content in .md files, metadata in .toon (legacy `.json` read-only, no duplication)
**⚠️ Style References**: When --style-skill provided, workflow-session.toon stores style_skill_package name, ui-designer loads from `.claude/skills/style-{package-name}/`

## Available Roles

- data-architect (数据架构师)
- product-manager (产品经理)
- product-owner (产品负责人)
- scrum-master (敏捷教练)
- subject-matter-expert (领域专家)
- system-architect (系统架构师)
- test-strategist (测试策略师)
- ui-designer (UI 设计师)
- ux-expert (UX 专家)

**Role Selection**: Handled by artifacts command (intelligent recommendation + user selection)

## Error Handling

- **Role selection failure**: artifacts defaults to product-manager with explanation
- **Agent execution failure**: Agent-specific retry with minimal dependencies
- **Template loading issues**: Agent handles graceful degradation
- **Synthesis conflicts**: Synthesis highlights disagreements without resolution

## Reference Information

**File Structure**:
```
.workflow/WFS-[topic]/
├── .active-brainstorming
├── workflow-session.toon              # Session metadata ONLY
└── .brainstorming/
    ├── guidance-specification.md      # Framework (Phase 1)
    ├── {role-1}/
    │   └── analysis.md                # Role analysis (Phase 2)
    ├── {role-2}/
    │   └── analysis.md
    ├── {role-N}/
    │   └── analysis.md
    └── synthesis-specification.md     # Integration (Phase 3)
```

**Template Source**: `~/.claude/workflows/cli-templates/planning-roles/`

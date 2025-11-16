---
name: plan
description: 5-phase planning workflow with action-planning-agent task generation, outputs IMPL_PLAN.md and task TOON files with optional CLI auto-execution
argument-hint: "[--cli-execute] \"text description\"|file.md"
allowed-tools: SlashCommand(*), TodoWrite(*), Read(*), Bash(*)
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Workflow Plan Command (/workflow:plan)

## Coordinator Role

**This command is a pure orchestrator**: Execute 5 slash commands in sequence (including a quality gate), parse their outputs, pass context between them, and ensure complete execution through **automatic continuation**.

**Execution Model - Auto-Continue Workflow with Quality Gate**:

This workflow runs **fully autonomously** once triggered. Phase 3 (conflict resolution) and Phase 4 (task generation) are delegated to specialized agents.


1. **User triggers**: `/workflow:plan "task"`
2. **Phase 1 executes** → Session discovery → Auto-continues
3. **Phase 2 executes** → Context gathering → Auto-continues
4. **Phase 3 executes** (optional, if conflict_risk ≥ medium) → Conflict resolution → Auto-continues
5. **Phase 4 executes** → Task generation (task-generate-agent) → Reports final summary

**Task Attachment Model**:
- SlashCommand invocation **expands workflow** by attaching sub-tasks to current TodoWrite
- When a sub-command is invoked (e.g., `/workflow:tools:context-gather`), its internal tasks are attached to the orchestrator's TodoWrite
- Orchestrator **executes these attached tasks** sequentially
- After completion, attached tasks are **collapsed** back to high-level phase summary
- This is **task expansion**, not external delegation

**Auto-Continue Mechanism**:
- TodoList tracks current phase status and dynamically manages task attachment/collapse
- When each phase finishes executing, automatically execute next pending phase
- All phases run autonomously without user interaction (clarification handled in brainstorm phase)
- Progress updates shown at each phase for visibility
- **⚠️ CONTINUOUS EXECUTION** - Do not stop until all phases complete

## Core Rules

1. **Start Immediately**: First action is TodoWrite initialization, second action is Phase 1 command execution
2. **No Preliminary Analysis**: Do not read files, analyze structure, or gather context before Phase 1
3. **Parse Every Output**: Extract required data from each command/agent output for next phase
4. **Auto-Continue via TodoList**: Check TodoList status to execute next pending phase automatically
5. **Track Progress**: Update TodoWrite dynamically with task attachment/collapse pattern
6. **Task Attachment Model**: SlashCommand invocation **attaches** sub-tasks to current workflow. Orchestrator **executes** these attached tasks itself, then **collapses** them after completion
7. **⚠️ CRITICAL: DO NOT STOP**: Continuous multi-phase workflow. After executing all attached tasks, immediately collapse them and execute next phase

## 5-Phase Execution

### Phase 1: Session Discovery
**Command**: `SlashCommand(command="/workflow:session:start --auto \"[structured-task-description]\"")`

**Task Description Structure**:
```
GOAL: [Clear, concise objective]
SCOPE: [What's included/excluded]
CONTEXT: [Relevant background or constraints]
```

**Example**:
```
GOAL: Build JWT-based authentication system
SCOPE: User registration, login, token validation
CONTEXT: Existing user database schema, REST API endpoints
```

**Parse Output**:
- Extract: `SESSION_ID: WFS-[id]` (store as `sessionId`)

**Validation**:
- Session ID successfully extracted
- Session directory `.workflow/[sessionId]/` exists

**TodoWrite**: Mark phase 1 completed, phase 2 in_progress

**After Phase 1**: Return to user showing Phase 1 results, then auto-continue to Phase 2

---

### Phase 2: Context Gathering
**Command**: `SlashCommand(command="/workflow:tools:context-gather --session [sessionId] \"[structured-task-description]\"")`

**Use Same Structured Description**: Pass the same structured format from Phase 1

**Input**: `sessionId` from Phase 1

**Parse Output**:
- Extract: context-package.toon path (store as `contextPath`)
- Typical pattern: `.workflow/[sessionId]/.process/context-package.toon`

**Validation**:
- Context package path extracted
- File exists and is valid JSON

<!-- TodoWrite: When context-gather invoked, INSERT 3 context-gather tasks, mark first as in_progress -->

**TodoWrite Update (Phase 2 SlashCommand invoked - tasks attached)**:
```json
[
  {"content": "Execute session discovery", "status": "completed", "activeForm": "Executing session discovery"},
  {"content": "Phase 2.1: Analyze codebase structure (context-gather)", "status": "in_progress", "activeForm": "Analyzing codebase structure"},
  {"content": "Phase 2.2: Identify integration points (context-gather)", "status": "pending", "activeForm": "Identifying integration points"},
  {"content": "Phase 2.3: Generate context package (context-gather)", "status": "pending", "activeForm": "Generating context package"},
  {"content": "Execute task generation", "status": "pending", "activeForm": "Executing task generation"}
]
```

**Note**: SlashCommand invocation **attaches** context-gather's 3 tasks. Orchestrator **executes** these tasks sequentially.

<!-- TodoWrite: After Phase 2 tasks complete, REMOVE Phase 2.1-2.3, restore to orchestrator view -->

**TodoWrite Update (Phase 2 completed - tasks collapsed)**:
```json
[
  {"content": "Execute session discovery", "status": "completed", "activeForm": "Executing session discovery"},
  {"content": "Execute context gathering", "status": "completed", "activeForm": "Executing context gathering"},
  {"content": "Execute task generation", "status": "pending", "activeForm": "Executing task generation"}
]
```

**Note**: Phase 2 tasks completed and collapsed to summary.

**After Phase 2**: Return to user showing Phase 2 results, then auto-continue to Phase 3/4 (depending on conflict_risk)

---

### Phase 3: Conflict Resolution (Optional - auto-triggered by conflict risk)

**Trigger**: Only execute when context-package.toon indicates conflict_risk is "medium" or "high"

**Command**: `SlashCommand(command="/workflow:tools:conflict-resolution --session [sessionId] --context [contextPath]")`

**Input**:
- sessionId from Phase 1
- contextPath from Phase 2
- conflict_risk from context-package.toon

**Parse Output**:
- Extract: Execution status (success/skipped/failed)
- Verify: CONFLICT_RESOLUTION.md file path (if executed)

**Validation**:
- File `.workflow/[sessionId]/.process/CONFLICT_RESOLUTION.md` exists (if executed)

**Skip Behavior**:
- If conflict_risk is "none" or "low", skip directly to Phase 3.5
- Display: "No significant conflicts detected, proceeding to clarification"

<!-- TodoWrite: If conflict_risk ≥ medium, INSERT 3 conflict-resolution tasks -->

**TodoWrite Update (Phase 3 SlashCommand invoked - tasks attached, if conflict_risk ≥ medium)**:
```json
[
  {"content": "Execute session discovery", "status": "completed", "activeForm": "Executing session discovery"},
  {"content": "Execute context gathering", "status": "completed", "activeForm": "Executing context gathering"},
  {"content": "Phase 3.1: Detect conflicts with CLI analysis (conflict-resolution)", "status": "in_progress", "activeForm": "Detecting conflicts"},
  {"content": "Phase 3.2: Present conflicts to user (conflict-resolution)", "status": "pending", "activeForm": "Presenting conflicts"},
  {"content": "Phase 3.3: Apply resolution strategies (conflict-resolution)", "status": "pending", "activeForm": "Applying resolution strategies"},
  {"content": "Execute task generation", "status": "pending", "activeForm": "Executing task generation"}
]
```

**Note**: SlashCommand invocation **attaches** conflict-resolution's 3 tasks. Orchestrator **executes** these tasks sequentially.

<!-- TodoWrite: After Phase 3 tasks complete, REMOVE Phase 3.1-3.3, restore to orchestrator view -->

**TodoWrite Update (Phase 3 completed - tasks collapsed)**:
```json
[
  {"content": "Execute session discovery", "status": "completed", "activeForm": "Executing session discovery"},
  {"content": "Execute context gathering", "status": "completed", "activeForm": "Executing context gathering"},
  {"content": "Resolve conflicts and apply fixes", "status": "completed", "activeForm": "Resolving conflicts"},
  {"content": "Execute task generation", "status": "pending", "activeForm": "Executing task generation"}
]
```

**Note**: Phase 3 tasks completed and collapsed to summary.

**After Phase 3**: Return to user showing conflict resolution results (if executed) and selected strategies, then auto-continue to Phase 3.5

**Memory State Check**:
- Evaluate current context window usage and memory state
- If memory usage is high (>110K tokens or approaching context limits):
  - **Command**: `SlashCommand(command="/compact")`
  - This optimizes memory before proceeding to Phase 3.5
- Memory compaction is particularly important after analysis phase which may generate extensive documentation
- Ensures optimal performance and prevents context overflow

---

### Phase 3.5: Pre-Task Generation Validation (Optional Quality Gate)

**Purpose**: Optional quality gate before task generation - primarily handled by brainstorm synthesis phase


**Current Behavior**: Auto-skip to Phase 4 (Task Generation)

**Future Enhancement**: Could add additional validation steps like:
- Cross-reference checks between conflict resolution and brainstorm analyses
- Final sanity checks before task generation
- User confirmation prompt for proceeding

**TodoWrite**: Mark phase 3.5 completed (auto-skip), phase 4 in_progress

**After Phase 3.5**: Auto-continue to Phase 4 immediately

---

### Phase 4: Task Generation

**Relationship with Brainstorm Phase**:
- If brainstorm role analyses exist ([role]/analysis.md files), Phase 3 analysis incorporates them as input
- **User's original intent is ALWAYS primary**: New or refined user goals override brainstorm recommendations
- **Role analysis.md files define "WHAT"**: Requirements, design specs, role-specific insights
- **IMPL_PLAN.md defines "HOW"**: Executable task breakdown, dependencies, implementation sequence
- Task generation translates high-level role analyses into concrete, actionable work items
- **Intent priority**: Current user prompt > role analysis.md files > guidance-specification.md

**Command**:
```bash
# Default (agent mode)
SlashCommand(command="/workflow:tools:task-generate-agent --session [sessionId]")

# With CLI execution
SlashCommand(command="/workflow:tools:task-generate-agent --session [sessionId] --cli-execute")
```

**Flag**:
- `--cli-execute`: Generate tasks with Codex execution commands

**Input**: `sessionId` from Phase 1

**Validation**:
- `.workflow/[sessionId]/IMPL_PLAN.md` exists
- `.workflow/[sessionId]/.task/IMPL-*.toon` exists (at least one)
- `.workflow/[sessionId]/TODO_LIST.md` exists

<!-- TodoWrite: When task-generate-agent invoked, ATTACH 1 agent task -->

**TodoWrite Update (Phase 4 SlashCommand invoked - agent task attached)**:
```json
[
  {"content": "Execute session discovery", "status": "completed", "activeForm": "Executing session discovery"},
  {"content": "Execute context gathering", "status": "completed", "activeForm": "Executing context gathering"},
  {"content": "Execute task-generate-agent", "status": "in_progress", "activeForm": "Executing task-generate-agent"}
]
```

**Note**: Single agent task attached. Agent autonomously completes discovery, planning, and output generation internally.

<!-- TodoWrite: After agent completes, mark task as completed -->

**TodoWrite Update (Phase 4 completed)**:
```json
[
  {"content": "Execute session discovery", "status": "completed", "activeForm": "Executing session discovery"},
  {"content": "Execute context gathering", "status": "completed", "activeForm": "Executing context gathering"},
  {"content": "Execute task-generate-agent", "status": "completed", "activeForm": "Executing task-generate-agent"}
]
```

**Note**: Agent task completed. No collapse needed (single task).

**Return to User**:
```
Planning complete for session: [sessionId]
Tasks generated: [count]
Plan: .workflow/[sessionId]/IMPL_PLAN.md

Recommended Next Steps:
1. /workflow:action-plan-verify --session [sessionId]  # Verify plan quality before execution
2. /workflow:status  # Review task breakdown
3. /workflow:execute  # Start implementation (after verification)

Quality Gate: Consider running /workflow:action-plan-verify to catch issues early
```

## TodoWrite Pattern

**Core Concept**: Dynamic task attachment and collapse for real-time visibility into workflow execution.

### Key Principles

1. **Task Attachment** (when SlashCommand invoked):
   - Sub-command's internal tasks are **attached** to orchestrator's TodoWrite
   - **Phase 2, 3**: Multiple sub-tasks attached (e.g., Phase 2.1, 2.2, 2.3)
   - **Phase 4**: Single agent task attached (e.g., "Execute task-generate-agent")
   - First attached task marked as `in_progress`, others as `pending`
   - Orchestrator **executes** these attached tasks sequentially

2. **Task Collapse** (after sub-tasks complete):
   - **Applies to Phase 2, 3**: Remove detailed sub-tasks from TodoWrite
   - **Collapse** to high-level phase summary
   - Example: Phase 2.1-2.3 collapse to "Execute context gathering: completed"
   - **Phase 4**: No collapse needed (single task, just mark completed)
   - Maintains clean orchestrator-level view

3. **Continuous Execution**:
   - After completion, automatically proceed to next pending phase
   - No user intervention required between phases
   - TodoWrite dynamically reflects current execution state

**Lifecycle Summary**: Initial pending tasks → Phase invoked (tasks ATTACHED) → Sub-tasks executed sequentially → Phase completed (tasks COLLAPSED to summary for Phase 2/3, or marked completed for Phase 4) → Next phase begins → Repeat until all phases complete.

### Benefits

- ✓ Real-time visibility into sub-task execution
- ✓ Clear mental model: SlashCommand = attach → execute → collapse (Phase 2/3) or complete (Phase 4)
- ✓ Clean summary after completion
- ✓ Easy to track workflow progress

**Note**: See individual Phase descriptions for detailed TodoWrite Update examples:
- **Phase 2, 3**: Multiple sub-tasks with attach/collapse pattern
- **Phase 4**: Single agent task (no collapse needed)

## Input Processing

**Convert User Input to Structured Format**:

1. **Simple Text** → Structure it:
   ```
   User: "Build authentication system"

   Structured:
   GOAL: Build authentication system
   SCOPE: Core authentication features
   CONTEXT: New implementation
   ```

2. **Detailed Text** → Extract components:
   ```
   User: "Add JWT authentication with email/password login and token refresh"

   Structured:
   GOAL: Implement JWT-based authentication
   SCOPE: Email/password login, token generation, token refresh endpoints
   CONTEXT: JWT token-based security, refresh token rotation
   ```

3. **File Reference** (e.g., `requirements.md`) → Read and structure:
   - Read file content
   - Extract goal, scope, requirements
   - Format into structured description

## Data Flow

```
User Input (task description)
    ↓
[Convert to Structured Format]
    ↓ Structured Description:
    ↓   GOAL: [objective]
    ↓   SCOPE: [boundaries]
    ↓   CONTEXT: [background]
    ↓
Phase 1: session:start --auto "structured-description"
    ↓ Output: sessionId
    ↓ Session Memory: Previous tasks, context, artifacts
    ↓
Phase 2: context-gather --session sessionId "structured-description"
    ↓ Input: sessionId + session memory + structured description
    ↓ Output: contextPath (context-package.toon) + conflict_risk
    ↓
Phase 3: conflict-resolution [AUTO-TRIGGERED if conflict_risk ≥ medium]
    ↓ Input: sessionId + contextPath + conflict_risk
    ↓ CLI-powered conflict detection (JSON output)
    ↓ AskUserQuestion: Present conflicts + resolution strategies
    ↓ User selects strategies (or skip)
    ↓ Apply modifications via Edit tool:
    ↓   - Update guidance-specification.md
    ↓   - Update role analyses (*.md)
    ↓   - Mark context-package.toon as "resolved"
    ↓ Output: Modified brainstorm artifacts (NO report file)
    ↓ Skip if conflict_risk is none/low → proceed directly to Phase 4
    ↓
Phase 4: task-generate-agent --session sessionId [--cli-execute]
    ↓ Input: sessionId + resolved brainstorm artifacts + session memory
    ↓ Output: IMPL_PLAN.md, task TOON files, TODO_LIST.md
    ↓
Return summary to user
```

**Session Memory Flow**: Each phase receives session ID, which provides access to:
- Previous task summaries
- Existing context and analysis
- Brainstorming artifacts (potentially modified by Phase 3)
- Session-specific configuration

**Structured Description Benefits**:
- **Clarity**: Clear separation of goal, scope, and context
- **Consistency**: Same format across all phases
- **Traceability**: Easy to track what was requested
- **Precision**: Better context gathering and analysis

## Execution Flow Diagram

```
User triggers: /workflow:plan "Build authentication system"
  ↓
[TodoWrite Init] 3 orchestrator-level tasks
  ↓
Phase 1: Session Discovery
  → sessionId extracted
  ↓
Phase 2: Context Gathering (SlashCommand invoked)
  → ATTACH 3 tasks: ← ATTACHED
    - Phase 2.1: Analyze codebase structure
    - Phase 2.2: Identify integration points
    - Phase 2.3: Generate context package
  → Execute Phase 2.1-2.3
  → COLLAPSE tasks ← COLLAPSED
  → contextPath + conflict_risk extracted
  ↓
Conditional Branch: Check conflict_risk
  ├─ IF conflict_risk ≥ medium:
  │   Phase 3: Conflict Resolution (SlashCommand invoked)
  │     → ATTACH 3 tasks: ← ATTACHED
  │       - Phase 3.1: Detect conflicts with CLI analysis
  │       - Phase 3.2: Present conflicts to user
  │       - Phase 3.3: Apply resolution strategies
  │     → Execute Phase 3.1-3.3
  │     → COLLAPSE tasks ← COLLAPSED
  │
  └─ ELSE: Skip Phase 3, proceed to Phase 4
  ↓
Phase 4: Task Generation (SlashCommand invoked)
  → ATTACH 1 agent task: ← ATTACHED
    - Execute task-generate-agent
  → Agent autonomously completes internally:
    (discovery → planning → output)
  → Outputs: IMPL_PLAN.md, IMPL-*.toon, TODO_LIST.md
  ↓
Return summary to user
```

**Key Points**:
- **← ATTACHED**: Tasks attached to TodoWrite when SlashCommand invoked
  - Phase 2, 3: Multiple sub-tasks
  - Phase 4: Single agent task
- **← COLLAPSED**: Sub-tasks collapsed to summary after completion (Phase 2, 3 only)
- **Phase 4**: Single agent task, no collapse (just mark completed)
- **Conditional Branch**: Phase 3 only executes if conflict_risk ≥ medium
- **Continuous Flow**: No user intervention between phases

## Error Handling

- **Parsing Failure**: If output parsing fails, retry command once, then report error
- **Validation Failure**: If validation fails, report which file/data is missing
- **Command Failure**: Keep phase `in_progress`, report error to user, do not proceed to next phase

## Coordinator Checklist

- **Pre-Phase**: Convert user input to structured format (GOAL/SCOPE/CONTEXT)
- Initialize TodoWrite before any command (Phase 3 added dynamically after Phase 2)
- Execute Phase 1 immediately with structured description
- Parse session ID from Phase 1 output, store in memory
- Pass session ID and structured description to Phase 2 command
- Parse context path from Phase 2 output, store in memory
- **Extract conflict_risk from context-package.toon**: Determine Phase 3 execution
- **If conflict_risk ≥ medium**: Launch Phase 3 conflict-resolution with sessionId and contextPath
- Wait for Phase 3 to finish executing (if executed), verify CONFLICT_RESOLUTION.md created
- **If conflict_risk is none/low**: Skip Phase 3, proceed directly to Phase 4
- **Build Phase 4 command**:
  - Base command: `/workflow:tools:task-generate-agent --session [sessionId]`
  - Add `--cli-execute` if flag present
- Pass session ID to Phase 4 command
- Verify all Phase 4 outputs
- Update TodoWrite after each phase (dynamically adjust for Phase 3 presence)
- After each phase, automatically continue to next phase based on TodoList status

## Structure Template Reference

**Minimal Structure**:
```
GOAL: [What to achieve]
SCOPE: [What's included]
CONTEXT: [Relevant info]
```

**Detailed Structure** (optional, when more context available):
```
GOAL: [Primary objective]
SCOPE: [Included features/components]
CONTEXT: [Existing system, constraints, dependencies]
REQUIREMENTS: [Specific technical requirements]
CONSTRAINTS: [Limitations or boundaries]
```

**Usage in Commands**:
```bash
# Phase 1
/workflow:session:start --auto "GOAL: Build authentication\nSCOPE: JWT, login, registration\nCONTEXT: REST API"

# Phase 2
/workflow:tools:context-gather --session WFS-123 "GOAL: Build authentication\nSCOPE: JWT, login, registration\nCONTEXT: REST API"
```

## Related Commands

**Prerequisite Commands**:
- `/workflow:brainstorm:artifacts` - Optional: Generate role-based analyses before planning (if complex requirements need multiple perspectives)
- `/workflow:brainstorm:synthesis` - Optional: Refine brainstorm analyses with clarifications

**Called by This Command** (5 phases):
- `/workflow:session:start` - Phase 1: Create or discover workflow session
- `/workflow:tools:context-gather` - Phase 2: Gather project context and analyze codebase
- `/workflow:tools:conflict-resolution` - Phase 3: Detect and resolve conflicts (auto-triggered if conflict_risk ≥ medium)
- `/compact` - Phase 3: Memory optimization (if context approaching limits)
- `/workflow:tools:task-generate-agent` - Phase 4: Generate task TOON files with agent-driven approach

**Follow-up Commands**:
- `/workflow:action-plan-verify` - Recommended: Verify plan quality and catch issues before execution
- `/workflow:status` - Review task breakdown and current progress
- `/workflow:execute` - Begin implementation of generated tasks

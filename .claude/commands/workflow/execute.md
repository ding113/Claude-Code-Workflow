---
name: execute
description: Coordinate agent execution for workflow tasks with automatic session discovery, parallel task processing, and status tracking
argument-hint: "[--resume-session=\"session-id\"]"
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Workflow Execute Command

## Overview
Orchestrates autonomous workflow execution through systematic task discovery, agent coordination, and progress tracking. **Executes entire workflow without user interruption** (except initial session selection if multiple active sessions exist), providing complete context to agents and ensuring proper flow control execution with comprehensive TodoWrite tracking.

**Resume Mode**: When called with `--resume-session` flag, skips discovery phase and directly enters TodoWrite generation and agent execution for the specified session.

## Performance Optimization Strategy

**Lazy Loading**: Task TOON files read **on-demand** during execution, not upfront. TODO_LIST.md + IMPL_PLAN.md provide metadata for planning.

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Initial Load** | All task TOON files (~2,300 lines) | TODO_LIST.md only (~650 lines) | **72% reduction** |
| **Startup Time** | Seconds | Milliseconds | **~90% faster** |
| **Memory** | All tasks | 1-2 tasks | **90% less** |
| **Scalability** | 10-20 tasks | 100+ tasks | **5-10x** |

**Loading Strategy**:
- **TODO_LIST.md**: Read in Phase 2 (task metadata, status, dependencies)
- **IMPL_PLAN.md**: Read existence in Phase 2, parse execution strategy when needed
- **Task TOON files**: Complete lazy loading (read only during execution)

## Core Rules
**Complete entire workflow autonomously without user interruption, using TodoWrite for comprehensive progress tracking.**
**Execute all discovered pending tasks until workflow completion or blocking dependency.**
**Auto-complete session when all tasks finished: Call `/workflow:session:complete` upon workflow completion.**

## Core Responsibilities
- **Session Discovery**: Identify and select active workflow sessions
- **Execution Strategy Parsing**: Extract execution model from IMPL_PLAN.md
- **TodoWrite Progress Tracking**: Maintain real-time execution status throughout entire workflow
- **Agent Orchestration**: Coordinate specialized agents with complete context
- **Status Synchronization**: Update task TOON files and workflow state
- **Autonomous Completion**: Continue execution until all tasks complete or reach blocking state
- **Session Auto-Complete**: Call `/workflow:session:complete` when all workflow tasks finished

## Execution Philosophy
- **IMPL_PLAN-driven**: Follow execution strategy from IMPL_PLAN.md Section 4
- **Discovery-first**: Auto-discover existing plans and tasks
- **Status-aware**: Execute only ready tasks with resolved dependencies
- **Context-rich**: Provide complete task TOON and accumulated context to agents
- **Progress tracking**: Continuous TodoWrite updates throughout entire workflow execution
- **Autonomous completion**: Execute all tasks without user interruption until workflow complete

## Execution Lifecycle

### Phase 1: Discovery
**Applies to**: Normal mode only (skipped in resume mode)

**Process**:
1. **Check Active Sessions**: Find `.workflow/.active-*` markers
2. **Select Session**: If multiple found, prompt user selection
3. **Load Session Metadata**: Read `workflow-session.toon` ONLY (minimal context)
4. **DO NOT read task TOON files yet** - defer until execution phase

**Resume Mode**: This phase is completely skipped when `--resume-session="session-id"` flag is provided.

### Phase 2: Planning Document Analysis
**Applies to**: Normal mode only (skipped in resume mode)

**Optimized to avoid reading all task TOON files upfront**

**Process**:
1. **Read IMPL_PLAN.md**: Check existence, understand overall strategy
2. **Read TODO_LIST.md**: Get current task statuses and execution progress
3. **Extract Task Metadata**: Parse task IDs, titles, and dependency relationships from TODO_LIST.md
4. **Build Execution Queue**: Determine ready tasks based on TODO_LIST.md status and dependencies

**Key Optimization**: Use IMPL_PLAN.md (existence check only) and TODO_LIST.md as primary sources instead of reading all task TOON files

**Resume Mode**: This phase is skipped when `--resume-session` flag is provided (session already known).

### Phase 3: TodoWrite Generation
**Applies to**: Both normal and resume modes (resume mode entry point)

**Process**:
1. **Create TodoWrite List**: Generate task list from TODO_LIST.md (not from task TOON files)
   - Parse TODO_LIST.md to extract all tasks with current statuses
   - Identify first pending task with met dependencies
   - Generate comprehensive TodoWrite covering entire workflow
2. **Mark Initial Status**: Set first ready task(s) as `in_progress` in TodoWrite
   - **Sequential execution**: Mark ONE task as `in_progress`
   - **Parallel batch**: Mark ALL tasks in current batch as `in_progress`
3. **Prepare Session Context**: Inject workflow paths for agent use (using provided session-id)
4. **Validate Prerequisites**: Ensure IMPL_PLAN.md and TODO_LIST.md exist and are valid

**Resume Mode Behavior**:
- Load existing TODO_LIST.md directly from `.workflow/{session-id}/`
- Extract current progress from TODO_LIST.md
- Generate TodoWrite from TODO_LIST.md state
- Proceed immediately to agent execution (Phase 4)

### Phase 4: Execution Strategy Selection & Task Execution
**Applies to**: Both normal and resume modes

**Step 4A: Parse Execution Strategy from IMPL_PLAN.md**

Read IMPL_PLAN.md Section 4 to extract:
- **Execution Model**: Sequential | Parallel | Phased | TDD Cycles
- **Parallelization Opportunities**: Which tasks can run in parallel
- **Serialization Requirements**: Which tasks must run sequentially
- **Critical Path**: Priority execution order

If IMPL_PLAN.md lacks execution strategy, use intelligent fallback (analyze task structure).

**Step 4B: Execute Tasks with Lazy Loading**

**Key Optimization**: Read task TOON **only when needed** for execution

**Execution Loop Pattern**:
```
while (TODO_LIST.md has pending tasks) {
  next_task_id = getTodoWriteInProgressTask()
  task_json = Read(.workflow/{session}/.task/{next_task_id}.toon)  // Lazy load
  executeTaskWithAgent(task_json)
  updateTodoListMarkCompleted(next_task_id)
  advanceTodoWriteToNextTask()
}
```

**Execution Process per Task**:
1. **Identify Next Task**: From TodoWrite, get the next `in_progress` task ID
2. **Load Task TOON on Demand**: Read `.task/{task-id}.toon` for current task ONLY
3. **Validate Task Structure**: Ensure all 5 required fields exist (id, title, status, meta, context, flow_control)
4. **Launch Agent**: Invoke specialized agent with complete context including flow control steps
5. **Monitor Progress**: Track agent execution and handle errors without user interruption
6. **Collect Results**: Gather implementation results and outputs
7. **Update TODO_LIST.md**: Mark current task as completed in TODO_LIST.md
8. **Continue Workflow**: Identify next pending task from TODO_LIST.md and repeat

**Benefits**:
- Reduces initial context loading by ~90%
- Only reads task TOON when actually executing
- Scales better for workflows with many tasks
- Faster startup time for workflow execution

### Phase 5: Completion
**Applies to**: Both normal and resume modes

**Process**:
1. **Update Task Status**: Mark completed tasks in JSON files
2. **Generate Summary**: Create task summary in `.summaries/`
3. **Update TodoWrite**: Mark current task complete, advance to next
4. **Synchronize State**: Update session state and workflow status
5. **Check Workflow Complete**: Verify all tasks are completed
6. **Auto-Complete Session**: Call `/workflow:session:complete` when all tasks finished

## Execution Strategy (IMPL_PLAN-Driven)

### Strategy Priority

**IMPL_PLAN-Driven Execution (Recommended)**:
1. **Read IMPL_PLAN.md execution strategy** (Section 4: Implementation Strategy)
2. **Follow explicit guidance**:
   - Execution Model (Sequential/Parallel/Phased/TDD)
   - Parallelization Opportunities (which tasks can run in parallel)
   - Serialization Requirements (which tasks must run sequentially)
   - Critical Path (priority execution order)
3. **Use TODO_LIST.md for status tracking** only
4. **IMPL_PLAN decides "HOW"**, execute.md implements it

**Intelligent Fallback (When IMPL_PLAN lacks execution details)**:
1. **Analyze task structure**:
   - Check `meta.execution_group` in task TOON files
   - Analyze `depends_on` relationships
   - Understand task complexity and risk
2. **Apply smart defaults**:
   - No dependencies + same execution_group → Parallel
   - Has dependencies → Sequential (wait for deps)
   - Critical/high-risk tasks → Sequential
3. **Conservative approach**: When uncertain, prefer sequential execution

### Execution Models

#### 1. Sequential Execution
**When**: IMPL_PLAN specifies "Sequential" OR no clear parallelization guidance
**Pattern**: Execute tasks one by one in TODO_LIST order
**TodoWrite**: ONE task marked as `in_progress` at a time

#### 2. Parallel Execution
**When**: IMPL_PLAN specifies "Parallel" with clear parallelization opportunities
**Pattern**: Execute independent task groups concurrently
**TodoWrite**: MULTIPLE tasks (in same batch) marked as `in_progress` simultaneously

#### 3. Phased Execution
**When**: IMPL_PLAN specifies "Phased" with phase breakdown
**Pattern**: Execute tasks in phases, respect phase boundaries
**TodoWrite**: Within each phase, follow Sequential or Parallel rules

#### 4. Intelligent Fallback
**When**: IMPL_PLAN lacks execution strategy details
**Pattern**: Analyze task structure and apply smart defaults
**TodoWrite**: Follow Sequential or Parallel rules based on analysis

### Task Status Logic
```
pending + dependencies_met → executable
completed → skip
blocked → skip until dependencies clear
```

## TodoWrite Coordination

### TodoWrite Rules (Unified)

**Rule 1: Initial Creation**
- **Normal Mode**: Generate TodoWrite from discovered pending tasks for entire workflow
- **Resume Mode**: Generate from existing session state and current progress

**Rule 2: In-Progress Task Count (Execution-Model-Dependent)**
- **Sequential execution**: Mark ONLY ONE task as `in_progress` at a time
- **Parallel batch execution**: Mark ALL tasks in current batch as `in_progress` simultaneously
- **Execution group indicator**: Show `[execution_group: group-id]` for parallel tasks

**Rule 3: Status Updates**
- **Immediate Updates**: Update status after each task/batch completion without user interruption
- **Status Synchronization**: Sync with JSON task files after updates
- **Continuous Tracking**: Maintain TodoWrite throughout entire workflow execution until completion

**Rule 4: Workflow Completion Check**
- When all tasks marked `completed`, auto-call `/workflow:session:complete`

### TodoWrite Tool Usage

**Example 1: Sequential Execution**
```javascript
TodoWrite({
  todos: [
    {
      content: "Execute IMPL-1.1: Design auth schema [code-developer] [FLOW_CONTROL]",
      status: "in_progress",  // ONE task in progress
      activeForm: "Executing IMPL-1.1: Design auth schema"
    },
    {
      content: "Execute IMPL-1.2: Implement auth logic [code-developer] [FLOW_CONTROL]",
      status: "pending",
      activeForm: "Executing IMPL-1.2: Implement auth logic"
    }
  ]
});
```

**Example 2: Parallel Batch Execution**
```javascript
TodoWrite({
  todos: [
    {
      content: "Execute IMPL-1.1: Build Auth API [code-developer] [execution_group: parallel-auth-api]",
      status: "in_progress",  // Batch task 1
      activeForm: "Executing IMPL-1.1: Build Auth API"
    },
    {
      content: "Execute IMPL-1.2: Build User UI [code-developer] [execution_group: parallel-ui-comp]",
      status: "in_progress",  // Batch task 2 (running concurrently)
      activeForm: "Executing IMPL-1.2: Build User UI"
    },
    {
      content: "Execute IMPL-1.3: Setup Database [code-developer] [execution_group: parallel-db-schema]",
      status: "in_progress",  // Batch task 3 (running concurrently)
      activeForm: "Executing IMPL-1.3: Setup Database"
    },
    {
      content: "Execute IMPL-2.1: Integration Tests [test-fix-agent] [depends_on: IMPL-1.1, IMPL-1.2, IMPL-1.3]",
      status: "pending",  // Next batch (waits for current batch completion)
      activeForm: "Executing IMPL-2.1: Integration Tests"
    }
  ]
});
```

### TODO_LIST.md Update Timing
**Single source of truth for task status** - enables lazy loading by providing task metadata without reading JSONs

- **Before Agent Launch**: Mark task as `in_progress`
- **After Task Complete**: Mark as `completed`, advance to next
- **On Error**: Keep as `in_progress`, add error note
- **Workflow Complete**: Call `/workflow:session:complete`

## Agent Context Management

### Context Sources (Priority Order)
1. **Complete Task TOON**: Full task definition including all fields and artifacts
2. **Artifacts Context**: Brainstorming outputs and role analyses from task.context.artifacts
3. **Flow Control Context**: Accumulated outputs from pre_analysis steps (including artifact loading)
4. **Dependency Summaries**: Previous task completion summaries
5. **Session Context**: Workflow paths and session metadata
6. **Inherited Context**: Parent task context and shared variables

### Context Assembly Process
```
1. Load Task TOON → Base context (including artifacts array)
2. Load Artifacts → Synthesis specifications and brainstorming outputs
3. Execute Flow Control → Accumulated context (with artifact loading steps)
4. Load Dependencies → Dependency context
5. Prepare Session Paths → Session context
6. Combine All → Complete agent context with artifact integration
```

### Agent Context Package Structure
```json
{
  "task": { /* Complete task TOON with artifacts array */ },
  "artifacts": {
    "synthesis_specification": { "path": "{{from context-package.toon → brainstorm_artifacts.synthesis_output.path}}", "priority": "highest" },
    "guidance_specification": { "path": "{{from context-package.toon → brainstorm_artifacts.guidance_specification.path}}", "priority": "medium" },
    "role_analyses": [ /* From context-package.toon → brainstorm_artifacts.role_analyses[] */ ],
    "conflict_resolution": { "path": "{{from context-package.toon → brainstorm_artifacts.conflict_resolution.path}}", "conditional": true }
  },
  "flow_context": {
    "step_outputs": {
      "synthesis_specification": "...",
      "individual_artifacts": "...",
      "pattern_analysis": "...",
      "dependency_context": "..."
    }
  },
  "session": {
    "workflow_dir": ".workflow/WFS-session/",
    "context_package_path": ".workflow/WFS-session/.process/context-package.toon",
    "todo_list_path": ".workflow/WFS-session/TODO_LIST.md",
    "summaries_dir": ".workflow/WFS-session/.summaries/",
    "task_json_path": ".workflow/WFS-session/.task/IMPL-1.1.toon"
  },
  "dependencies": [ /* Task summaries from depends_on */ ],
  "inherited": { /* Parent task context */ }
}
```

### Context Validation Rules
- **Task TOON Complete**: All 5 fields present and valid, including artifacts array in context
- **Artifacts Available**: All artifacts loaded from context-package.toon
- **Flow Control Ready**: All pre_analysis steps completed including artifact loading steps
- **Dependencies Loaded**: All depends_on summaries available
- **Session Paths Valid**: All workflow paths exist and accessible (verified via context-package.toon)
- **Agent Assignment**: Valid agent type specified in meta.agent

## Agent Execution Pattern

### Flow Control Execution
**[FLOW_CONTROL]** marker indicates task TOON contains `flow_control.pre_analysis` steps for context preparation.

**Orchestrator Responsibility**:
- Pass complete task TOON to agent (including `flow_control` block)
- Provide session paths for artifact access
- Monitor agent completion

**Agent Responsibility**:
- Parse `flow_control.pre_analysis` array from JSON
- Execute steps sequentially with variable substitution
- Accumulate context from artifacts and dependencies
- Follow error handling per `step.on_error`
- Complete implementation using accumulated context

**Orchestrator does NOT execute flow control steps - Agent interprets and executes them from JSON.**

### Agent Prompt Template
```bash
Task(subagent_type="{meta.agent}",
     prompt="**EXECUTE TASK FROM JSON**

     ## Task TOON Location
     {session.task_json_path}

     ## Instructions
     1. **Load Complete Task TOON**: Read and validate all fields (id, title, status, meta, context, flow_control)
     2. **Execute Flow Control**: If `flow_control.pre_analysis` exists, execute steps sequentially:
        - Load artifacts (role analysis documents, role analyses) using commands in each step
        - Accumulate context from step outputs using variable substitution [variable_name]
        - Handle errors per step.on_error (skip_optional | fail | retry_once)
     3. **Implement Solution**: Follow `flow_control.implementation_approach` using accumulated context
     4. **Complete Task**:
        - Update task status: `jq '.status = \"completed\"' {session.task_json_path} > temp.toon && mv temp.toon {session.task_json_path}`
        - Update TODO_LIST.md: Mark task as [x] completed in {session.todo_list_path}
        - Generate summary: {session.summaries_dir}/{task.id}-summary.md
        - Check workflow completion and call `/workflow:session:complete` if all tasks done

     ## Context Sources (All from JSON)
     - Requirements: `context.requirements`
     - Focus Paths: `context.focus_paths`
     - Acceptance: `context.acceptance`
     - Artifacts: `context.artifacts` (synthesis specs, brainstorming outputs)
     - Dependencies: `context.depends_on`
     - Target Files: `flow_control.target_files`

     ## Session Paths
     - Workflow Dir: {session.workflow_dir}
     - TODO List: {session.todo_list_path}
     - Summaries: {session.summaries_dir}
     - Flow Context: {flow_context.step_outputs}

     **Complete JSON structure is authoritative - load and follow it exactly.**"),
     description="Execute task: {task.id}")
```

### Agent JSON Loading Specification
**MANDATORY AGENT PROTOCOL**: All agents must follow this exact loading sequence:

1. **JSON Loading**: First action must be `cat {session.task_json_path}`
2. **Field Validation**: Verify all 5 required fields exist: `id`, `title`, `status`, `meta`, `context`, `flow_control`
3. **Structure Parsing**: Parse nested fields correctly:
   - `meta.type` and `meta.agent` (NOT flat `task_type`)
   - `context.requirements`, `context.focus_paths`, `context.acceptance`
   - `context.depends_on`, `context.inherited`
   - `flow_control.pre_analysis` array, `flow_control.target_files`
4. **Flow Control Execution**: If `flow_control.pre_analysis` exists, execute steps sequentially
5. **Status Management**: Update JSON status upon completion

**JSON Field Reference**:
```json
{
  "id": "IMPL-1.2",
  "title": "Task title",
  "status": "pending|active|completed|blocked",
  "meta": {
    "type": "feature|bugfix|refactor|test-gen|test-fix|docs",
    "agent": "@code-developer|@test-fix-agent|@universal-executor"
  },
  "context": {
    "requirements": ["req1", "req2"],
    "focus_paths": ["src/path1", "src/path2"],
    "acceptance": ["criteria1", "criteria2"],
    "depends_on": ["IMPL-1.1"],
    "inherited": { "from": "parent", "context": ["info"] },
    "artifacts": [
      {
        "type": "synthesis_specification",
        "source": "context-package.toon → brainstorm_artifacts.synthesis_output",
        "path": "{{loaded dynamically from context-package.toon}}",
        "priority": "highest",
        "contains": "complete_integrated_specification"
      },
      {
        "type": "individual_role_analysis",
        "source": "context-package.toon → brainstorm_artifacts.role_analyses[]",
        "path": "{{loaded dynamically from context-package.toon}}",
        "note": "Supports analysis*.md pattern (analysis.md, analysis-01.md, analysis-api.md, etc.)",
        "priority": "low",
        "contains": "role_specific_analysis_fallback"
      }
    ]
  },
  "flow_control": {
    "pre_analysis": [
      {
        "step": "load_synthesis_specification",
        "action": "Load synthesis specification from context-package.toon",
        "commands": [
          "Read(.workflow/WFS-[session]/.process/context-package.toon)",
          "Extract(brainstorm_artifacts.synthesis_output.path)",
          "Read(extracted path)"
        ],
        "output_to": "synthesis_specification",
        "on_error": "skip_optional"
      },
      {
        "step": "step_name",
        "command": "bash_command",
        "output_to": "variable",
        "on_error": "skip_optional|fail|retry_once"
      }
    ],
    "implementation_approach": [
      {
        "step": 1,
        "title": "Implement task following role analyses",
        "description": "Implement '[title]' following role analyses. PRIORITY: Use role analysis documents as primary requirement source. When implementation needs technical details (e.g., API schemas, caching configs, design tokens), refer to artifacts[] for detailed specifications from original role analyses.",
        "modification_points": [
          "Apply consolidated requirements from role analysis documents",
          "Follow technical guidelines from synthesis",
          "Consult artifacts for implementation details when needed",
          "Integrate with existing patterns"
        ],
        "logic_flow": [
          "Load role analyses",
          "Parse architecture and requirements",
          "Implement following specification",
          "Consult artifacts for technical details when needed",
          "Validate against acceptance criteria"
        ],
        "depends_on": [],
        "output": "implementation"
      }
    ],
    "target_files": ["file:function:lines", "path/to/NewFile.ts"]
  }
}
```

### Execution Flow
1. **Load Task TOON**: Agent reads and validates complete JSON structure
2. **Execute Flow Control**: Agent runs pre_analysis steps if present
3. **Prepare Implementation**: Agent uses implementation_approach from JSON
4. **Launch Implementation**: Agent follows focus_paths and target_files
5. **Update Status**: Agent marks JSON status as completed
6. **Generate Summary**: Agent creates completion summary

### Agent Assignment Rules
```
meta.agent specified → Use specified agent
meta.agent missing → Infer from meta.type:
  - "feature" → @code-developer
  - "test-gen" → @code-developer
  - "test-fix" → @test-fix-agent
  - "review" → @universal-executor
  - "docs" → @doc-generator
```

## Workflow File Structure Reference
```
.workflow/WFS-[topic-slug]/
├── workflow-session.toon     # Session state and metadata
├── IMPL_PLAN.md             # Planning document and requirements
├── TODO_LIST.md             # Progress tracking (auto-updated)
├── .task/                   # Task definitions (JSON only)
│   ├── IMPL-1.toon          # Main task definitions
│   └── IMPL-1.1.toon        # Subtask definitions
├── .summaries/              # Task completion summaries
│   ├── IMPL-1-summary.md    # Task completion details
│   └── IMPL-1.1-summary.md  # Subtask completion details
└── .process/                # Planning artifacts
    ├── context-package.toon # Smart context package
    └── ANALYSIS_RESULTS.md  # Planning analysis results
```

## Error Handling & Recovery

### Common Errors & Recovery

| Error Type | Cause | Recovery Strategy | Max Attempts |
|-----------|-------|------------------|--------------|
| **Discovery Errors** |
| No active session | No `.active-*` markers found | Create or resume session: `/workflow:plan "project"` | N/A |
| Multiple sessions | Multiple `.active-*` markers | Prompt user selection | N/A |
| Corrupted session | Invalid JSON files | Recreate session structure or validate files | N/A |
| **Execution Errors** |
| Agent failure | Agent crash/timeout | Retry with simplified context | 2 |
| Flow control error | Command failure | Skip optional, fail critical | 1 per step |
| Context loading error | Missing dependencies | Reload from JSON, use defaults | 3 |
| JSON file corruption | File system issues | Restore from backup/recreate | 1 |

### Error Prevention
- **Pre-flight Checks**: Validate session integrity before execution
- **Backup Strategy**: Create task snapshots before major operations
- **Atomic Updates**: Update JSON files atomically to prevent corruption
- **Dependency Validation**: Check all depends_on references exist
- **Context Verification**: Ensure all required context is available

### Recovery Procedures

**Session Recovery**:
```bash
# Check session integrity
find .workflow -name ".active-*" | while read marker; do
  session=$(basename "$marker" | sed 's/^\.active-//')
  [ ! -d ".workflow/$session" ] && rm "$marker"
done

# Recreate corrupted session files
[ ! -f ".workflow/$session/workflow-session.toon" ] && \
  echo '{"session_id":"'$session'","status":"active"}' > ".workflow/$session/workflow-session.toon"
```

**Task Recovery**:
```bash
# Validate task TOON integrity
for task_file in .workflow/$session/.task/*.toon; do
  jq empty "$task_file" 2>/dev/null || echo "Corrupted: $task_file"
done

# Fix missing dependencies
missing_deps=$(jq -r '.context.depends_on[]?' .workflow/$session/.task/*.toon | sort -u)
for dep in $missing_deps; do
  [ ! -f ".workflow/$session/.task/$dep.toon" ] && echo "Missing dependency: $dep"
done
```

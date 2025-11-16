> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.

--- 
name: task-generate
description: Generate task TOON files and IMPL_PLAN.md from analysis results using action-planning-agent with artifact integration
argument-hint: "--session WFS-session-id [--cli-execute]"
examples:
  - /workflow:tools:task-generate --session WFS-auth
  - /workflow:tools:task-generate --session WFS-auth --cli-execute
---

# Task Generation Command

## 1. Overview
This command generates task TOON files and an `IMPL_PLAN.md` from brainstorming role analyses. It automatically detects and integrates all brainstorming artifacts (role-specific `analysis.md` files and `guidance-specification.md`), creating a structured and context-rich plan for implementation. The command supports two primary execution modes: a default agent-based mode for seamless context handling and a `--cli-execute` mode that leverages the Codex CLI for complex, autonomous development tasks. Its core function is to translate requirements and design specifications from role analyses into actionable, executable tasks, ensuring all necessary context, dependencies, and implementation steps are defined upfront.

## 2. Execution Modes

This command offers two distinct modes for task execution, providing flexibility for different implementation complexities.

### Agent Mode (Default)
In the default mode, each step in `implementation_approach` **omits the `command` field**. The agent interprets the step's `modification_points` and `logic_flow` to execute the task autonomously.
- **Step Structure**: Contains `step`, `title`, `description`, `modification_points`, `logic_flow`, `depends_on`, and `output` fields
- **Execution**: Agent reads these fields and performs the implementation autonomously
- **Context Loading**: Agent loads context via `pre_analysis` steps
- **Validation**: Agent validates against acceptance criteria in `context.acceptance`
- **Benefit**: Direct agent execution with full context awareness, no external tool overhead
- **Use Case**: Standard implementation tasks where agent capability is sufficient

### CLI Execute Mode (`--cli-execute`)
When the `--cli-execute` flag is used, each step in `implementation_approach` **includes a `command` field** that specifies the exact execution command. This mode is designed for complex implementations requiring specialized CLI tools.
- **Step Structure**: Includes all default fields PLUS a `command` field
- **Execution**: The specified command executes the step directly (e.g., `bash(codex ...)`)
- **Context Packages**: Each command receives context via the CONTEXT field in the prompt
- **Multi-Step Support**: Complex tasks can have multiple sequential codex steps with `resume --last`
- **Benefit**: Leverages specialized CLI tools (codex/gemini) for complex reasoning and autonomous execution
- **Use Case**: Large-scale features, complex refactoring, or when user explicitly requests CLI tool usage

## 3. Core Principles
This command is built on a set of core principles to ensure efficient and reliable task generation.

- **Role Analysis-Driven**: All generated tasks originate from role-specific `analysis.md` files (enhanced in synthesis phase), ensuring direct link between requirements/design and implementation
- **Artifact-Aware**: Automatically detects and integrates all brainstorming outputs (role analyses, guidance-specification.md, enhancements) to enrich task context
- **Context-Rich**: Embeds comprehensive context (requirements, focus paths, acceptance criteria, artifact references) directly into each task TOON
- **Path Clarity**: All `focus_paths` prefer absolute paths (e.g., `D:\\project\\src\\module`), or clear relative paths from project root (e.g., `./src/module`)
- **Flow-Control Ready**: Pre-defines clear execution sequence (`pre_analysis`, `implementation_approach`) within each task
- **Memory-First**: Prioritizes using documents already loaded in conversation memory to avoid redundant file operations
- **Mode-Flexible**: Supports both agent-driven execution (default) and CLI tool execution (with `--cli-execute` flag)
- **Multi-Step Support**: Complex tasks can use multiple sequential steps in `implementation_approach` with codex resume mechanism
- **Quantification-Enforced**: **NEW** - All requirements, acceptance criteria, and modification points MUST include explicit counts and enumerations to prevent ambiguity (e.g., "17 commands: [list]" not "implement commands")
- **Responsibility**: Parses analysis, detects artifacts, generates enhanced task TOON files, creates `IMPL_PLAN.md` and `TODO_LIST.md`, updates session state

## 3.5. Quantification Requirements (MANDATORY)

**Purpose**: Eliminate ambiguity by enforcing explicit counts and enumerations in all task specifications.

**Core Rules**:
1. **Extract Counts from Analysis**: Search for HOW MANY items and list them explicitly
2. **Enforce Explicit Lists**: Every deliverable uses format `{count} {type}: [{explicit_list}]`
3. **Make Acceptance Measurable**: Include verification commands (e.g., `ls ... | wc -l = N`)
4. **Quantify Modification Points**: Specify exact targets (files, functions with line numbers)
5. **Avoid Vague Language**: Replace "complete", "comprehensive", "reorganize" with quantified statements

**Standard Formats**:

- **Requirements**: `"Implement N items: [item1, item2, ...]"` or `"Modify N files: [file1:func:lines, ...]"`
- **Acceptance**: `"N items exist: verify by [command]"` or `"Coverage >= X%: verify by [test command]"`
- **Modification Points**: `"Create N files: [list]"` or `"Modify N functions: [func() in file lines X-Y]"`

**Validation Checklist**:
- [ ] Every requirement contains explicit count or enumerated list
- [ ] Every acceptance criterion is measurable with verification command
- [ ] Every modification_point specifies exact targets (files/functions/lines)
- [ ] No vague language ("complete", "comprehensive", "reorganize" without counts)
- [ ] Each implementation step has its own acceptance criteria

## 4. Execution Flow
The command follows a streamlined, three-step process to convert analysis into executable tasks.

### Step 1: Input & Discovery
The process begins by gathering all necessary inputs. It follows a **Memory-First Rule**, skipping file reads if documents are already in the conversation memory.
1.  **Session Validation**: Loads and validates the session from `.workflow/{session_id}/workflow-session.toon`.
2.  **Context Package Loading** (primary source): Reads `.workflow/{session_id}/.process/context-package.toon` for smart context and artifact catalog.
3.  **Brainstorm Artifacts Extraction**: Extracts role analysis paths from `context-package.toon` → `brainstorm_artifacts.role_analyses[]` (supports `analysis*.md` automatically).
4.  **Document Loading**: Reads role analyses, guidance specification, synthesis output, and conflict resolution (if exists) using paths from context package.

### Step 2: Task Decomposition & Grouping
Once all inputs are loaded, the command analyzes the tasks defined in the analysis results and groups them based on shared context.

**Phase 2.1: Quantification Extraction (NEW - CRITICAL)**
1. **Count Extraction**: Scan analysis documents for quantifiable information:
   - Search for numbers + nouns (e.g., "5 files", "17 commands", "3 features")
   - Identify enumerated lists (bullet points, numbered lists, comma-separated items)
   - Extract explicit counts from tables, diagrams, or structured data
   - Store extracted counts with their context (what is being counted)

2. **List Enumeration**: Build explicit lists for each deliverable:
   - If analysis says "implement session commands", enumerate ALL commands: [start, resume, list, complete, archive]
   - If analysis mentions "create categories", list ALL categories: [literature, experiment, data-analysis, visualization, context]
   - If analysis describes "modify functions", list ALL functions with line numbers
   - Maintain full enumerations (no "..." unless list exceeds 20 items)

3. **Verification Method Assignment**: For each deliverable, determine verification approach:
   - File count: `ls {path}/*.{ext} | wc -l = {count}`
   - Directory existence: `ls {parent}/ | grep -E '(name1|name2|...)' | wc -l = {count}`
   - Test coverage: `pytest --cov={module} --cov-report=term | grep TOTAL | awk '{print $4}' >= {percentage}`
   - Function existence: `grep -E '(func1|func2|...)' {file} | wc -l = {count}`

4. **Ambiguity Detection**: Flag vague language for replacement:
   - Detect words: "complete", "comprehensive", "reorganize", "refactor", "implement", "create" without counts
   - Require quantification: "implement" → "implement {N} {items}: [{list}]"
   - Reject unquantified deliverables

**Phase 2.2: Task Definition & Grouping**
1.  **Task Definition Parsing**: Extracts task definitions, requirements, and dependencies from quantified analysis
2.  **Context Signature Analysis**: Computes a unique hash (`context_signature`) for each task based on its `focus_paths` and referenced `artifacts`
3.  **Task Grouping**:
    *   Tasks with the **same signature** are candidates for merging, as they operate on the same context
    *   Tasks with **different signatures** and no dependencies are grouped for parallel execution
    *   Tasks with `depends_on` relationships are marked for sequential execution
4.  **Modification Target Determination**: Extracts specific code locations (`file:function:lines`) from the analysis to populate the `target_files` field

### Step 3: Output Generation
Finally, the command generates all the necessary output files.
1.  **Task TOON Creation**: Creates individual `.task/IMPL-*.toon` files, embedding all context, artifacts, and flow control steps. If `--cli-execute` is active, it generates the appropriate `codex exec` commands.
2.  **IMPL_PLAN.md Generation**: Creates the main implementation plan document, summarizing the strategy, tasks, and dependencies.
3.  **TODO_LIST.md Generation**: Creates a simple checklist for tracking task progress.
4.  **Session State Update**: Updates `workflow-session.toon` with the final task count and artifact inventory, marking the session as ready for execution.

## 5. Task Decomposition Strategy
The command employs a sophisticated strategy to group and decompose tasks, optimizing for context reuse and parallel execution.

### Core Principles
- **Primary Rule: Shared Context → Merge Tasks**: Tasks that operate on the same files, use the same artifacts, and share the same tech stack are merged. This avoids redundant context loading and recognizes inherent relationships between the tasks.
- **Secondary Rule: Different Contexts + No Dependencies → Decompose for Parallel Execution**: Tasks that are fully independent (different files, different artifacts, no shared dependencies) are decomposed into separate parallel execution groups.

### Context Analysis for Task Grouping
The decision to merge or decompose is based on analyzing context indicators:

1.  **Shared Context Indicators (→ Merge)**:
    *   Identical `focus_paths` (working on the same modules/files).
    *   Same tech stack and dependencies.
    *   Identical `context.artifacts` references.
    *   A sequential logic flow within the same feature.
    *   Shared test fixtures or setup.

2.  **Independent Context Indicators (→ Decompose)**:
    *   Different `focus_paths` (separate modules).
    *   Different tech stacks (e.g., frontend vs. backend).
    *   Different `context.artifacts` (using different brainstorming outputs).
    *   No shared dependencies.
    *   Can be tested independently.

**Decomposition is only performed when**:
- Tasks have different contexts and no shared dependencies (enabling parallel execution).
- A single task represents an excessive workload (e.g., >2500 lines of code or >6 files to modify).
- A sequential dependency creates a necessary block (e.g., IMPL-1 must complete before IMPL-2 can start).

### Context Signature Algorithm
To automate grouping, a `context_signature` is computed for each task.

```javascript
// Compute context signature for task grouping
function computeContextSignature(task) {
  const focusPathsStr = task.context.focus_paths.sort().join('|');
  const artifactsStr = task.context.artifacts.map(a => a.path).sort().join('|');
  const techStack = task.context.shared_context?.tech_stack?.sort().join('|') || '';

  return hash(`${focusPathsStr}:${artifactsStr}:${techStack}`);
}
```

### Execution Group Assignment
Tasks are assigned to execution groups based on their signatures and dependencies.

```javascript
// Group tasks by context signature
function groupTasksByContext(tasks) {
  const groups = {};

  tasks.forEach(task => {
    const signature = computeContextSignature(task);
    if (!groups[signature]) {
      groups[signature] = [];
    }
    groups[signature].push(task);
  });

  return groups;
}

// Assign execution groups for parallel tasks
function assignExecutionGroups(tasks) {
  const contextGroups = groupTasksByContext(tasks);

  Object.entries(contextGroups).forEach(([signature, groupTasks]) => {
    if (groupTasks.length === 1) {
      const task = groupTasks[0];
      // Single task with unique context
      if (!task.context.depends_on || task.context.depends_on.length === 0) {
        task.meta.execution_group = `parallel-${signature.slice(0, 8)}`;
      } else {
        task.meta.execution_group = null; // Sequential task
      }
    } else {
      // Multiple tasks with same context → Should be merged
      console.warn(`Tasks ${groupTasks.map(t => t.id).join(', ')} share context and should be merged`);
      // Merge tasks into single task
      return mergeTasks(groupTasks);
    }
  });
}
```
**Task Limits**:
- **Maximum 10 tasks** (hard limit).
- **Hierarchy**: Flat (≤5 tasks) or two-level (6-10 tasks). If >10, the scope should be re-evaluated.
- **Parallel Groups**: Tasks with the same `execution_group` ID are independent and can run concurrently.

## 6. Generated Outputs
The command produces three key documents and a directory of task files.

### 6.1. Task TOON Schema (`.task/IMPL-*.toon`)
Each task TOON embeds all necessary context, artifacts, and execution steps using this schema:

**Top-Level Fields**:
- `id`: Task identifier (format: `IMPL-N` or `IMPL-N.M` for subtasks)
- `title`: Descriptive task name
- `status`: Task state (`pending|active|completed|blocked|container`)
- `context_package_path`: Path to context package (`.workflow/WFS-[session]/.process/context-package.toon`)
- `meta`: Task metadata
- `context`: Task-specific context and requirements
- `flow_control`: Execution steps and workflow

**Meta Object**:
- `type`: Task category (`feature|bugfix|refactor|test-gen|test-fix|docs`)
- `agent`: Assigned agent (`@code-developer|@test-fix-agent|@universal-executor`)
- `execution_group`: Parallelization group ID or null
- `context_signature`: Hash for context-based grouping

**Context Object**:
- `requirements`: Quantified implementation requirements (with counts and explicit lists)
- `focus_paths`: Target directories/files (absolute or relative paths)
- `acceptance`: Measurable acceptance criteria (with verification commands)
- `parent`: Parent task ID for subtasks
- `depends_on`: Prerequisite task IDs
- `inherited`: Shared patterns and dependencies from parent
- `shared_context`: Tech stack and conventions
- `artifacts`: Referenced brainstorm artifacts with paths, priority, and usage

**Flow Control Object**:
- `pre_analysis`: Context loading and preparation steps
  - `load_context_package`: Load smart context and artifact catalog
  - `load_role_analysis_artifacts`: Load role analyses dynamically from context package
  - `load_planning_context`: Load finalized decisions with resolved conflicts
  - `codebase_exploration`: Discover existing patterns
  - `analyze_task_patterns`: Identify modification targets
- `implementation_approach`: Execution steps
  - **Agent Mode**: Steps contain `modification_points` and `logic_flow` (agent executes autonomously)
  - **CLI Mode**: Steps include `command` field with CLI tool invocation
- `target_files`: Specific files/functions/lines to modify

**Key Characteristics**:
- **Quantification**: All requirements/acceptance use explicit counts and enumerations
- **Mode Flexibility**: Supports both agent execution (default) and CLI tool execution (`--cli-execute`)
- **Context Intelligence**: References context-package.toon for smart context and artifact paths
- **Artifact Integration**: Dynamically loads role analyses and brainstorm artifacts

**Example Task TOON**:
```json
{
  "id": "IMPL-1",
  "title": "Implement feature X with Y components",
  "status": "pending",
  "context_package_path": ".workflow/WFS-session/.process/context-package.toon",
  "meta": {
    "type": "feature",
    "agent": "@code-developer",
    "execution_group": "parallel-abc123",
    "context_signature": "hash-value"
  },
  "context": {
    "requirements": [
      "Implement 5 commands: [cmd1, cmd2, cmd3, cmd4, cmd5]",
      "Create 3 directories: [dir1/, dir2/, dir3/]",
      "Modify 2 functions: [funcA() in file1.ts lines 10-25, funcB() in file2.ts lines 40-60]"
    ],
    "focus_paths": ["D:\\project\\src\\module", "./tests/module"],
    "acceptance": [
      "5 command files created: verify by ls .claude/commands/*/*.md | wc -l = 5",
      "3 directories exist: verify by ls -d dir*/ | wc -l = 3",
      "All tests pass: pytest tests/ --cov=src/module (>=80% coverage)"
    ],
    "depends_on": [],
    "artifacts": [
      {
        "path": ".workflow/WFS-session/.brainstorming/system-architect/analysis.md",
        "priority": "highest",
        "usage": "Architecture decisions and API specifications"
      }
    ]
  },
  "flow_control": {
    "pre_analysis": [
      {
        "step": "load_context_package",
        "action": "Load context package for artifact paths and smart context",
        "commands": ["Read({{context_package_path}})"],
        "output_to": "context_package",
        "on_error": "fail"
      },
      {
        "step": "load_role_analysis_artifacts",
        "action": "Load role analyses from context-package.toon",
        "commands": [
          "Read({{context_package_path}})",
          "Extract(brainstorm_artifacts.role_analyses[].files[].path)",
          "Read(each extracted path)"
        ],
        "output_to": "role_analysis_artifacts",
        "on_error": "skip_optional"
      }
    ],
    "implementation_approach": [
      {
        "step": 1,
        "title": "Implement feature following role analyses",
        "description": "Implement feature X using requirements from role analyses and context package",
        "modification_points": [
          "Create 5 command files: [cmd1.md, cmd2.md, cmd3.md, cmd4.md, cmd5.md]",
          "Modify funcA() in file1.ts lines 10-25: add validation logic",
          "Modify funcB() in file2.ts lines 40-60: integrate with new API"
        ],
        "logic_flow": [
          "Load role analyses and context package",
          "Extract requirements and design decisions",
          "Implement commands following existing patterns",
          "Update functions with new logic",
          "Validate against acceptance criteria"
        ],
        "depends_on": [],
        "output": "implementation"
      }
    ],
    "target_files": ["file1.ts:funcA:10-25", "file2.ts:funcB:40-60"]
  }
}
```

**Note**: In CLI Execute Mode (`--cli-execute`), `implementation_approach` steps include a `command` field with the CLI tool invocation (e.g., `bash(codex ...)`).

### 6.2. IMPL_PLAN.md Structure
This document provides a high-level overview of the entire implementation plan.

```markdown
---
identifier: WFS-{session-id}
source: "User requirements" | "File: path" | "Issue: ISS-001"
role_analyses: .workflow/{session-id}/.brainstorming/[role]/analysis*.md
artifacts: .workflow/{session-id}/.brainstorming/
context_package: .workflow/{session-id}/.process/context-package.toon  # CCW smart context
guidance_specification: .workflow/{session-id}/.brainstorming/guidance-specification.md  # Finalized decisions with resolved conflicts
workflow_type: "standard | tdd | design"  # Indicates execution model
verification_history:  # CCW quality gates
  synthesis_clarify: "passed | skipped | pending"  # Brainstorm phase clarification
  action_plan_verify: "pending"
  conflict_resolution: "resolved | none | low"  # Status from context-package.toon
phase_progression: "brainstorm → synthesis → context → conflict_resolution (if needed) → planning"  # CCW workflow phases
---

# Implementation Plan: {Project Title}

## 1. Summary
Core requirements, objectives, technical approach summary (2-3 paragraphs max).

**Core Objectives**:
- [Key objective 1]
- [Key objective 2]

**Technical Approach**:
- [High-level approach]

## 2. Context Analysis

### CCW Workflow Context
**Phase Progression**:
- ✅ Phase 1: Brainstorming (role analyses generated by participating roles)
- ✅ Phase 2: Synthesis (concept enhancement + clarification, {N} questions answered, role analyses refined)
- ✅ Phase 3: Context Gathering (context-package.toon: {N} files, {M} modules analyzed, conflict_risk: {level})
- ✅ Phase 4: Conflict Resolution ({status}: {conflict_count} conflicts detected and resolved | skipped if no conflicts)
- ⏳ Phase 5: Task Generation (current phase - generating IMPL_PLAN.md and task TOON files)

**Quality Gates**:
- synthesis-clarify: ✅ Passed ({N} ambiguities resolved, {M} enhancements applied)
- action-plan-verify: ⏳ Pending (recommended before /workflow:execute)

**Context Package Summary**:
- **Focus Paths**: {list key directories from context-package.toon}
- **Key Files**: {list primary files for modification}
- **Module Depth Analysis**: {from get_modules_by_depth.sh output}
- **Smart Context**: {total file count} files, {module count} modules, {dependency count} dependencies identified

### Project Profile
- **Type**: Greenfield/Enhancement/Refactor
- **Scale**: User count, data volume, complexity
- **Tech Stack**: Primary technologies
- **Timeline**: Duration and milestones

### Module Structure
'''
[Directory tree showing key modules]
'''

### Dependencies
**Primary**: [Core libraries and frameworks]
**APIs**: [External services]
**Development**: [Testing, linting, CI/CD tools]

### Patterns & Conventions
- **Architecture**: [Key patterns like DI, Event-Driven]
- **Component Design**: [Design patterns]
- **State Management**: [State strategy]
- **Code Style**: [Naming, TypeScript coverage]

## 3. Brainstorming Artifacts Reference

### Artifact Usage Strategy
**Primary Reference (Role Analyses)**:
- **What**: Role-specific analyses from brainstorming phase providing multi-perspective insights
- **When**: Every task references relevant role analyses for requirements and design decisions
- **How**: Extract requirements, architecture decisions, UI/UX patterns from applicable role documents
- **Priority**: Collective authoritative source - multiple role perspectives provide comprehensive coverage
- **CCW Value**: Maintains role-specific expertise while enabling cross-role integration during planning

**Context Intelligence (context-package.toon)**:
- **What**: Smart context gathered by CCW's context-gather phase
- **Content**: Focus paths, dependency graph, existing patterns, module structure, tech stack, conflict_risk status
- **Usage**: Tasks load this via `flow_control.preparatory_steps` for environment setup and conflict awareness
- **CCW Value**: Automated intelligent context discovery replacing manual file exploration

**Conflict Resolution Status**:
- **What**: Conflict resolution applied in-place to brainstorm artifacts (if conflict_risk was >= medium)
- **Location**: guidance-specification.md and role analyses (*.md) contain resolved conflicts
- **Status**: Check context-package.toon → conflict_detection.conflict_risk ("resolved" | "none" | "low")
- **Usage**: Read finalized decisions from guidance-specification.md (includes applied resolutions)
- **CCW Value**: Interactive conflict resolution with user confirmation, modifications applied automatically

### Role Analysis Documents (Highest Priority)
Role analyses provide specialized perspectives on the implementation:
- **system-architect/analysis.md**: Architecture design, ADRs, API specifications, caching strategies
- **ui-designer/analysis.md**: Design tokens, layout specifications, component patterns
- **ux-expert/analysis.md**: User journeys, interaction flows, accessibility requirements
- **guidance-specification/analysis.md**: Product vision, user stories, business requirements, success metrics
- **data-architect/analysis.md**: Data models, schemas, database design, migration strategies
- **api-designer/analysis.md**: API contracts, endpoint specifications, integration patterns

### Supporting Artifacts (Reference)
- **topic-framework.md**: Role-specific discussion points and analysis framework

**Artifact Priority in Development**:
1. {context_package_path} (primary source: smart context AND brainstorm artifact catalog in `brainstorm_artifacts` + conflict_risk status)
2. role/analysis*.md (paths from context-package.toon: requirements, design specs, enhanced by synthesis, with resolved conflicts if any)
3. guidance-specification.md (path from context-package.toon: finalized decisions with resolved conflicts if any)

## 4. Implementation Strategy

### Execution Strategy
**Execution Model**: [Sequential | Parallel | Phased | TDD Cycles]

**Rationale**: [Why this execution model fits the project]

**Parallelization Opportunities**:
- [List independent workstreams]

**Serialization Requirements**:
- [List critical dependencies]

### Architectural Approach
**Key Architecture Decisions**:
- [ADR references from role analyses]
- [Justification for architecture patterns]

**Integration Strategy**:
- [How modules communicate]
- [State management approach]

### Key Dependencies
**Task Dependency Graph**:
'''
[High-level dependency visualization]
'''

**Critical Path**: [Identify bottleneck tasks]

### Testing Strategy
**Testing Approach**:
- Unit testing: [Tools, scope]
- Integration testing: [Key integration points]
- E2E testing: [Critical user flows]

**Coverage Targets**:
- Lines: ≥70%
- Functions: ≥70%
- Branches: ≥65%

**Quality Gates**:
- [CI/CD gates]
- [Performance budgets]

## 5. Task Breakdown Summary

### Task Count
**{N} tasks** (flat hierarchy | two-level hierarchy, sequential | parallel execution)

### Task Structure
- **IMPL-1**: [Main task title]
- **IMPL-2**: [Main task title]
...

### Complexity Assessment
- **High**: [List with rationale]
- **Medium**: [List]
- **Low**: [List]

### Dependencies
[Reference Section 4.3 for dependency graph]

**Parallelization Opportunities**:
- [Specific task groups that can run in parallel]

## 6. Implementation Plan (Detailed Phased Breakdown)

### Execution Strategy

**Phase 1 (Weeks 1-2): [Phase Name]**
- **Tasks**: IMPL-1, IMPL-2
- **Deliverables**:
  - [Specific deliverable 1]
  - [Specific deliverable 2]
- **Success Criteria**:
  - [Measurable criterion]

**Phase 2 (Weeks 3-N): [Phase Name]**
...

### Resource Requirements

**Development Team**:
- [Team composition and skills]

**External Dependencies**:
- [Third-party services, APIs]

**Infrastructure**:
- [Development, staging, production environments]

## 7. Risk Assessment & Mitigation

| Risk | Impact | Probability | Mitigation Strategy | Owner |
|------|--------|-------------|---------------------|-------|
| [Risk description] | High/Med/Low | High/Med/Low | [Strategy] | [Role] |

**Critical Risks** (High impact + High probability):
- [Risk 1]: [Detailed mitigation plan]

**Monitoring Strategy**:
- [How risks will be monitored]

## 8. Success Criteria

**Functional Completeness**:
- [ ] All requirements from role analysis documents implemented
- [ ] All acceptance criteria from task.toon files met

**Technical Quality**:
- [ ] Test coverage ≥70%
- [ ] Bundle size within budget
- [ ] Performance targets met

**Operational Readiness**:
- [ ] CI/CD pipeline operational
- [ ] Monitoring and logging configured
- [ ] Documentation complete

**Business Metrics**:
- [ ] [Key business metrics from role analyses]
```

### 6.3. TODO_LIST.md Structure
A simple Markdown file for tracking the status of each task.

```markdown
# Tasks: [Session Topic]

## Task Progress
▸ **IMPL-001**: [Main Task Group] → [📋](./.task/IMPL-001.toon)
  - [ ] **IMPL-001.1**: [Subtask] → [📋](./.task/IMPL-001.1.toon)
  - [x] **IMPL-001.2**: [Subtask] → [📋](./.task/IMPL-001.2.toon) | [✅](./.summaries/IMPL-001.2-summary.md)

- [x] **IMPL-002**: [Simple Task] → [📋](./.task/IMPL-002.toon) | [✅](./.summaries/IMPL-002-summary.md)

## Status Legend
- `▸` = Container task (has subtasks)
- `- [ ]` = Pending leaf task
- `- [x]` = Completed leaf task
- Maximum 2 levels: Main tasks and subtasks only
```

### 6.4. Output Files Diagram
The command organizes outputs into a standard directory structure.
```
.workflow/{session-id}/
├── IMPL_PLAN.md                     # Implementation plan
├── TODO_LIST.md                     # Progress tracking
├── .task/
│   ├── IMPL-1.toon                  # Container task
│   ├── IMPL-1.1.toon                # Leaf task with flow_control
│   └── IMPL-1.2.toon                # Leaf task with flow_control
├── .brainstorming              # Input artifacts from brainstorm + synthesis
│   ├── guidance-specification.md    # Finalized decisions (with resolved conflicts if any)
│   └── {role}/analysis*.md          # Role analyses (enhanced by synthesis, with resolved conflicts if any)
└── .process/
    └── context-package.toon         # Input from context-gather (smart context + conflict_risk status)
```

## 7. Artifact Integration
The command intelligently detects and integrates artifacts from the `.brainstorming/` directory.

#### Artifact Priority
1.  **context-package.toon** (critical): Primary source - smart context AND all brainstorm artifact paths in `brainstorm_artifacts` section + conflict_risk status
2.  **role/analysis*.md** (highest): Paths from context-package.toon → role-specific requirements, design specs, enhanced by synthesis, with resolved conflicts applied in-place
3.  **guidance-specification.md** (high): Path from context-package.toon → finalized decisions with resolved conflicts (if conflict_risk was >= medium)

#### Artifact-Task Mapping
Artifacts are mapped to tasks based on their relevance to the task's domain.
- **Role analysis.md files**: Primary requirements source - all relevant role analyses included based on task type
- **ui-designer/analysis.md**: Mapped to UI/Frontend tasks for design tokens, layouts, components
- **system-architect/analysis.md**: Mapped to Architecture/Backend tasks for ADRs, APIs, patterns
- **subject-matter-expert/analysis.md**: Mapped to tasks related to domain logic or standards
- **data-architect/analysis.md**: Mapped to tasks involving data models, schemas, or APIs
- **product-manager/analysis.md**: Mapped to all tasks for business requirements and user stories

This ensures that each task has access to the most relevant and detailed specifications from role-specific analyses.

## 8. Error Handling

### Input Validation Errors
| Error | Cause | Resolution |
|-------|-------|------------|
| Session not found | Invalid session ID | Verify session exists |
| Context missing | Incomplete planning | Run context-gather first |
| Invalid format | Corrupted results | Regenerate analysis |

### Task Generation Errors
| Error | Cause | Resolution |
|-------|-------|------------|
| Count exceeds limit | >10 tasks | Re-scope requirements |
| Invalid structure | Missing fields | Fix analysis results |
| Dependency cycle | Circular refs | Adjust dependencies |

### Artifact Integration Errors
| Error | Cause | Recovery |
|-------|-------|----------|
| Artifact not found | Missing output | Continue without artifacts |
| Invalid format | Corrupted file | Skip artifact loading |
| Path invalid | Moved/deleted | Update references |

## 10. Usage & Related Commands

**Basic Usage**:
```bash
/workflow:tools:task-generate --session WFS-auth [--cli-execute]
```

**Workflow Integration**:
- Called by: `/workflow:plan` (task generation phase)
- Followed by: `/workflow:execute`, `/workflow:status`

**Related Commands**:
- `/workflow:plan` - Orchestrates entire planning workflow
- `/workflow:tools:context-gather` - Provides context package input
- `/workflow:tools:conflict-resolution` - Provides conflict resolution (if needed)
- `/workflow:execute` - Executes generated tasks

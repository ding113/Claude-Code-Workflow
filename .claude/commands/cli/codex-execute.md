---
name: codex-execute
description: Multi-stage Codex execution with automatic task decomposition into grouped subtasks using resume mechanism for context continuity
argument-hint: "[--verify-git] task description or task-id"
allowed-tools: SlashCommand(*), Bash(*), TodoWrite(*), Read(*), Glob(*)
---

# CLI Codex Execute Command (/cli:codex-execute)

## Purpose

Automated task decomposition and sequential execution with Codex, using `codex exec "..." resume --last` mechanism for continuity between subtasks.

**Input**: User description or task ID (automatically loads from `.task/[ID].json` if applicable)

## Core Workflow

```
Task Input → Analyze Dependencies → Create Task Flow Diagram →
Decompose into Subtask Groups → TodoWrite Tracking →
For Each Subtask Group:
  For First Subtask in Group:
    0. Stage existing changes (git add -A) if valid git repo
    1. Execute with Codex (new session)
    2. [Optional] Git verification
    3. Mark complete in TodoWrite
  For Related Subtasks in Same Group:
    0. Stage changes from previous subtask
    1. Execute with `codex exec "..." resume --last` (continue session)
    2. [Optional] Git verification
    3. Mark complete in TodoWrite
→ Final Summary
```

## Parameters

- `<input>` (Required): Task description or task ID (e.g., "implement auth" or "IMPL-001")
  - If input matches task ID format, loads from `.task/[ID].json`
  - Otherwise, uses input as task description
- `--verify-git` (Optional): Verify git status after each subtask completion

## Execution Flow

### Phase 1: Input Processing & Task Flow Analysis

1. **Parse Input**:
   - Check if input matches task ID pattern (e.g., `IMPL-001`, `TASK-123`)
   - If yes: Load from `.task/[ID].json` and extract requirements
   - If no: Use input as task description directly

2. **Analyze Dependencies & Create Task Flow Diagram**:
   - Analyze task complexity and scope
   - Identify dependencies and relationships between subtasks
   - Create visual task flow diagram showing:
     - Independent task groups (parallel execution possible)
     - Sequential dependencies (must use resume)
     - Branching logic (conditional paths)
   - Display flow diagram for user review

**Task Flow Diagram Format**:
```
[Group A: Auth Core]
  A1: Create user model ──┐
  A2: Add validation     ─┤─► [resume] ─► A3: Database schema
                          │
[Group B: API Layer]      │
  B1: Auth endpoints ─────┘─► [new session]
  B2: Middleware ────────────► [resume] ─► B3: Error handling

[Group C: Testing]
  C1: Unit tests ─────────────► [new session]
  C2: Integration tests ──────► [resume]
```

**Diagram Symbols**:
- `──►` Sequential dependency (must resume previous session)
- `─┐` Branch point (multiple paths)
- `─┘` Merge point (wait for completion)
- `[resume]` Use `codex exec "..." resume --last`
- `[new session]` Start fresh Codex session

3. **Decompose into Subtask Groups**:
   - Group related subtasks that share context
   - Break down into 3-8 subtasks total
   - Assign each subtask to a group
   - Create TodoWrite tracker with groups
   - Display decomposition for user review

**Decomposition Criteria**:
- Each subtask: 5-15 minutes completable
- Clear, testable outcomes
- Explicit dependencies
- Focused file scope (1-5 files per subtask)
- **Group coherence**: Subtasks in same group share context/files

### File Discovery for Task Decomposition

Use `rg` or MCP tools to discover relevant files, then group by domain:

**Workflow**: Discover → Analyze scope → Group by files → Create task flow

**Example**:
```bash
# Discover files
rg "authentication" --files-with-matches --type ts

# Group by domain
# Group A: src/auth/model.ts, src/auth/schema.ts
# Group B: src/api/auth.ts, src/middleware/auth.ts
# Group C: tests/auth/*.test.ts

# Each group becomes a session with related subtasks
```

File patterns: see intelligent-tools-strategy.md (loaded in memory)

### Phase 2: Group-Based Execution

**Pre-Execution Git Staging** (if valid git repository):
```bash
# Stage all current changes before codex execution
# This makes codex changes clearly visible in git diff
git add -A
git status --short
```

**For First Subtask in Each Group** (New Session):
```bash
# Start new Codex session for independent task group
codex -C [dir] --full-auto exec "
PURPOSE: [group goal]
TASK: [subtask description - first in group]
CONTEXT: @{relevant_files} @CLAUDE.md
EXPECTED: [specific deliverables]
RULES: [constraints]
Group [X]: [group name] - Subtask 1 of N in this group
" --skip-git-repo-check -s danger-full-access
```

**For Related Subtasks in Same Group** (Resume Session):
```bash
# Stage changes from previous subtask (if valid git repository)
git add -A

# Resume session ONLY for subtasks in same group
codex exec "
CONTINUE IN SAME GROUP:
Group [X]: [group name] - Subtask N of M

PURPOSE: [continuation goal within group]
TASK: [subtask N description]
CONTEXT: Previous work in this group completed, now focus on @{new_relevant_files}
EXPECTED: [specific deliverables]
RULES: Build on previous subtask in group, maintain consistency
" resume --last --skip-git-repo-check -s danger-full-access
```

**For First Subtask in Different Group** (New Session):
```bash
# Stage changes from previous group
git add -A

# Start NEW session for different group (no resume)
codex -C [dir] --full-auto exec "
PURPOSE: [new group goal]
TASK: [subtask description - first in new group]
CONTEXT: @{different_files} @CLAUDE.md
EXPECTED: [specific deliverables]
RULES: [constraints]
Group [Y]: [new group name] - Subtask 1 of N in this group
" --skip-git-repo-check -s danger-full-access
```

**Resume Decision Logic**:
```
if (subtask.group == previous_subtask.group):
    use `codex exec "..." resume --last`  # Continue session
else:
    use `codex -C [dir] exec "..."`       # New session
```

### Phase 3: Verification (if --verify-git enabled)

After each subtask completion:
```bash
# Check git status
git status --short

# Verify expected changes
git diff --stat

# Optional: Check for untracked files that should be committed
git ls-files --others --exclude-standard
```

**Verification Checks**:
- Files modified match subtask scope
- No unexpected changes in unrelated files
- No merge conflicts or errors
- Code compiles/runs (if applicable)

### Phase 4: TodoWrite Tracking with Groups

**Initial Setup with Task Flow**:
```javascript
TodoWrite({
  todos: [
    // Display task flow diagram first
    { content: "Task Flow Analysis Complete - See diagram above", status: "completed", activeForm: "Analyzing task flow" },

    // Group A subtasks (will use resume within group)
    { content: "[Group A] Subtask 1: [description]", status: "in_progress", activeForm: "Executing Group A subtask 1" },
    { content: "[Group A] Subtask 2: [description] [resume]", status: "pending", activeForm: "Executing Group A subtask 2" },

    // Group B subtasks (new session, then resume within group)
    { content: "[Group B] Subtask 1: [description] [new session]", status: "pending", activeForm: "Executing Group B subtask 1" },
    { content: "[Group B] Subtask 2: [description] [resume]", status: "pending", activeForm: "Executing Group B subtask 2" },

    // Group C subtasks (new session)
    { content: "[Group C] Subtask 1: [description] [new session]", status: "pending", activeForm: "Executing Group C subtask 1" },

    { content: "Final verification and summary", status: "pending", activeForm: "Verifying and summarizing" }
  ]
})
```

**After Each Subtask**:
```javascript
TodoWrite({
  todos: [
    { content: "Task Flow Analysis Complete - See diagram above", status: "completed", activeForm: "Analyzing task flow" },
    { content: "[Group A] Subtask 1: [description]", status: "completed", activeForm: "Executing Group A subtask 1" },
    { content: "[Group A] Subtask 2: [description] [resume]", status: "in_progress", activeForm: "Executing Group A subtask 2" },
    // ... update status
  ]
})
```

## Codex Resume Mechanism

**Why Group-Based Resume?**
- **Within Group**: Maintains conversation context for related subtasks
  - Codex remembers previous decisions and patterns
  - Reduces context repetition
  - Ensures consistency in implementation style
- **Between Groups**: Fresh session for independent tasks
  - Avoids context pollution from unrelated work
  - Prevents confusion when switching domains
  - Maintains focused attention on current group

**How It Works**:
1. **First subtask in Group A**: Creates new Codex session
2. **Subsequent subtasks in Group A**: Use `codex resume --last` to continue session
3. **First subtask in Group B**: Creates NEW Codex session (no resume)
4. **Subsequent subtasks in Group B**: Use `codex resume --last` within Group B
5. Each group builds on its own context, isolated from other groups

**When to Resume vs New Session**:
```
RESUME (same group):
  - Subtasks share files/modules
  - Logical continuation of previous work
  - Same architectural domain

NEW SESSION (different group):
  - Independent task area
  - Different files/modules
  - Switching architectural domains
  - Testing after implementation
```

**Image Support**:
```bash
# First subtask with design reference
codex -C [dir] -i design.png --full-auto exec "..." --skip-git-repo-check -s danger-full-access

# Resume for next subtask (image context preserved)
codex exec "CONTINUE TO NEXT SUBTASK: ..." resume --last --skip-git-repo-check -s danger-full-access
```

## Error Handling

**Subtask Failure**:
1. Mark subtask as blocked in TodoWrite
2. Report error details to user
3. Pause execution for manual intervention
4. Use AskUserQuestion for recovery decision:

```typescript
AskUserQuestion({
  questions: [{
    question: "Codex execution failed for the subtask. How should the workflow proceed?",
    header: "Recovery",
    options: [
      { label: "Retry Subtask", description: "Attempt to execute the same subtask again." },
      { label: "Skip Subtask", description: "Continue to the next subtask in the plan." },
      { label: "Abort Workflow", description: "Stop the entire execution." }
    ],
    multiSelect: false
  }]
})
```

**Git Verification Failure** (if --verify-git):
1. Show unexpected changes
2. Pause execution
3. Request user decision:
   - Continue anyway
   - Rollback and retry
   - Manual fix

**Codex Session Lost**:
1. Detect if `codex exec "..." resume --last` fails
2. Attempt retry with fresh session
3. Report to user if manual intervention needed

## Output Format

**During Execution**:
```
Task Flow Diagram:
[Group A: Auth Core]
  A1: Create user model ──┐
  A2: Add validation     ─┤─► [resume] ─► A3: Database schema
                          │
[Group B: API Layer]      │
  B1: Auth endpoints ─────┘─► [new session]
  B2: Middleware ────────────► [resume] ─► B3: Error handling

[Group C: Testing]
  C1: Unit tests ─────────────► [new session]
  C2: Integration tests ──────► [resume]

Task Decomposition:
  [Group A] 1. Create user model
  [Group A] 2. Add validation logic [resume]
  [Group A] 3. Implement database schema [resume]
  [Group B] 4. Create auth endpoints [new session]
  [Group B] 5. Add middleware [resume]
  [Group B] 6. Error handling [resume]
  [Group C] 7. Unit tests [new session]
  [Group C] 8. Integration tests [resume]

[Group A] Executing Subtask 1/8: Create user model
  Starting new Codex session for Group A...
  [Codex output]
  Subtask 1 completed

Git Verification:
  M  src/models/user.ts
  Changes verified

[Group A] Executing Subtask 2/8: Add validation logic
  Resuming Codex session (same group)...
  [Codex output]
  Subtask 2 completed

[Group B] Executing Subtask 4/8: Create auth endpoints
  Starting NEW Codex session for Group B...
  [Codex output]
  Subtask 4 completed
...

All Subtasks Completed
Summary: [file references, changes, next steps]
```

**Final Summary**:
```markdown
# Task Execution Summary: [Task Description]

## Subtasks Completed
1. [Subtask 1]: [files modified]
2. [Subtask 2]: [files modified]
...

## Files Modified
- src/file1.ts:10-50 - [changes]
- src/file2.ts - [changes]

## Git Status
- N files modified
- M files added
- No conflicts

## Next Steps
- [Suggested follow-up actions]
```

## Examples

**Example 1: Simple Task with Groups**
```bash
/cli:codex-execute "implement user authentication system"

# Task Flow Diagram:
# [Group A: Data Layer]
#   A1: Create user model ──► [resume] ──► A2: Database schema
#
# [Group B: Auth Logic]
#   B1: JWT token generation ──► [new session]
#   B2: Authentication middleware ──► [resume]
#
# [Group C: API Endpoints]
#   C1: Login/logout endpoints ──► [new session]
#
# [Group D: Testing]
#   D1: Unit tests ──► [new session]
#   D2: Integration tests ──► [resume]

# Execution:
# Group A: A1 (new) → A2 (resume)
# Group B: B1 (new) → B2 (resume)
# Group C: C1 (new)
# Group D: D1 (new) → D2 (resume)
```

**Example 2: With Git Verification**
```bash
/cli:codex-execute --verify-git "refactor API layer to use dependency injection"

# After each subtask, verifies:
# - Only expected files modified
# - No breaking changes in unrelated code
# - Tests still pass
```

**Example 3: With Task ID**
```bash
/cli:codex-execute IMPL-001

# Loads task from .task/IMPL-001.json
# Decomposes based on task requirements
```

## Best Practices

1. **Task Flow First**: Always create visual flow diagram before execution
2. **Group Related Work**: Cluster subtasks by domain/files for efficient resume
3. **Subtask Granularity**: Keep subtasks small and focused (5-15 min each)
4. **Clear Boundaries**: Each subtask should have well-defined input/output
5. **Git Hygiene**: Use `--verify-git` for critical refactoring
6. **Pre-Execution Staging**: Stage changes before each subtask to clearly see codex modifications
7. **Smart Resume**: Use `resume --last` ONLY within same group
8. **Fresh Sessions**: Start new session when switching to different group/domain
9. **Recovery Points**: TodoWrite with group labels provides clear progress tracking
10. **Image References**: Attach design files for UI tasks (first subtask in group)

## Input Processing

**Automatic Detection**:
- Input matches task ID pattern → Load from `.task/[ID].json`
- Otherwise → Use as task description

**Task JSON Structure** (when loading from file):
```json
{
  "task_id": "IMPL-001",
  "title": "Implement user authentication",
  "description": "Create JWT-based auth system",
  "acceptance_criteria": [...],
  "scope": {...},
  "brainstorming_refs": [...]
}
```

## Output Routing

**Execution Log Destination**:
- **IF** active workflow session exists:
  - Execution log: `.workflow/WFS-[id]/.chat/codex-execute-[timestamp].md`
  - Task summaries: `.workflow/WFS-[id]/.summaries/[TASK-ID]-summary.md` (if task ID)
  - Task updates: `.workflow/WFS-[id]/.task/[TASK-ID].json` status updates
  - TodoWrite tracking: Embedded in execution log
- **ELSE** (no active session):
  - **Recommended**: Create workflow session first (`/workflow:session:start`)
  - **Alternative**: Save to `.workflow/.scratchpad/codex-execute-[description]-[timestamp].md`

**Output Files** (during execution):
```
.workflow/WFS-[session-id]/
├── .chat/
│   └── codex-execute-20250105-143022.md    # Full execution log with task flow
├── .summaries/
│   ├── IMPL-001.1-summary.md               # Subtask summaries
│   ├── IMPL-001.2-summary.md
│   └── IMPL-001-summary.md                 # Final task summary
└── .task/
    ├── IMPL-001.json                       # Updated task status
    └── [subtask JSONs if decomposed]
```

**Examples**:
- During session `WFS-auth-system`, executing multi-stage auth implementation:
  - Log: `.workflow/WFS-auth-system/.chat/codex-execute-20250105-143022.md`
  - Summaries: `.workflow/WFS-auth-system/.summaries/IMPL-001.{1,2,3}-summary.md`
  - Task status: `.workflow/WFS-auth-system/.task/IMPL-001.json` (status: completed)
- No session, ad-hoc multi-stage task:
  - Log: `.workflow/.scratchpad/codex-execute-auth-refactor-20250105-143045.md`

**Save Results**:
- Execution log with task flow diagram and TodoWrite tracking
- Individual summaries for each completed subtask
- Final consolidated summary when all subtasks complete
- Modified code files throughout project

## Notes

**vs. `/cli:execute`**:
- `/cli:execute`: Single-shot execution with Gemini/Codex
- `/cli:codex-execute`: Multi-stage Codex execution with automatic task decomposition and resume mechanism

**Input Flexibility**: Accepts both freeform descriptions and task IDs (auto-detects and loads JSON)

**Context Window**: `codex exec "..." resume --last` maintains conversation history, ensuring consistency across subtasks without redundant context injection.

**Output Details**:
- Session management: see intelligent-tools-strategy.md
- **⚠️ Code Modification**: This command performs multi-stage code modifications - execution log tracks all changes

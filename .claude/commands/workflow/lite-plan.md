---
name: lite-plan
description: Lightweight interactive planning and execution workflow with in-memory planning, code exploration, and immediate execution after user confirmation
argument-hint: "[--tool claude|gemini|codex] [-e|--explore] \"task description\"|file.md"
allowed-tools: TodoWrite(*), Task(*), Bash(*), AskUserQuestion(*)
timeout: 180000
color: cyan
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Workflow Lite-Plan Command (/workflow:lite-plan)

## Overview

Intelligent lightweight planning and execution command with dynamic workflow adaptation based on task complexity.

## Core Functionality

- **Intelligent Task Analysis**: Automatically determines if exploration/planning agents are needed
- **Dynamic Exploration**: Calls cli-explore-agent only when task requires codebase understanding
- **Interactive Clarification**: Asks follow-up questions after exploration to gather missing information
- **Adaptive Planning**:
  - Simple tasks: Direct planning by current Claude
  - Complex tasks: Delegates to cli-planning-agent for detailed breakdown
- **Three-Dimensional Confirmation**: Multi-select interaction for task approval + execution method selection + code review tool selection
- **Direct Execution**: Immediate dispatch to selected execution method (agent or CLI)
- **Live Progress Tracking**: Real-time TodoWrite updates during execution
- **Optional Code Review**: Post-execution quality analysis with claude/gemini/codex (user selectable)


## Usage

### Command Syntax
```bash
/workflow:lite-plan [FLAGS] <TASK_DESCRIPTION>

# Flags
--tool <tool-name>         Preset CLI tool (claude|gemini|codex); if not provided, user selects during confirmation
-e, --explore              Force code exploration phase (overrides auto-detection logic)

# Arguments
<task-description>         Task description or path to .md file (required)
```


## Execution Process

### Workflow Overview

```
User Input ("/workflow:lite-plan \"task\"")
    |
    v
[Phase 1] Task Analysis & Exploration Decision (10-20 seconds)
    -> Analyze task description
    -> Decision: Need exploration? (Yes/No)
    -> If Yes: Launch cli-explore-agent
    -> Output: exploration findings (if performed)
    |
    v
[Phase 2] Clarification (Optional, user interaction)
    -> If exploration revealed ambiguities or missing info
    -> AskUserQuestion: Gather clarifications
    -> Update task context with user responses
    -> If no clarification needed: Skip to Phase 3
    |
    v
[Phase 3] Complexity Assessment & Planning (20-60 seconds)
    -> Assess task complexity (Low/Medium/High)
    -> Decision: Planning strategy
       - Low: Direct planning (current Claude)
       - Medium/High: Delegate to cli-planning-agent
    -> Output: Task breakdown with execution approach
    |
    v
[Phase 4] Task Confirmation & Execution Selection (User interaction)
    -> Display task breakdown and approach
    -> AskUserQuestion: Three dimensions (all multi-select)
       1. Confirm task: Allow/Modify/Cancel (can supplement via Other)
       2. Execution method: Agent/Provide Plan/CLI (input CLI tool in Other)
       3. Code review: No/Claude/Gemini/Codex
    -> Process selections and proceed to Phase 5
    -> If cancel: Exit
    |
    v
[Phase 5] Execution & Progress Tracking
    -> Create TodoWrite task list from breakdown
    -> Launch selected execution (agent or CLI)
    -> Track progress with TodoWrite updates
    -> Real-time status displayed to user
    -> If code review enabled: Run selected CLI analysis
    |
    v
Execution Complete
```

### Task Management Pattern

- TodoWrite creates task list before execution starts (Phase 5)
- Tasks marked as in_progress/completed during execution
- Real-time progress updates visible to user
- No intermediate file artifacts generated

## Detailed Phase Execution

### Phase 1: Task Analysis & Exploration Decision

**Operations**:
- Analyze task description to determine if code exploration is needed
- Decision logic:
  ```javascript
  needsExploration = (
    flags.includes('--explore') || flags.includes('-e') ||  // Force exploration if flag present
    (
      task.mentions_specific_files ||
      task.requires_codebase_context ||
      task.needs_architecture_understanding ||
      task.modifies_existing_code
    )
  )
  ```

**Decision Criteria**:

| Task Type | Needs Exploration | Reason |
|-----------|-------------------|--------|
| Any task with `-e` or `--explore` flag | **Yes (forced)** | **Flag overrides auto-detection logic** |
| "Implement new feature X" | Maybe | Depends on integration with existing code |
| "Refactor module Y" | Yes | Needs understanding of current implementation |
| "Add tests for Z" | Yes | Needs to understand code structure |
| "Create new standalone utility" | No | Self-contained, no existing code context |
| "Update documentation" | No | Doesn't require code exploration |
| "Fix bug in function F" | Yes | Needs to understand implementation |

**If Exploration Needed**:
- Launch cli-explore-agent with task-specific focus
- Agent call format:
  ```javascript
  Task(
    subagent_type="cli-explore-agent",
    description="Analyze codebase for task context",
    prompt=`
    Task: ${task_description}

    Analyze and return the following information in structured format:
    1. Project Structure: Overall architecture and module organization
    2. Relevant Files: List of files that will be affected by this task (with paths)
    3. Current Implementation Patterns: Existing code patterns, conventions, and styles
    4. Dependencies: External dependencies and internal module dependencies
    5. Integration Points: Where this task connects with existing code
    6. Architecture Constraints: Technical limitations or requirements
    7. Clarification Needs: Ambiguities or missing information requiring user input

    Time Limit: 60 seconds

    Output Format: Return a JSON-like structured object with the above fields populated.
    Include specific file paths, pattern examples, and clear questions for clarifications.
    `
  )
  ```

**Expected Return Structure**:
```javascript
explorationContext = {
  project_structure: "Description of overall architecture",
  relevant_files: ["src/auth/service.ts", "src/middleware/auth.ts", ...],
  patterns: "Description of existing patterns (e.g., 'Uses dependency injection pattern', 'React hooks convention')",
  dependencies: "List of dependencies and integration points",
  integration_points: "Where this connects with existing code",
  constraints: "Technical constraints (e.g., 'Must use existing auth library', 'No breaking changes')",
  clarification_needs: [
    {
      question: "Which authentication method to use?",
      context: "Found both JWT and Session patterns",
      options: ["JWT tokens", "Session-based", "Hybrid approach"]
    },
    // ... more clarification questions
  ]
}
```

**Output Processing**:
- Store exploration findings in `explorationContext`
- Extract `clarification_needs` array from exploration results
- Set `needsClarification = (clarification_needs.length > 0)`
- Use clarification_needs to generate Phase 2 questions

**Progress Tracking**:
- Mark Phase 1 as completed
- If needsClarification: Mark Phase 2 as in_progress
- Else: Skip to Phase 3

**Expected Duration**: 10-20 seconds (analysis) + 30-60 seconds (exploration if needed)

---

### Phase 2: Clarification (Optional)

**Skip Condition**: Only run if Phase 1 set `needsClarification = true`

**Operations**:
- Review `explorationContext.clarification_needs` from Phase 1
- Generate AskUserQuestion based on exploration findings
- Focus on ambiguities that affect implementation approach

**AskUserQuestion Call** (simplified reference):
```javascript
// Use clarification_needs from exploration to build questions
AskUserQuestion({
  questions: explorationContext.clarification_needs.map(need => ({
    question: `${need.context}\n\n${need.question}`,
    header: "Clarification",
    multiSelect: false,
    options: need.options.map(opt => ({
      label: opt,
      description: `Use ${opt} approach`
    }))
  }))
})
```

**Output Processing**:
- Collect user responses and store in `clarificationContext`
- Format: `{ question_id: selected_answer, ... }`
- This context will be passed to Phase 3 planning

**Progress Tracking**:
- Mark Phase 2 as completed
- Mark Phase 3 as in_progress

**Expected Duration**: User-dependent (typically 30-60 seconds)

---

### Phase 3: Complexity Assessment & Planning

**Operations**:
- Assess task complexity based on multiple factors
- Select appropriate planning strategy
- Generate task breakdown using selected method

**Complexity Assessment Factors**:
```javascript
complexityScore = {
  file_count: exploration.files_to_modify.length,
  integration_points: exploration.dependencies.length,
  architecture_changes: exploration.requires_architecture_change,
  technology_stack: exploration.unfamiliar_technologies.length,
  task_scope: (task.estimated_steps > 5),
  cross_cutting_concerns: exploration.affects_multiple_modules
}

// Calculate complexity
if (complexityScore < 3) complexity = "Low"
else if (complexityScore < 6) complexity = "Medium"
else complexity = "High"
```

**Complexity Levels**:

| Level | Characteristics | Planning Strategy |
|-------|----------------|-------------------|
| Low | 1-2 files, simple changes, clear requirements | Direct planning (current Claude) |
| Medium | 3-5 files, moderate integration, some ambiguity | Delegate to cli-planning-agent |
| High | 6+ files, complex architecture, high uncertainty | Delegate to cli-planning-agent with detailed analysis |

**Planning Execution**:

**Option A: Direct Planning (Low Complexity)**
```javascript
// Current Claude generates plan directly
planObject = {
  summary: "Brief overview of what needs to be done",
  approach: "Step-by-step implementation strategy",
  tasks: [
    "Task 1: Specific action with file references",
    "Task 2: Specific action with file references",
    // ... 3-5 tasks
  ],
  complexity: "Low",
  estimated_time: "15-30 minutes"
}
```

**Option B: Agent-Based Planning (Medium/High Complexity)**
```javascript
// Delegate to cli-planning-agent
Task(
  subagent_type="cli-planning-agent",
  description="Generate detailed implementation plan",
  prompt=`
  Task: ${task_description}

  Exploration Context:
  ${encodeTOON(explorationContext, { indent: 2 })}

  User Clarifications:
  ${encodeTOON(clarificationContext, { indent: 2 }) || "None provided"}

  Complexity Level: ${complexity}

  Generate a detailed implementation plan with the following components:

  1. Summary: 2-3 sentence overview of the implementation
  2. Approach: High-level implementation strategy
  3. Task Breakdown: 5-10 specific, actionable tasks
     - Each task should specify:
       * What to do
       * Which files to modify/create
       * Dependencies on other tasks (if any)
  4. Task Dependencies & Parallelization:
     - Identify independent tasks that can run in parallel (no shared file conflicts or logical dependencies)
     - Group tasks by execution order: parallel groups can execute simultaneously, sequential groups must wait for previous completion
     - Format: "Group 1 (parallel): Task 1, Task 2 | Group 2 (parallel): Task 3, Task 4 | Task 5 (depends on all)"
  5. Risks: Potential issues and mitigation strategies (for Medium/High complexity)
  6. Estimated Time: Total implementation time estimate
  7. Recommended Execution: "Direct" (agent) or "CLI" (autonomous tool)

  Output Format: Return a structured object with these fields:
  {
    summary: string,
    approach: string,
    tasks: string[],
    dependencies: string[] (optional),
    risks: string[] (optional),
    estimated_time: string,
    recommended_execution: "Direct" | "CLI"
  }

  Ensure tasks are specific, with file paths and clear acceptance criteria.
  `
)

// Agent returns detailed plan
planObject = agent_output.parse()
```

**Expected Return Structure**:
```javascript
planObject = {
  summary: "Implement JWT-based authentication system with middleware integration",
  approach: "Create auth service layer, implement JWT utilities, add middleware, update routes",
  tasks: [
    "Create authentication service in src/auth/service.ts with login/logout/verify methods",
    "Implement JWT token utilities in src/auth/jwt.ts (generate, verify, refresh)",
    "Add authentication middleware to src/middleware/auth.ts",
    "Update API routes in src/routes/*.ts to use auth middleware",
    "Add integration tests for auth flow in tests/auth.test.ts"
  ],
  dependencies: [
    "Group 1 (parallel): Task 1, Task 2 - Independent service and utilities, no file conflicts",
    "Group 2 (sequential): Task 3 - Depends on Task 2 completion (middleware needs JWT utilities)",
    "Group 3 (sequential): Task 4 - Depends on Task 3 completion (routes need middleware)",
    "Group 4 (sequential): Task 5 - Depends on all previous tasks (tests need complete implementation)"
  ],
  risks: [
    "Token refresh timing may conflict with existing session logic - test thoroughly",
    "Breaking change if existing auth is in use - plan migration strategy"
  ],
  estimated_time: "30-45 minutes",
  recommended_execution: "CLI"  // Based on clear requirements and straightforward implementation
}
```

**Output Structure**:
```javascript
planObject = {
  summary: "2-3 sentence overview",
  approach: "Implementation strategy",
  tasks: [
    "Task 1: ...",
    "Task 2: ...",
    // ... 3-10 tasks based on complexity
  ],
  complexity: "Low|Medium|High",
  dependencies: ["task1 -> task2", ...],  // if Medium/High
  risks: ["risk1", "risk2", ...],         // if High
  estimated_time: "X minutes",
  recommended_execution: "Direct|CLI"
}
```

**Progress Tracking**:
- Mark Phase 3 as completed
- Mark Phase 4 as in_progress

**Expected Duration**:
- Low complexity: 20-30 seconds (direct)
- Medium/High complexity: 40-60 seconds (agent-based)

---

### Phase 4: Task Confirmation & Execution Selection

**User Interaction Flow**: Three-dimensional multi-select confirmation

**Operations**:
- Display plan summary with full task breakdown
- Collect three multi-select inputs:
  1. Task confirmation (Allow/Modify/Cancel + optional supplements)
  2. Execution method (Agent/Provide Plan/CLI + CLI tool specification)
  3. Code review tool (No/Claude/Gemini/Codex)
- Support plan supplements and modifications via "Other" input

**Question 1: Task Confirmation (Multi-select)**

Display plan to user and ask for confirmation:
- Show: summary, approach, task breakdown, dependencies, risks, complexity, estimated time
- Options: "Allow" / "Modify" / "Cancel" (multi-select enabled)
- User can input plan supplements via "Other" option
- If Cancel selected: Exit workflow
- Otherwise: Proceed to Question 2

**Question 2: Execution Method Selection (Multi-select)**

Ask user to select execution method:
- Options: "Agent Execution" / "Provide Plan" / "CLI Execution" (multi-select enabled)
- User inputs CLI tool choice (gemini/codex) via "Other" option if "CLI Execution" selected
- Store selection for Phase 5 execution

**Simplified AskUserQuestion Reference**:
```javascript
// Question 1: Task Confirmation (Multi-select)
AskUserQuestion({
  questions: [{
    question: `[Display plan with all details]\n\nConfirm this plan?`,
    header: "Confirm Plan",
    multiSelect: true,
    options: [
      { label: "Allow", description: "Proceed with plan" },
      { label: "Modify", description: "Adjust plan" },
      { label: "Cancel", description: "Abort" }
    ]
  }]
})

// Question 2: Execution Method (Multi-select)
AskUserQuestion({
  questions: [{
    question: `Select execution method (input CLI tool in Other if choosing CLI):`,
    header: "Execution Method",
    multiSelect: true,
    options: [
      { label: "Agent Execution", description: "Execute with @code-developer" },
      { label: "Provide Plan", description: "Return plan only" },
      { label: "CLI Execution", description: "Execute with CLI tool (specify in Other)" }
    ]
  }]
})

// Question 3: Code Review Tool Selection
AskUserQuestion({
  questions: [{
    question: `Enable code review after execution?`,
    header: "Code Review",
    options: [
      { label: "No", description: "Skip code review" },
      { label: "Claude (default)", description: "Current Claude agent review" },
      { label: "Gemini", description: "gemini-2.5-pro analysis" },
      { label: "Codex", description: "gpt-5.1-codex analysis" }
    ]
  }]
})
```

**Decision Flow**:
```
Task Confirmation (Multi-select):
  ├─ Allow (+ optional supplements in Other) → Proceed to Execution Method Selection
  ├─ Modify (+ optional supplements in Other) → Re-run Phase 3 with modifications
  └─ Cancel → Exit (no execution)

Execution Method Selection (Multi-select):
  ├─ Agent Execution → Launch @code-developer
  ├─ Provide Plan → Return plan JSON, skip execution
  └─ CLI Execution (+ tool name in Other: gemini/codex) → Build and execute CLI command

Code Review Selection (after execution):
  ├─ No → Skip review, workflow complete
  ├─ Claude (default) → Current Claude agent review
  ├─ Gemini → Run gemini code analysis
  └─ Codex → Run codex code analysis
```

**Progress Tracking**:
- Mark Phase 4 as completed
- Mark Phase 5 as in_progress

**Expected Duration**: User-dependent (1-3 minutes typical)

---

### Phase 5: Execution & Progress Tracking

**Operations**:
- Create TodoWrite task list from plan breakdown
- Launch selected execution method (agent or CLI)
- Track execution progress with real-time TodoWrite updates
- Display status to user

**Step 5.1: Create TodoWrite Task List**

**Before execution starts**, create task list:
```javascript
TodoWrite({
  todos: planObject.tasks.map((task, index) => ({
    content: task,
    status: "pending",
    activeForm: task.replace(/^(.*?):/, "$1ing:")  // "Implement X" -> "Implementing X"
  }))
})
```

**Example Task List**:
```
[ ] Implement authentication service in src/auth/service.ts
[ ] Create JWT token utilities in src/auth/jwt.ts
[ ] Add authentication middleware to src/middleware/auth.ts
[ ] Update API routes to use authentication
[ ] Add integration tests for auth flow
```

**Step 5.2: Launch Execution**

**IMPORTANT**: CLI execution MUST run in foreground (no background execution)

Based on user selection in Phase 4, execute appropriate method:

#### Option A: Direct Execution with Agent

**Operations**:
- Launch @code-developer agent with full plan context
- Agent receives exploration findings, clarifications, and task breakdown
- Agent call format:
  ```javascript
  Task(
    subagent_type="code-developer",
    description="Implement planned tasks with progress tracking",
    prompt=`
    Implement the following tasks with TodoWrite progress updates:

    Summary: ${planObject.summary}

    Task Breakdown:
    ${planObject.tasks.map((t, i) => `${i+1}. ${t}`).join('\n')}

    ${planObject.dependencies ? `\nTask Dependencies:\n${planObject.dependencies.join('\n')}` : ''}

    Implementation Approach:
    ${planObject.approach}

    Code Context:
    ${explorationContext || "No exploration performed"}

    ${clarificationContext ? `\nClarifications:\n${clarificationContext}` : ''}

    ${planObject.risks ? `\nRisks to Consider:\n${planObject.risks.join('\n')}` : ''}

    IMPORTANT Instructions:
    - **Parallel Execution**: Identify independent tasks from dependencies field and execute them in parallel using multiple tool calls in a single message
    - **Dependency Respect**: Sequential tasks must wait for dependent tasks to complete before starting
    - **TodoWrite Updates**: Mark tasks as in_progress when starting, completed when finished
    - **Intelligent Grouping**: Analyze task dependencies to determine parallel groups - tasks with no file conflicts or logical dependencies can run simultaneously
    - Test functionality as you go
    - Handle risks proactively
    `
  )
  ```

**Agent Responsibilities**:
- Mark tasks as in_progress when starting
- Mark tasks as completed when finished
- Update TodoWrite in real-time for user visibility

#### Option B: CLI Execution (Gemini/Codex)

**Operations**:
- Build CLI command with comprehensive context
- Execute CLI tool with write permissions
- Monitor CLI output and update TodoWrite based on progress indicators
- Parse CLI completion signals to mark tasks as done

**Command Format (Gemini)** - Full context with exploration and clarifications:
```bash
gemini -p "
PURPOSE: Implement planned tasks with full context from exploration and planning
TASK:
${planObject.tasks.map((t, i) => `• ${t}`).join('\n')}

MODE: write

CONTEXT: @**/* | Memory: Implementation plan from lite-plan workflow

## Exploration Findings
${explorationContext ? `
Project Structure:
${explorationContext.project_structure || 'Not available'}

Relevant Files:
${explorationContext.relevant_files?.join('\n') || 'Not specified'}

Current Implementation Patterns:
${explorationContext.patterns || 'Not analyzed'}

Dependencies and Integration Points:
${explorationContext.dependencies || 'Not specified'}

Architecture Constraints:
${explorationContext.constraints || 'None identified'}
` : 'No exploration performed (task did not require codebase context)'}

## User Clarifications
${clarificationContext ? `
The following clarifications were provided by the user after exploration:
${Object.entries(clarificationContext).map(([q, a]) => `Q: ${q}\nA: ${a}`).join('\n\n')}
` : 'No clarifications needed'}

## Implementation Plan Context
Task Summary: ${planObject.summary}

Implementation Approach:
${planObject.approach}

${planObject.dependencies ? `
Task Dependencies (execute in order):
${planObject.dependencies.join('\n')}
` : ''}

${planObject.risks ? `
Identified Risks:
${planObject.risks.join('\n')}
` : ''}

Complexity Level: ${planObject.complexity}
Estimated Time: ${planObject.estimated_time}

EXPECTED: All tasks implemented following the plan approach, with proper error handling and testing

RULES: $(cat ~/.claude/workflows/cli-templates/prompts/development/02-implement-feature.txt) | Follow implementation approach exactly | Handle identified risks proactively | write=CREATE/MODIFY/DELETE
" -m gemini-2.5-pro --approval-mode yolo
```

**Command Format (Codex)** - Session-based with resume support:

**First Execution (Establish Session)**:
```bash
codex --full-auto exec "
TASK: ${planObject.summary}

## Task Breakdown
${planObject.tasks.map((t, i) => `${i+1}. ${t}`).join('\n')}

${planObject.dependencies ? `\n## Task Dependencies\n${planObject.dependencies.join('\n')}` : ''}

## Implementation Approach
${planObject.approach}

## Code Context from Exploration
${explorationContext ? `
Project Structure: ${explorationContext.project_structure || 'Standard structure'}
Relevant Files: ${explorationContext.relevant_files?.join(', ') || 'TBD'}
Current Patterns: ${explorationContext.patterns || 'Follow existing conventions'}
Integration Points: ${explorationContext.dependencies || 'None specified'}
Constraints: ${explorationContext.constraints || 'None'}
` : 'No prior exploration - analyze codebase as needed'}

${clarificationContext ? `\n## User Clarifications\n${Object.entries(clarificationContext).map(([q, a]) => `${q}: ${a}`).join('\n')}` : ''}

${planObject.risks ? `\n## Risks to Handle\n${planObject.risks.join('\n')}` : ''}

## Execution Instructions
- Complete all tasks following the breakdown sequence
- Test functionality as you implement
- Handle identified risks proactively
- Create session for potential resume if needed

Complexity: ${planObject.complexity}
" -m gpt-5.1-codex --skip-git-repo-check -s danger-full-access
```

**Subsequent Executions (Resume if needed)**:
```bash
# If first execution fails or is interrupted, can resume:
codex --full-auto exec "
Continue implementation from previous session.

Remaining tasks:
${remaining_tasks.map((t, i) => `${i+1}. ${t}`).join('\n')}

Maintain context from previous execution.
" resume --last -m gpt-5.1-codex --skip-git-repo-check -s danger-full-access
```

**Codex Session Strategy**:
- First execution establishes full context and creates session
- If execution is interrupted or fails, use `resume --last` to continue
- Resume inherits all context from original execution
- Useful for complex tasks that may hit timeouts or require iteration



**Execution with Progress Tracking**:
```javascript
// Launch CLI in foreground (NOT background - avoid )
bash_result = Bash(
  command=cli_command,
  timeout=600000  // 10 minutes
)

// Monitor output and update TodoWrite
// Parse CLI output for task completion indicators
// Update TodoWrite when tasks complete
// Example: When CLI outputs "✓ Task 1 complete" -> Mark task 1 as completed
```

**CLI Progress Monitoring**:
- Parse CLI output for completion keywords ("done", "complete", "✓", etc.)
- Update corresponding TodoWrite tasks based on progress
- Provide real-time visibility to user

**Step 5.3: Track Execution Progress**

**Real-time TodoWrite Updates**:
```javascript
// As execution progresses, update task status:

// Task started
TodoWrite({
  todos: [
    { content: "Implement auth service", status: "in_progress", activeForm: "Implementing auth service" },
    { content: "Create JWT utilities", status: "pending", activeForm: "Creating JWT utilities" },
    // ...
  ]
})

// Task completed
TodoWrite({
  todos: [
    { content: "Implement auth service", status: "completed", activeForm: "Implementing auth service" },
    { content: "Create JWT utilities", status: "in_progress", activeForm: "Creating JWT utilities" },
    // ...
  ]
})
```

**User Visibility**:
- User sees real-time task progress
- Current task highlighted as "in_progress"
- Completed tasks marked with checkmark
- Pending tasks remain unchecked

**Progress Tracking**:
- Mark Phase 5 as in_progress throughout execution
- Mark Phase 5 as completed when all tasks done
- Final status summary displayed to user

**Step 5.4: Code Review (Optional)**

**Skip Condition**: Only run if user selected review tool in Phase 4 (not "No")

**Operations**:
- If Claude: Current agent performs direct code review analysis
- If CLI tool (gemini/codex): Execute CLI with code review analysis prompt
- Review all modified files from execution
- Generate quality assessment and improvement recommendations

**Command Format**:
```bash
# Claude (default): Direct agent review (no CLI command needed)
# Uses analysis prompt and TodoWrite tools directly

# CLI Tools (gemini/codex): Execute analysis command
{selected_tool} -p "
PURPOSE: Code review for implemented changes
TASK: • Analyze code quality • Identify potential issues • Suggest improvements
MODE: analysis
CONTEXT: @**/* | Memory: Review changes from lite-plan execution
EXPECTED: Quality assessment with actionable recommendations
RULES: $(cat ~/.claude/workflows/cli-templates/prompts/analysis/02-review-code-quality.txt) | Focus on recent changes | analysis=READ-ONLY
" -m {model}
```

**Expected Duration**: Varies by task complexity and execution method
- Low complexity: 5-15 minutes
- Medium complexity: 15-45 minutes
- High complexity: 45-120 minutes
- Code review (if enabled): +2-5 minutes

---

## Best Practices

### Workflow Intelligence

1. **Dynamic Adaptation**: Workflow automatically adjusts based on task characteristics
   - Smart exploration: Only runs when task requires codebase context
   - Adaptive planning: Simple tasks get direct planning, complex tasks use specialized agent
   - Context-aware clarification: Only asks questions when truly needed
   - Reduces unnecessary steps while maintaining thoroughness
   - **Flag-Based Control**:
     - Use `-e` or `--explore` to force exploration when:
       - Task appears simple but you know it requires codebase context
       - Auto-detection might miss subtle integration points
       - You want comprehensive code understanding before planning

2. **Progressive Clarification**: Gather information at the right time
   - Phase 1: Explore codebase to understand current state
   - Phase 2: Ask clarifying questions based on exploration findings
   - Phase 3: Plan with complete context (task + exploration + clarifications)
   - Avoids premature assumptions and reduces rework

3. **Complexity-Aware Planning**: Planning strategy matches task complexity
   - Low complexity (1-2 files): Direct planning by current Claude (fast, 20-30s)
   - Medium complexity (3-5 files): CLI planning agent (detailed, 40-50s)
   - High complexity (6+ files): CLI planning agent with risk analysis (thorough, 50-60s)
   - Balances speed and thoroughness appropriately

4. **Two-Dimensional Confirmation**: Separate task approval from execution method
   - First dimension: Confirm/Modify/Cancel plan
   - Second dimension: Direct execution vs CLI execution
   - Allows plan refinement without re-selecting execution method
   - Supports iterative planning with user feedback

### Task Management

1. **Live Progress Tracking**: TodoWrite provides real-time execution visibility
   - Tasks created before execution starts
   - Updated in real-time as work progresses
   - User sees current task being worked on
   - Clear completion status throughout execution

2. **Phase-Based Organization**: 5 distinct phases with clear transitions
   - Phase 1: Task Analysis & Exploration (automatic)
   - Phase 2: Clarification (conditional, interactive)
   - Phase 3: Planning (automatic, adaptive)
   - Phase 4: Confirmation (interactive, two-dimensional)
   - Phase 5: Execution & Tracking (automatic with live updates)

3. **Flexible Task Counts**: Task breakdown adapts to complexity
   - Low complexity: 3-5 tasks (focused)
   - Medium complexity: 5-7 tasks (detailed)
   - High complexity: 7-10 tasks (comprehensive)
   - Avoids artificial constraints while maintaining focus

4. **Dependency Tracking**: Medium/High complexity tasks include dependencies
   - Explicit task ordering when sequence matters
   - Parallel execution hints when tasks are independent
   - Risk flagging for complex interactions
   - Helps agent/CLI execute correctly

### Planning Standards

1. **Context-Rich Planning**: Plans include all relevant context
   - Exploration findings (code structure, patterns, constraints)
   - User clarifications (requirements, preferences, decisions)
   - Complexity assessment (risks, dependencies, time estimates)
   - Execution recommendations (Direct vs CLI, specific tool)

2. **Modification Support**: Plans can be iteratively refined
   - User can request plan modifications in Phase 4
   - Feedback incorporated into re-planning
   - No need to restart from scratch
   - Supports collaborative planning workflow

3. **No File Artifacts**: All planning stays in memory
   - Faster workflow without I/O overhead
   - Cleaner workspace
   - Plan context passed directly to execution
   - Reduces complexity and maintenance

## Error Handling

### Common Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| Phase 1 Exploration Failure | cli-explore-agent unavailable or timeout | Skip exploration, set `explorationContext = null`, log warning, continue to Phase 2/3 with task description only |
| Phase 2 Clarification Timeout | User no response > 5 minutes | Use exploration findings as-is without clarification, proceed to Phase 3 with warning |
| Phase 3 Planning Agent Failure | cli-planning-agent unavailable or timeout | Fallback to direct planning by current Claude (simplified plan), continue to Phase 4 |
| Phase 3 Planning Timeout | Planning takes > 90 seconds | Generate simplified direct plan, mark as "Quick Plan", continue to Phase 4 with reduced detail |
| Phase 4 Confirmation Timeout | User no response > 5 minutes | Save plan context to temporary var, display resume instructions, exit gracefully |
| Phase 4 Modification Loop | User requests modify > 3 times | Suggest breaking task into smaller pieces or using /workflow:plan for comprehensive planning |
| Phase 5 CLI Tool Unavailable | Selected CLI tool not installed | Show installation instructions, offer to re-select (Direct execution or different CLI) |
| Phase 5 Execution Failure | Agent/CLI crashes or errors | Display error details, save partial progress from TodoWrite, suggest manual recovery or retry |

## Input/Output

### Input Requirements
- Task description: String or path to .md file (required)
  - Should be specific and concrete
  - Can include context about existing code or requirements
  - Examples:
    - "Implement user authentication with JWT tokens"
    - "Refactor logging module for better performance"
    - "Add unit tests for authentication service"
- Flags (optional):
  - `--tool <name>`: Preset execution tool (claude|gemini|codex)
  - `-e` or `--explore`: Force code exploration phase (overrides auto-detection)

### Output Format

**In-Memory Plan Object**:
```javascript
{
  summary: "2-3 sentence overview of implementation",
  approach: "High-level implementation strategy",
  tasks: [
    "Task 1: Specific action with file locations",
    "Task 2: Specific action with file locations",
    // ... 3-7 tasks total
  ],
  complexity: "Low|Medium|High",
  recommended_tool: "Claude|Gemini|Codex",
  estimated_time: "X minutes"
}
```

**Execution Result**:
- Immediate dispatch to selected tool/agent with plan context
- No file artifacts generated during planning phase
- Execution starts immediately after user confirmation
- Tool/agent handles implementation and any necessary file operations

---
name: test-cycle-execute
description: Execute test-fix workflow with dynamic task generation and iterative fix cycles until test pass rate >= 95% or max iterations reached. Uses @cli-planning-agent for failure analysis and task generation.
argument-hint: "[--resume-session=\"session-id\"] [--max-iterations=N]"
allowed-tools: SlashCommand(*), TodoWrite(*), Read(*), Bash(*), Task(*)
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Workflow Test-Cycle-Execute Command

## Overview
Orchestrates dynamic test-fix workflow execution through iterative cycles of testing, analysis, and fixing. **Unlike standard execute, this command dynamically generates intermediate tasks** during execution based on test results and CLI analysis, enabling adaptive problem-solving.

**Quality Gate**: Iterates until test pass rate >= 95% (with criticality assessment) or 100% for full approval.

**CRITICAL - Orchestrator Boundary**:
- This command is the **ONLY place** where test failures are handled
- All failure analysis and fix task generation delegated to **@cli-planning-agent**
- Orchestrator calculates pass rate, assesses criticality, and manages iteration loop
- @test-fix-agent executes tests and applies fixes, reports results back
- **Do NOT handle test failures in main workflow or other commands** - always delegate to this orchestrator

**Resume Mode**: When called with `--resume-session` flag, skips discovery and continues from interruption point.

## Core Philosophy

### Dynamic vs Static Execution
**Standard Execute**: Pre-defined task queue → Sequential execution → Complete
**Test Execute**: Initial tasks → Test → Analyze → Generate fix tasks → Execute → Re-test → Repeat

### Iteration Loop Pattern
```
1. Execute current task (test/implement)
2. Run tests and collect results
3. If failures: CLI analysis → Generate fix tasks → Execute → Back to 2
4. If success: Mark complete → Next task
5. Repeat until all tests pass or max iterations reached
```

### Agent Coordination
- **@code-developer**: Understands requirements, generates implementations
- **@test-fix-agent**: Executes tests, applies fixes, validates results, assigns criticality
- **@cli-planning-agent**: Executes CLI analysis (Gemini/Qwen), parses results, generates fix task TOON files

## Core Rules
1. **Dynamic Task Generation**: Create intermediate fix tasks via @cli-planning-agent based on test failures
2. **Iterative Execution**: Repeat test-fix cycles until pass rate >= 95% (with criticality assessment) or max iterations
3. **Pass Rate Threshold**: Target 95%+ pass rate; 100% for full approval; assess criticality for 95-100% range
4. **Agent-Based Analysis**: Delegate CLI execution and task generation to @cli-planning-agent
5. **Agent Delegation**: All execution delegated to specialized agents (@cli-planning-agent, @test-fix-agent)
6. **Context Accumulation**: Each iteration builds on previous attempt context
7. **Autonomous Completion**: Continue until pass rate >= 95% without user interruption

## Core Responsibilities
- **Session Discovery**: Identify test-fix workflow sessions
- **Task Queue Management**: Maintain dynamic task queue with runtime additions
- **Test Execution**: Run tests through @test-fix-agent
- **Pass Rate Calculation**: Calculate test pass rate from test-results.toon (passed/total * 100)
- **Criticality Assessment**: Evaluate failure severity using test-results.toon criticality field
- **Threshold Decision**: Determine if pass rate >= 95% with criticality consideration
- **Failure Analysis Delegation**: Invoke @cli-planning-agent for CLI analysis and task generation
- **Iteration Control**: Manage fix cycles with max iteration limits (5 default)
- **Context Propagation**: Pass failure context and fix history to @cli-planning-agent
- **Progress Tracking**: TodoWrite updates for entire iteration cycle
- **Session Auto-Complete**: Call `/workflow:session:complete` when pass rate >= 95% (or 100%)

## Responsibility Matrix

**CRITICAL - Clear division of labor between orchestrator and agents:**

| Responsibility | test-cycle-execute (Orchestrator) | @cli-planning-agent | @test-fix-agent (Executor) |
|----------------|----------------------------|---------------------|---------------------------|
| Manage iteration loop | Yes - Controls loop flow | No - Not involved | No - Executes single task |
| Calculate pass rate | Yes - From test-results.toon | No - Not involved | No - Reports test results |
| Assess criticality | Yes - From test-results.toon | No - Not involved | Yes - Assigns criticality in test results |
| Run CLI analysis (Gemini/Qwen) | No - Delegates to cli-planning-agent | Yes - Executes CLI internally | No - Not involved |
| Parse CLI output | No - Delegated | Yes - Extracts fix strategy | No - Not involved |
| Generate IMPL-fix-N.toon | No - Delegated | Yes - Creates task files | No - Not involved |
| Run tests | No - Delegates to agent | No - Not involved | Yes - Executes test command |
| Apply fixes | No - Delegates to agent | No - Not involved | Yes - Modifies code |
| Detect test failures | Yes - Analyzes pass rate and decides next action | No - Not involved | Yes - Executes tests and reports outcomes |
| Add tasks to queue | Yes - Manages queue | No - Returns task ID | No - Not involved |
| Update iteration state | Yes - Maintains overall iteration state | No - Not involved | Yes - Updates individual task status only |

**Key Principles**:
- Orchestrator manages the "what" (iteration flow, threshold decisions) and "when" (task scheduling)
- @cli-planning-agent executes the "analysis" (CLI execution, result parsing, task generation)
- @test-fix-agent executes the "how" (run tests, apply fixes)

**ENFORCEMENT**: If test failures occur outside this orchestrator, do NOT handle them inline - always call `/workflow:test-cycle-execute` instead.

## Execution Lifecycle

### Phase 1: Discovery & Initialization
1. **Detect Session Type**: Identify test-fix session from `workflow_type: "test_session"`
2. **Load Session State**: Read `workflow-session.toon`, `IMPL_PLAN.md`, `TODO_LIST.md`
3. **Scan Initial Tasks**: Analyze `.task/*.toon` files
4. **Initialize TodoWrite**: Create task list including initial tasks
5. **Prepare Iteration Context**: Setup iteration counter and max limits

**Resume Mode**: Load existing iteration context from `.process/iteration-state.toon`

### Phase 2: Task Execution Loop
**Main execution loop with dynamic task generation (executed by test-cycle-execute orchestrator):**

**Execution Order**: The workflow begins by executing IMPL-001 (test generation) first. Upon successful completion, IMPL-002 (test-fix cycle) is initiated, starting the iterative test-fix loop.

```
For each task in queue:
  1. [Orchestrator] Load task TOON and context
  2. [Orchestrator] Determine task type (test-gen, test-fix, fix-iteration)
  3. [Orchestrator] Execute task through appropriate agent
  4. [Orchestrator] Collect agent results from .process/test-results.toon
  5. [Orchestrator] Calculate test pass rate:
     a. Parse test-results.toon: passRate = (passed / total) * 100
     b. Assess failure criticality (from test-results.toon)
     c. Evaluate fix effectiveness (NEW):
        - Compare passRate with previous iteration
        - If passRate decreased by >10%: REGRESSION detected
        - If regression: Rollback last fix, skip to next strategy
  6. [Orchestrator] Make threshold decision:
     IF passRate === 100%:
       → SUCCESS: Mark task complete, update TodoWrite, continue
     ELSE IF passRate >= 95%:
       → REVIEW: Check failure criticality
       → If all failures are "low" criticality: PARTIAL SUCCESS (approve with note)
       → If any "high" or "medium" criticality: Enter fix loop (step 7)
     ELSE IF passRate < 95%:
       → FAILED: Enter fix loop (step 7)
  7. If entering fix loop (pass rate < 95% OR critical failures exist):
     a. [Orchestrator] Invoke @cli-planning-agent with failure context
     b. [Agent] Executes CLI analysis + generates IMPL-fix-N.toon
     c. [Orchestrator] Insert fix task at front of queue
     d. [Orchestrator] Continue loop
  8. [Orchestrator] Check max iterations limit (abort if exceeded)
```

**Note**: The orchestrator controls the loop. Agents execute individual tasks and return results.

### Phase 3: Iteration Cycle (Test-Fix Loop)

**Orchestrator-controlled iteration with agent delegation:**

#### Iteration Structure
```
Iteration N (managed by test-cycle-execute orchestrator):
├── 1. Test Execution & Pass Rate Validation
│   ├── [Orchestrator] Launch @test-fix-agent with test task
│   ├── [Agent] Run test suite and save results to test-results.toon
│   ├── [Agent] Report completion back to orchestrator
│   ├── [Orchestrator] Calculate pass rate: (passed / total) * 100
│   └── [Orchestrator] Assess failure criticality from test-results.toon
├── 2. Failure Analysis & Task Generation (via @cli-planning-agent)
│   ├── [Orchestrator] Assemble failure context package (tests, errors, pass_rate)
│   ├── [Orchestrator] Invoke @cli-planning-agent with context
│   ├── [@cli-planning-agent] Execute CLI tool (Gemini/Qwen) internally
│   ├── [@cli-planning-agent] Parse CLI output for root causes and fix strategy
│   ├── [@cli-planning-agent] Generate IMPL-fix-N.toon with structured task
│   ├── [@cli-planning-agent] Save analysis to iteration-N-analysis.md
│   └── [Orchestrator] Receive task ID and insert into queue (front position)
├── 3. Fix Execution
│   ├── [Orchestrator] Launch @test-fix-agent with IMPL-fix-N task
│   ├── [Agent] Load fix strategy from task.context.fix_strategy
│   ├── [Agent] Apply surgical fixes to identified files
│   └── [Agent] Report completion
└── 4. Re-test
    └── [Orchestrator] Return to step 1 with updated code
```

**Key Changes**:
- CLI analysis + task generation encapsulated in @cli-planning-agent
- Pass rate calculation added to test execution step
- Orchestrator only assembles context and invokes agent

#### Iteration Task TOON Template
```json
{
  "id": "IMPL-fix-{iteration}",
  "title": "Fix test failures - Iteration {N}",
  "status": "pending",
  "meta": {
    "type": "test-fix-iteration",
    "agent": "@test-fix-agent",
    "iteration": N,
    "parent_task": "IMPL-002",
    "max_iterations": 5
  },
  "context": {
    "requirements": [
      "Fix identified test failures",
      "Address root causes from analysis"
    ],
    "failure_context": {
      "failed_tests": ["test1", "test2"],
      "error_messages": ["error1", "error2"],
      "failure_analysis": "Raw test output and error messages",
      "previous_attempts": ["iteration-1 context"]
    },
    "fix_strategy": {
      "approach": "Generated by CLI tool (Gemini/Qwen) analysis",
      "modification_points": ["file1:func1", "file2:func2"],
      "expected_outcome": "All tests pass"
    },
    "depends_on": ["IMPL-fix-{N-1}"],
    "inherited": {
      "iteration_history": [...]
    }
  },
  "flow_control": {
    "pre_analysis": [
      {
        "step": "load_failure_context",
        "command": "Read(.workflow/{session}/.process/iteration-{N-1}-failures.toon)",
        "output_to": "previous_failures",
        "on_error": "skip_optional"
      },
      {
        "step": "load_fix_strategy",
        "command": "Read(.workflow/{session}/.process/iteration-{N}-strategy.md)",
        "output_to": "fix_strategy",
        "on_error": "fail"
      }
    ],
    "implementation_approach": [
      {
        "step": 1,
        "title": "Apply fixes from strategy",
        "description": "Implement fixes identified by CLI analysis",
        "modification_points": "From fix_strategy",
        "logic_flow": [
          "Load failure context and strategy",
          "Apply surgical fixes",
          "Run tests",
          "Validate fixes"
        ]
      }
    ],
    "target_files": ["from fix_strategy"],
    "exit_conditions": {
      "success": "all_tests_pass",
      "failure": "max_iterations_reached",
      "max_iterations": 5
    }
  }
}
```

### Phase 4: Agent-Based Failure Analysis & Task Generation

**Orchestrator delegates CLI analysis and task generation to @cli-planning-agent:**

#### When Test Failures Occur (Pass Rate < 95% OR Critical Failures)
1. **[Orchestrator]** Detects failures from test-results.toon
2. **[Orchestrator]** Check for repeated failures (NEW):
   - Compare failed_tests with previous 2 iterations
   - If same test failed 3 times consecutively: Mark as "stuck"
   - If >50% of failures are "stuck": Switch analysis strategy or abort
3. **[Orchestrator]** Extracts failure context:
   - Failed tests with criticality assessment
   - Error messages and stack traces
   - Current pass rate
   - Previous iteration attempts (if any)
   - Stuck test markers (NEW)
4. **[Orchestrator]** Assembles context package for @cli-planning-agent
5. **[Orchestrator]** Invokes @cli-planning-agent via Task tool
6. **[@cli-planning-agent]** Executes internally:
   - Runs Gemini/Qwen CLI analysis with bug diagnosis template
   - Parses CLI output to extract root causes and fix strategy
   - Generates `IMPL-fix-N.toon` with structured task definition
   - Saves analysis report to `.process/iteration-N-analysis.md`
   - Saves raw CLI output to `.process/iteration-N-cli-output.txt`
7. **[Orchestrator]** Receives task ID from agent and inserts into queue

**Key Change**: CLI execution + result parsing + task generation are now encapsulated in @cli-planning-agent, simplifying orchestrator logic.

#### Agent Invocation Pattern (executed by orchestrator)
```javascript
Task(
  subagent_type="cli-planning-agent",
  description=`Analyze test failures and generate fix task (iteration ${currentIteration})`,
  prompt=`
    ## Context Package
    {
      "session_id": "${sessionId}",
      "iteration": ${currentIteration},
      "analysis_type": "test-failure",
      "failure_context": {
        "failed_tests": ${encodeTOON(failedTests)},
        "error_messages": ${encodeTOON(errorMessages)},
        "test_output": "${testOutputPath}",
        "pass_rate": ${passRate},
        "previous_attempts": ${encodeTOON(previousAttempts)}
      },
      "cli_config": {
        "tool": "gemini",
        "model": "gemini-3-pro-preview-11-2025",
        "template": "01-diagnose-bug-root-cause.txt",
        "timeout": 2400000,
        "fallback": "qwen"
      },
      "task_config": {
        "agent": "@test-fix-agent",
        "type": "test-fix-iteration",
        "max_iterations": ${maxIterations},
        "use_codex": false
      }
    }

    ## Your Task
    1. Execute CLI analysis using Gemini (fallback to Qwen if needed)
    2. Parse CLI output and extract fix strategy with specific modification points
    3. Generate IMPL-fix-${currentIteration}.toon using your internal task template
    4. Save analysis report to .process/iteration-${currentIteration}-analysis.md
    5. Report success and task ID back to orchestrator
  `
)
```

#### Agent Response
```javascript
{
  "status": "success",
  "task_id": "IMPL-fix-${iteration}",
  "task_path": ".workflow/${session}/.task/IMPL-fix-${iteration}.toon",
  "analysis_report": ".process/iteration-${iteration}-analysis.md",
  "cli_output": ".process/iteration-${iteration}-cli-output.txt",
  "summary": "Fix authentication token validation and null check issues",
  "modification_points_count": 2,
  "estimated_complexity": "low"
}
```

#### Generated Analysis Report Structure
The @cli-planning-agent generates `.process/iteration-N-analysis.md`:

```markdown
---
iteration: N
analysis_type: test-failure
cli_tool: gemini
model: gemini-3-pro-preview-11-2025
timestamp: 2025-11-10T10:00:00Z
pass_rate: 85.0%
---

# Test Failure Analysis - Iteration N

## Summary
- **Failed Tests**: 2
- **Pass Rate**: 85.0% (Target: 95%+)
- **Root Causes Identified**: 2
- **Modification Points**: 2

## Failed Tests Details

### test_auth_flow
- **Error**: Expected 200, got 401
- **File**: tests/test_auth.test.ts:45
- **Criticality**: high

### test_data_validation
- **Error**: TypeError: Cannot read property 'name' of undefined
- **File**: tests/test_validators.test.ts:23
- **Criticality**: medium

## Root Cause Analysis
[CLI output: 根本原因分析 section]

## Fix Strategy
[CLI output: 详细修复建议 section]

## Modification Points
- `src/auth/client.ts:sendRequest:45-50` - Add authentication token header
- `src/validators/user.ts:validateUser:23-25` - Add null check before property access

## Expected Outcome
[CLI output: 验证建议 section]

## CLI Raw Output
See: `.process/iteration-N-cli-output.txt`
```

### Phase 5: Task Queue Management

**Orchestrator maintains dynamic task queue with runtime insertions:**

#### Dynamic Queue Operations
```
Initial Queue: [IMPL-001, IMPL-002]

After IMPL-002 execution (test failures detected by orchestrator):
  [Orchestrator] Generates IMPL-fix-1.toon
  [Orchestrator] Inserts at front: [IMPL-fix-1, IMPL-002-retest, ...]

After IMPL-fix-1 execution (still failures):
  [Orchestrator] Generates IMPL-fix-2.toon
  [Orchestrator] Inserts at front: [IMPL-fix-2, IMPL-002-retest, ...]

After IMPL-fix-2 execution (success):
  [Orchestrator] Continues to: [IMPL-002-complete, ...]
```

#### Queue Priority Rules (orchestrator-managed)
1. **Fix tasks**: Inserted at queue front for immediate execution
2. **Retest tasks**: Automatically scheduled after fix tasks
3. **Regular tasks**: Standard dependency order preserved
4. **Iteration limit**: Max 5 fix iterations per test task (orchestrator enforces)

### Phase 6: Completion & Session Management

#### Success Conditions
- All initial tasks completed
- All generated fix tasks completed
- **Test pass rate === 100%** (all tests passing)
- No pending tasks in queue

#### Partial Success Conditions (NEW)
- All initial tasks completed
- Test pass rate >= 95% AND < 100%
- All failures are "low" criticality (flaky tests, env-specific issues)
- **Automatic Approval with Warning**: System auto-approves but marks session with review flag
- Note: Generate completion summary with detailed warnings about low-criticality failures

#### Completion Steps
1. **Final Validation**: Run full test suite one more time
2. **Calculate Final Pass Rate**: Parse test-results.toon
3. **Assess Completion Status**:
   - If pass_rate === 100% → Full Success
   - If pass_rate >= 95% + all "low" criticality → Partial Success (add review note)
   - If pass_rate >= 95% + any "high"/"medium" criticality → Continue iteration
   - If pass_rate < 95% → Failure
4. **Update Session State**: Mark all tasks completed (or blocked if failure)
5. **Generate Summary**: Create session completion summary with pass rate metrics
6. **Update TodoWrite**: Mark all items completed
7. **Auto-Complete**: Call `/workflow:session:complete` (for Full or Partial Success)

#### Failure Conditions
- Max iterations (5) reached without achieving 95% pass rate
- **Test pass rate < 95% after max iterations** (NEW)
- Pass rate >= 95% but critical failures exist and max iterations reached
- Unrecoverable test failures (infinite loop detection)
- Agent execution errors

#### Failure Handling
1. **Document State**: Save current iteration context with final pass rate
2. **Generate Failure Report**: Include:
   - Final pass rate (e.g., "85% after 5 iterations")
   - Remaining failures with criticality assessment
   - Iteration history and attempted fixes
   - CLI analysis quality (normal/degraded)
   - Recommendations for manual intervention
3. **Preserve Context**: Keep all iteration logs and analysis reports
4. **Mark Blocked**: Update task status to blocked
5. **Return Control**: Return to user with detailed failure report

#### Degraded Analysis Handling (NEW)
When @cli-planning-agent returns `status: "degraded"` (both Gemini and Qwen failed):
1. **Log Warning**: Record CLI analysis failure in iteration-state.toon
2. **Assess Risk**: Check if degraded analysis is acceptable:
   - If iteration < 3 AND pass_rate improved: Accept degraded analysis, continue
   - If iteration >= 3 OR pass_rate stagnant: Skip iteration, mark as blocked
3. **User Notification**: Include CLI failure in completion summary
4. **Fallback Strategy**: Use basic pattern matching from fix-history.toon

## TodoWrite Coordination

### TodoWrite Structure for Test-Execute
```javascript
TodoWrite({
  todos: [
    {
      content: "Execute IMPL-001: Generate tests [code-developer]",
      status: "completed",
      activeForm: "Executing test generation"
    },
    {
      content: "Execute IMPL-002: Test & Fix Cycle [test-fix-agent] [ITERATION]",
      status: "in_progress",
      activeForm: "Running test-fix iteration cycle"
    },
    {
      content: "  → Iteration 1: Initial test run",
      status: "completed",
      activeForm: "Running initial tests"
    },
    {
      content: "  → Iteration 2: Fix auth issues",
      status: "in_progress",
      activeForm: "Fixing authentication issues"
    },
    {
      content: "  → Iteration 3: Re-test and validate",
      status: "pending",
      activeForm: "Re-testing after fixes"
    }
  ]
});
```

### TodoWrite Update Rules
1. **Initial Tasks**: Standard task list
2. **Iteration Start**: Add nested iteration item
3. **Fix Task Added**: Add fix task as nested item
4. **Iteration Complete**: Mark iteration item completed
5. **All Complete**: Mark parent task completed

## Agent Context Package

**Generated by test-cycle-execute orchestrator before launching agents.**

The orchestrator assembles this context package from:
- Task TOON file (IMPL-*.toon)
- Iteration state files
- Test results and failure context
- Session metadata

This package is passed to agents via the Task tool's prompt context.

### Enhanced Context for Test-Fix Agent
```json
{
  "task": { /* IMPL-fix-N.toon */ },
  "iteration_context": {
    "current_iteration": N,
    "max_iterations": 5,
    "previous_attempts": [
      {
        "iteration": N-1,
        "failures": ["test1", "test2"],
        "fixes_attempted": ["fix1", "fix2"],
        "result": "partial_success"
      }
    ],
    "failure_analysis": {
      "source": "gemini_cli",
      "analysis_file": ".process/iteration-N-analysis.md",
      "fix_strategy": { /* from CLI */ }
    }
  },
  "test_context": {
    "test_framework": "jest|pytest|...",
    "test_files": ["path/to/test1.test.ts"],
    "test_command": "npm test",
    "coverage_target": 80
  },
  "session": {
    "workflow_dir": ".workflow/WFS-test-{session}/",
    "iteration_state_file": ".process/iteration-state.toon",
    "test_results_file": ".process/test-results.toon",
    "fix_history_file": ".process/fix-history.toon"
  }
}
```

## File Structure

### Test-Fix Session Files
```
.workflow/WFS-test-{session}/
├── workflow-session.toon          # Session metadata with workflow_type
├── IMPL_PLAN.md                   # Test plan
├── TODO_LIST.md                   # Progress tracking
├── .task/
│   ├── IMPL-001.toon              # Test generation task
│   ├── IMPL-002.toon              # Initial test-fix task
│   ├── IMPL-fix-1.toon            # Generated: Iteration 1 fix
│   ├── IMPL-fix-2.toon            # Generated: Iteration 2 fix
│   └── ...
├── .summaries/
│   ├── IMPL-001-summary.md
│   ├── IMPL-002-summary.md
│   └── iteration-summaries/
│       ├── iteration-1.md
│       ├── iteration-2.md
│       └── ...
└── .process/
    ├── TEST_ANALYSIS_RESULTS.md   # From planning phase
    ├── iteration-state.toon       # Current iteration state
    ├── test-results.toon          # Latest test results
    ├── test-output.log            # Full test output
    ├── fix-history.toon           # All fix attempts
    ├── iteration-1-analysis.md    # CLI analysis for iteration 1
    ├── iteration-1-failures.toon  # Failures from iteration 1
    ├── iteration-1-strategy.md    # Fix strategy for iteration 1
    ├── iteration-2-analysis.md
    └── ...
```

### Iteration State JSON
```json
{
  "session_id": "WFS-test-user-auth",
  "current_task": "IMPL-002",
  "current_iteration": 2,
  "max_iterations": 5,
  "started_at": "2025-10-17T10:00:00Z",
  "iterations": [
    {
      "iteration": 1,
      "started_at": "2025-10-17T10:05:00Z",
      "completed_at": "2025-10-17T10:15:00Z",
      "test_results": {
        "total": 10,
        "passed": 7,
        "failed": 3,
        "failures": ["test1", "test2", "test3"]
      },
      "analysis_file": ".process/iteration-1-analysis.md",
      "fix_task": "IMPL-fix-1",
      "result": "partial_success"
    }
  ],
  "status": "active",
  "next_action": "execute_fix_task"
}
```

## Agent Prompt Template

**Unified template for all agent tasks (orchestrator invokes with Task tool):**

```bash
Task(subagent_type="{meta.agent}",
     prompt="**TASK EXECUTION: {task.title}**

     ## STEP 1: Load Complete Task TOON
     **MANDATORY**: First load the complete task TOON from: {session.task_json_path}

     cat {session.task_json_path}

     **CRITICAL**: Validate all required fields present

     ## STEP 2: Task Context (From Loaded JSON)
     **ID**: {task.id}
     **Type**: {task.meta.type}
     **Agent**: {task.meta.agent}

     ## STEP 3: Execute Task Based on Type

     ### For test-gen (IMPL-001):
     - Generate tests based on TEST_ANALYSIS_RESULTS.md
     - Follow test framework conventions
     - Create test files in target_files

     ### For test-fix (IMPL-002):
     - Run test suite: {test_command}
     - Collect results to .process/test-results.toon
     - Report results to orchestrator (do NOT analyze failures)
     - Orchestrator will handle failure detection and iteration decisions
     - If success: Mark complete

     ### For test-fix-iteration (IMPL-fix-N):
     - Load fix strategy from context.fix_strategy (CONTENT, not path)
     - Apply surgical fixes to identified files
     - Return results to orchestrator
     - Do NOT run tests independently - orchestrator manages all test execution
     - Do NOT handle failures - orchestrator analyzes and decides next iteration

     ## STEP 4: Implementation Context (From JSON)
     **Requirements**: {context.requirements}
     **Fix Strategy**: {context.fix_strategy} (full content provided in task TOON)
     **Failure Context**: {context.failure_context}
     **Iteration History**: {context.inherited.iteration_history}

     ## STEP 5: Flow Control Execution
     If flow_control.pre_analysis exists, execute steps sequentially

     ## STEP 6: Agent Completion
     1. Execute task following implementation_approach
     2. Update task status in JSON
     3. Update TODO_LIST.md
     4. Generate summary in .summaries/
     5. **CRITICAL**: Save results for orchestrator to analyze

     **Output Requirements**:
     - test-results.toon: Structured test results
     - test-output.log: Full test output
     - iteration-state.toon: Current iteration state (if applicable)
     - task-summary.md: Completion summary

     **Return to Orchestrator**: Agent completes and returns. Orchestrator decides next action.
     "),
     description="Execute {task.type} task with JSON validation")
```

**Key Points**:
- Agent executes single task and returns
- Orchestrator analyzes results and decides next step
- Fix strategy content (not path) embedded in task TOON by orchestrator
- Agent does not manage iteration loop

## Error Handling & Recovery

### Iteration Failure Scenarios
| Scenario | Handling | Recovery |
|----------|----------|----------|
| Test execution error | Log error, save context | Retry with error context |
| CLI analysis failure | Fallback to Qwen, or manual analysis | Retry analysis with different tool |
| Agent execution error | Save iteration state | Retry agent with simplified context |
| Max iterations reached | Generate failure report | Mark blocked, return to user |
| Unexpected test regression | Rollback last fix | Analyze regression, add to fix strategy |

### Recovery Procedures

#### Resume from Interruption
```bash
# Load iteration state
iteration_state=$(cat .workflow/{session}/.process/iteration-state.toon)
current_iteration=$(jq -r '.current_iteration' <<< "$iteration_state")

# Determine resume point
if [[ "$(jq -r '.next_action' <<< "$iteration_state")" == "execute_fix_task" ]]; then
  # Resume fix task execution
  task_id="IMPL-fix-${current_iteration}"
else
  # Resume test execution
  task_id="IMPL-002"
fi
```

#### Rollback Failed Fix
```bash
# Revert last commit (if fixes were committed)
git revert HEAD

# Remove failed fix task
rm .workflow/{session}/.task/IMPL-fix-{N}.toon

# Restore iteration state
jq '.current_iteration -= 1' iteration-state.toon > temp.toon
mv temp.toon iteration-state.toon

# Re-run analysis with additional context
# Include failure reason in next analysis
```

## Usage Examples

### Basic Usage
```bash
# Execute test-fix workflow
/workflow:test-cycle-execute

# Resume interrupted session
/workflow:test-cycle-execute --resume-session="WFS-test-user-auth"

# Set custom iteration limit
/workflow:test-cycle-execute --max-iterations=10
```

### Integration with Planning
```bash
# 1. Plan test workflow
/workflow:test-fix-gen WFS-user-auth

# 2. Execute with dynamic iteration
/workflow:test-cycle-execute

# 3. Monitor progress
/workflow:status

# 4. Resume if interrupted
/workflow:test-cycle-execute --resume-session="WFS-test-user-auth"
```

## Best Practices

1. **Set Realistic Iteration Limits**: Default 5, increase for complex fixes
2. **Commit Between Iterations**: Easier rollback if needed
3. **Monitor Iteration Logs**: Review CLI analysis for insights
4. **Incremental Fixes**: Prefer multiple small iterations over large changes
5. **Verify No Regressions**: Check all tests pass, not just previously failing ones
6. **Preserve Context**: All iteration artifacts saved for debugging

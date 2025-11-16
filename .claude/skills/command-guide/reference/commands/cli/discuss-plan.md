---
name: discuss-plan
description: Multi-round collaborative planning using Gemini, Codex, and Claude synthesis with iterative discussion cycles (read-only, no code changes)
argument-hint: "[--topic '...'] [--task-id '...'] [--rounds N]"
allowed-tools: SlashCommand(*), Bash(*), TodoWrite(*), Read(*), Glob(*)
---

# CLI Discuss-Plan Command (/cli:discuss-plan)

## Purpose

Orchestrates a multi-model collaborative discussion for in-depth planning and problem analysis. This command facilitates an iterative dialogue between Gemini, Codex, and Claude (the orchestrating AI) to explore a topic from multiple perspectives, refine ideas, and build a robust plan.

**This command is for discussion and planning ONLY. It does NOT modify any code.**

## Core Workflow: The Discussion Loop

The command operates in iterative rounds, allowing the plan to evolve with each cycle. The user can choose to continue for more rounds or conclude when consensus is reached.

```
Topic Input → [Round 1: Gemini → Codex → Claude] → [User Review] →
[Round 2: Gemini → Codex → Claude] → ... → Final Plan
```

### Model Roles & Priority

**Priority Order**: Gemini > Codex > Claude

1.  **Gemini (The Analyst)** - Priority 1
    - Kicks off each round with deep analysis
    - Provides foundational ideas and draft plans
    - Analyzes current context or previous synthesis

2.  **Codex (The Architect/Critic)** - Priority 2
    - Reviews Gemini's output critically
    - Uses deep reasoning for technical trade-offs
    - Proposes alternative strategies
    - **Participates purely in conversational/reasoning capacity**
    - Uses resume mechanism to maintain discussion context

3.  **Claude (The Synthesizer/Moderator)** - Priority 3
    - Synthesizes discussion from Gemini and Codex
    - Highlights agreements and contentions
    - Structures refined plan
    - Poses key questions for next round

## Parameters

-   `<input>` (Required): Topic description or task ID (e.g., "Design a new caching layer" or `PLAN-002`)
-   `--rounds <N>` (Optional): Maximum number of discussion rounds (default: prompts after each round)
-   `--task-id <id>` (Optional): Associates discussion with workflow task ID
-   `--topic <description>` (Optional): High-level topic for discussion

## Execution Flow

### Phase 1: Initial Setup

1.  **Input Processing**: Parse topic or task ID
2.  **Context Gathering**: Identify relevant files based on topic

### Phase 2: Discussion Round

Each round consists of three sequential steps, tracked via `TodoWrite`.

**Step 1: Gemini's Analysis (Priority 1)**

Gemini analyzes the topic and proposes preliminary plan.

```bash
# Round 1: CONTEXT_INPUT is the initial topic
# Subsequent rounds: CONTEXT_INPUT is the synthesis from previous round
gemini -p "
PURPOSE: Analyze and propose a plan for '[topic]'
TASK: Provide initial analysis, identify key modules, and draft implementation plan
MODE: analysis
CONTEXT: @CLAUDE.md [auto-detected files]
INPUT: [CONTEXT_INPUT]
EXPECTED: Structured analysis and draft plan for discussion
RULES: Focus on technical depth and practical considerations
"
```

**Step 2: Codex's Critique (Priority 2)**

Codex reviews Gemini's output using conversational reasoning. Uses `resume --last` to maintain context across rounds.

```bash
# First round (new session)
codex --full-auto exec "
PURPOSE: Critically review technical plan
TASK: Review the provided plan, identify weaknesses, suggest alternatives, reason about trade-offs
MODE: analysis
CONTEXT: @CLAUDE.md [relevant files]
INPUT_PLAN: [Output from Gemini's analysis]
EXPECTED: Critical review with alternative ideas and risk analysis
RULES: Focus on architectural soundness and implementation feasibility
" --skip-git-repo-check

# Subsequent rounds (resume discussion)
codex --full-auto exec "
PURPOSE: Re-evaluate plan based on latest synthesis
TASK: Review updated plan and discussion points, provide further critique or refined ideas
MODE: analysis
CONTEXT: Previous discussion context (maintained via resume)
INPUT_PLAN: [Output from Gemini's analysis for current round]
EXPECTED: Updated critique building on previous discussion
RULES: Build on previous insights, avoid repeating points
" resume --last --skip-git-repo-check
```

**Step 3: Claude's Synthesis (Priority 3)**

Claude (orchestrating AI) synthesizes both outputs:

-   Summarizes Gemini's proposal and Codex's critique
-   Highlights agreements and disagreements
-   Structures consolidated plan
-   Presents open questions for next round
-   This synthesis becomes input for next round

### Phase 3: User Review and Iteration

1.  **Present Synthesis**: Show synthesized plan and key discussion points
2.  **Continue or Conclude**: Use AskUserQuestion to prompt user:

```typescript
AskUserQuestion({
  questions: [{
    question: "Round of discussion complete. What is the next step?",
    header: "Next Round",
    options: [
      { label: "Start another round", description: "Continue the discussion to refine the plan further." },
      { label: "Conclude and finalize", description: "End the discussion and save the final plan." }
    ],
    multiSelect: false
  }]
})
```

3.  **Loop or Finalize**:
    -   Continue → New round with Gemini analyzing latest synthesis
    -   Conclude → Save final synthesized document

## TodoWrite Tracking

Progress tracked for each round and model.

```javascript
// Example for 2-round discussion
TodoWrite({
  todos: [
    // Round 1
    { content: "[Round 1] Gemini: Analyzing topic", status: "completed", activeForm: "Analyzing with Gemini" },
    { content: "[Round 1] Codex: Critiquing plan", status: "completed", activeForm: "Critiquing with Codex" },
    { content: "[Round 1] Claude: Synthesizing discussion", status: "completed", activeForm: "Synthesizing discussion" },
    { content: "[User Action] Review Round 1 and decide next step", status: "in_progress", activeForm: "Awaiting user decision" },

    // Round 2
    { content: "[Round 2] Gemini: Analyzing refined plan", status: "pending", activeForm: "Analyzing refined plan" },
    { content: "[Round 2] Codex: Re-evaluating plan [resume]", status: "pending", activeForm: "Re-evaluating with Codex" },
    { content: "[Round 2] Claude: Finalizing plan", status: "pending", activeForm: "Finalizing plan" },
    { content: "Discussion complete - Final plan generated", status: "pending", activeForm: "Generating final document" }
  ]
})
```

## Output Routing

-   **Primary Log**: Entire multi-round discussion logged to single file:
    -   `.workflow/WFS-[id]/.chat/discuss-plan-[topic]-[timestamp].md`
-   **Final Plan**: Clean final version saved upon conclusion:
    -   `.workflow/WFS-[id]/.summaries/plan-[topic].md`
-   **Scratchpad**: If no session active:
    -   `.workflow/.scratchpad/discuss-plan-[topic]-[timestamp].md`

## Discussion Structure

Each round's output is structured as:

```markdown
## Round N: [Topic]

### Gemini's Analysis (Priority 1)
[Gemini's full analysis and proposal]

### Codex's Critique (Priority 2)
[Codex's critical review and alternatives]

### Claude's Synthesis (Priority 3)
**Points of Agreement:**
- [Agreement 1]
- [Agreement 2]

**Points of Contention:**
- [Issue 1]: Gemini suggests X, Codex suggests Y
- [Issue 2]: Trade-off between A and B

**Consolidated Plan:**
[Structured plan incorporating both perspectives]

**Open Questions for Next Round:**
1. [Question 1]
2. [Question 2]
```

## Examples

### Example 1: Multi-Round Architecture Discussion

**Command**: `/cli:discuss-plan --topic "Design a real-time notification system"`

**Round 1**:
1.  **Gemini**: Proposes WebSocket-based architecture with RabbitMQ message queue
2.  **Codex**: Critiques as overly complex for MVP. Suggests Server-Sent Events (SSE) for simplicity (one-way notifications). Questions RabbitMQ necessity, proposes simpler Redis Pub/Sub
3.  **Claude**: Synthesizes views:
    -   **Plan A (Gemini)**: WebSockets + RabbitMQ (highly scalable, complex)
    -   **Plan B (Codex)**: SSE + Redis (simpler, less overhead)
    -   **Open Question**: Is bi-directional communication critical, or is simplicity priority?
4.  **User Action**: Opts for another round to explore trade-offs

**Round 2**:
1.  **Gemini**: Analyzes synthesized document. Notes that if features like "user is typing" indicators are roadmapped, WebSockets better long-term. Drafts plan starting with SSE/Redis but designing for easy migration
2.  **Codex**: Reviews migration plan. Reasons that migration itself could be complex. If feature set likely to expand, starting with WebSockets using managed service might be best cost/benefit
3.  **Claude**: Synthesizes new discussion:
    -   **Consensus**: Simple SSE/Redis too short-sighted
    -   **Refined Options**:
        1.  Phased approach (SSE → WebSocket) with clear migration plan
        2.  Direct WebSocket with managed service (Pusher, Ably) to reduce ops overhead
    -   **Recommendation**: Option 2 most robust and future-proof
4.  **User Action**: Agrees with recommendation, concludes discussion

**Final Output**: Planning document saved with:
- Chosen architecture (Managed WebSocket service)
- Multi-round reasoning
- High-level implementation steps

### Example 2: Feature Design Discussion

**Command**: `/cli:discuss-plan --topic "Design user permission system" --rounds 2`

**Round 1**:
1.  **Gemini**: Proposes RBAC (Role-Based Access Control) with predefined roles
2.  **Codex**: Suggests ABAC (Attribute-Based Access Control) for more flexibility
3.  **Claude**: Synthesizes trade-offs between simplicity (RBAC) vs flexibility (ABAC)

**Round 2**:
1.  **Gemini**: Analyzes hybrid approach - RBAC for core permissions, attributes for fine-grained control
2.  **Codex**: Reviews hybrid model, identifies implementation challenges
3.  **Claude**: Final plan with phased rollout strategy

**Automatic Conclusion**: Command concludes after 2 rounds as specified

### Example 3: Problem-Solving Discussion

**Command**: `/cli:discuss-plan --topic "Debug memory leak in data pipeline" --task-id ISSUE-042`

**Round 1**:
1.  **Gemini**: Identifies potential leak sources (unclosed handles, growing cache, event listeners)
2.  **Codex**: Adds profiling tool recommendations, suggests memory monitoring
3.  **Claude**: Structures debugging plan with phased approach

**User Decision**: Single round sufficient, concludes with debugging strategy

## Consensus Mechanisms

**When to Continue:**
- Significant disagreement between models
- Open questions requiring deeper analysis
- Trade-offs need more exploration
- User wants additional perspectives

**When to Conclude:**
- Models converge on solution
- All key questions addressed
- User satisfied with plan depth
- Maximum rounds reached (if specified)

## Comparison with Other Commands

| Command | Models | Rounds | Discussion | Implementation | Use Case |
|---------|--------|--------|------------|----------------|----------|
| `/cli:mode:plan` | Gemini | 1 | NO | NO | Single-model planning |
| `/cli:analyze` | Gemini | 1 | NO | NO | Code analysis |
| `/cli:execute` | Any | 1 | NO | YES | Direct implementation |
| `/cli:codex-execute` | Codex | 1 | NO | YES | Multi-stage implementation |
| `/cli:discuss-plan` | **Gemini+Codex+Claude** | **Multiple** | **YES** | **NO** | **Multi-perspective planning** |

## Best Practices

1.  **Use for Complex Decisions**: Ideal for architectural decisions, design trade-offs, problem-solving
2.  **Start with Broad Topic**: Let first round establish scope, subsequent rounds refine
3.  **Review Each Synthesis**: Claude's synthesis is key decision point - review carefully
4.  **Know When to Stop**: Don't over-iterate - 2-3 rounds usually sufficient
5.  **Task Association**: Use `--task-id` for traceability in workflow
6.  **Save Intermediate Results**: Each round's synthesis saved automatically
7.  **Let Models Disagree**: Divergent views often reveal important trade-offs
8.  **Focus Questions**: Use Claude's open questions to guide next round

## Breaking Discussion Loops

**Detecting Loops:**
- Models repeating same arguments
- No new insights emerging
- Trade-offs well understood

**Breaking Strategies:**
1.  **User Decision**: Make executive decision when enough info gathered
2.  **Timeboxing**: Set max rounds upfront with `--rounds`
3.  **Criteria-Based**: Define decision criteria before starting
4.  **Hybrid Approach**: Accept multiple valid solutions in final plan

## Notes

-   **Pure Discussion**: This command NEVER modifies code - only produces planning documents
-   **Codex Role**: Codex participates as reasoning/critique tool, not executor
-   **Resume Context**: Codex maintains discussion context via `resume --last`
-   **Priority System**: Ensures Gemini leads analysis, Codex provides critique, Claude synthesizes
-   **Output Quality**: Multi-perspective discussion produces more robust plans than single-model analysis
-   Command patterns and session management: see intelligent-tools-strategy.md (loaded in memory)
-   For implementation after discussion, use `/cli:execute` or `/cli:codex-execute` separately

# Claude Code Workflow (CCW) - Enhanced Workflow Diagrams

Based on comprehensive analysis of changes since v1.0, this document provides detailed mermaid diagrams illustrating the CCW architecture and execution flows.

## 1. System Architecture Overview

```mermaid
graph TB
    subgraph "CLI Interface Layer"
        CLI[CLI Commands]
        GEM[Gemini CLI]
        COD[Codex CLI]
        WRAPPER[Gemini Wrapper]
    end

    subgraph "Session Management"
        MARKER[".active-session marker"]
        SESSION["workflow-session.toon"]
        WDIR[".workflow/ directories"]
    end

    subgraph "Task System"
        TASK_JSON[".task/impl-*.toon"]
        HIERARCHY["Task Hierarchy (max 2 levels)"]
        STATUS["Task Status Management"]
    end

    subgraph "Agent Orchestration"
        PLAN_AGENT[Conceptual Planning Agent]
        ACTION_AGENT[Action Planning Agent]
        CODE_AGENT[Code Developer]
        REVIEW_AGENT[Code Review Agent]
        MEMORY_AGENT[Memory Gemini Bridge]
    end

    subgraph "Template System"
        ANALYSIS_TMPL[Analysis Templates]
        DEV_TMPL[Development Templates]
        PLAN_TMPL[Planning Templates]
        REVIEW_TMPL[Review Templates]
    end

    subgraph "Output Generation"
        TODO_MD["TODO_LIST.md"]
        IMPL_MD["IMPL_PLAN.md"]
        SUMMARY[".summaries/"]
        CHAT[".chat/ sessions"]
    end

    CLI --> GEM
    CLI --> COD
    CLI --> WRAPPER
    WRAPPER --> GEM

    GEM --> PLAN_AGENT
    COD --> CODE_AGENT

    PLAN_AGENT --> TASK_JSON
    ACTION_AGENT --> TASK_JSON
    CODE_AGENT --> TASK_JSON

    TASK_JSON --> HIERARCHY
    HIERARCHY --> STATUS

    SESSION --> MARKER
    MARKER --> WDIR

    ANALYSIS_TMPL --> GEM
    DEV_TMPL --> COD
    PLAN_TMPL --> PLAN_AGENT

    TASK_JSON --> TODO_MD
    TASK_JSON --> IMPL_MD
    STATUS --> SUMMARY
    GEM --> CHAT
    COD --> CHAT
```

## 2. Command Execution Flow

```mermaid
sequenceDiagram
    participant User
    participant CLI
    participant GeminiWrapper as Gemini Wrapper
    participant GeminiCLI as Gemini CLI
    participant CodexCLI as Codex CLI
    participant Agent
    participant TaskSystem as Task System
    participant FileSystem as File System

    User->>CLI: Command Request
    CLI->>CLI: Parse Command Type

    alt Analysis Task
        CLI->>GeminiWrapper: Analysis Request
        GeminiWrapper->>GeminiWrapper: Check Token Limit
        GeminiWrapper->>GeminiWrapper: Set Approval Mode
        GeminiWrapper->>GeminiCLI: Execute Analysis
        GeminiCLI->>FileSystem: Read Codebase
        GeminiCLI->>Agent: Route to Planning Agent
    else Development Task
        CLI->>CodexCLI: Development Request
        CodexCLI->>Agent: Route to Code Agent
    end

    Agent->>TaskSystem: Create/Update Tasks
    TaskSystem->>FileSystem: Save task JSON
    Agent->>Agent: Execute Task Logic
    Agent->>FileSystem: Apply Changes
    Agent->>TaskSystem: Update Task Status
    TaskSystem->>FileSystem: Regenerate Markdown Views
    Agent->>CLI: Return Results
    CLI->>User: Display Results
```

## 3. Session Management Flow

```mermaid
stateDiagram-v2
    [*] --> SessionInit: Create New Session

    SessionInit --> CreateStructure: mkdir .workflow/WFS-session-name
    CreateStructure --> CreateTOON: Create workflow-session.toon
    CreateTOON --> CreatePlan: Create IMPL_PLAN.md
    CreatePlan --> CreateTasks: Create .task/ directory
    CreateTasks --> SetActive: touch .active-session-name

    SetActive --> Active: Session Ready

    Active --> Paused: Switch to Another Session
    Active --> Working: Execute Tasks
    Active --> Completed: All Tasks Done

    Paused --> Active: Resume Session (set marker)
    Working --> Active: Task Complete
    Completed --> [*]: Archive Session

    state Working {
        [*] --> TaskExecution
        TaskExecution --> AgentProcessing
        AgentProcessing --> TaskUpdate
        TaskUpdate --> [*]
    }
```

## 4. Task Lifecycle Management

```mermaid
graph TD
    subgraph "Task Creation"
        REQ[Requirements] --> ANALYZE{Analysis Needed?}
        ANALYZE -->|Yes| GEMINI[Gemini Analysis]
        ANALYZE -->|No| DIRECT[Direct Creation]
        GEMINI --> CONTEXT[Extract Context]
        CONTEXT --> TASK_TOON[Create impl-*.toon]
        DIRECT --> TASK_TOON
    end

    subgraph "Task Hierarchy"
        TASK_JSON --> SIMPLE{<5 Tasks?}
        SIMPLE -->|Yes| SINGLE[Single Level: impl-N]
        SIMPLE -->|No| MULTI[Two Levels: impl-N.M]

        SINGLE --> EXEC1[Direct Execution]
        MULTI --> DECOMP[Task Decomposition]
        DECOMP --> SUBTASKS[Create Subtasks]
        SUBTASKS --> EXEC2[Execute Leaf Tasks]
    end

    subgraph "Task Execution"
        EXEC1 --> AGENT_SELECT[Select Agent]
        EXEC2 --> AGENT_SELECT
        AGENT_SELECT --> PLAN_A[Planning Agent]
        AGENT_SELECT --> CODE_A[Code Agent]
        AGENT_SELECT --> REVIEW_A[Review Agent]

        PLAN_A --> UPDATE_STATUS[Update Status]
        CODE_A --> UPDATE_STATUS
        REVIEW_A --> UPDATE_STATUS

        UPDATE_STATUS --> COMPLETED{All Done?}
        COMPLETED -->|No| NEXT_TASK[Next Task]
        COMPLETED -->|Yes| SUMMARY[Generate Summary]

        NEXT_TASK --> AGENT_SELECT
        SUMMARY --> REGEN[Regenerate Views]
        REGEN --> DONE[Session Complete]
    end
```

## 5. CLI Tool Integration Architecture

```mermaid
graph TB
    subgraph "User Input Layer"
        CMD[User Commands]
        INTENT{Task Intent}
    end

    subgraph "CLI Routing Layer"
        DISPATCHER[Command Dispatcher]
        GEMINI_ROUTE[Gemini Route]
        CODEX_ROUTE[Codex Route]
    end

    subgraph "Gemini Analysis Path"
        WRAPPER[Gemini Wrapper]
        TOKEN_CHECK{Token Limit Check}
        APPROVAL_MODE[Set Approval Mode]
        GEMINI_EXEC[Gemini Execution]

        subgraph "Gemini Features"
            ALL_FILES[--all-files Mode]
            PATTERNS["@{pattern} Mode"]
            TEMPLATES[Template Integration]
        end
    end

    subgraph "Codex Development Path"
        CODEX_EXEC[Codex --full-auto exec]
        AUTO_DISCOVERY[Automatic File Discovery]
        CONTEXT_AWARE[Context-Aware Execution]

        subgraph "Codex Features"
            EXPLICIT_PATTERNS["@{pattern} Control"]
            AUTONOMOUS[Full Autonomous Mode]
            TEMPLATE_INTEGRATION[Template Support]
        end
    end

    subgraph "Backend Processing"
        FILE_ANALYSIS[File Analysis]
        CONTEXT_EXTRACTION[Context Extraction]
        CODE_GENERATION[Code Generation]
        VALIDATION[Validation & Testing]
    end

    subgraph "Output Layer"
        RESULTS[Command Results]
        ARTIFACTS[Generated Artifacts]
        DOCUMENTATION[Updated Documentation]
    end

    CMD --> INTENT
    INTENT -->|Analyze/Review/Understand| GEMINI_ROUTE
    INTENT -->|Implement/Build/Develop| CODEX_ROUTE

    GEMINI_ROUTE --> WRAPPER
    WRAPPER --> TOKEN_CHECK
    TOKEN_CHECK -->|<2M tokens| ALL_FILES
    TOKEN_CHECK -->|>2M tokens| PATTERNS
    ALL_FILES --> APPROVAL_MODE
    PATTERNS --> APPROVAL_MODE
    APPROVAL_MODE --> GEMINI_EXEC
    GEMINI_EXEC --> TEMPLATES

    CODEX_ROUTE --> CODEX_EXEC
    CODEX_EXEC --> AUTO_DISCOVERY
    AUTO_DISCOVERY --> CONTEXT_AWARE
    CONTEXT_AWARE --> AUTONOMOUS
    AUTONOMOUS --> TEMPLATE_INTEGRATION

    TEMPLATES --> FILE_ANALYSIS
    TEMPLATE_INTEGRATION --> FILE_ANALYSIS

    FILE_ANALYSIS --> CONTEXT_EXTRACTION
    CONTEXT_EXTRACTION --> CODE_GENERATION
    CODE_GENERATION --> VALIDATION
    VALIDATION --> RESULTS

    RESULTS --> ARTIFACTS
    ARTIFACTS --> DOCUMENTATION
```

## 6. Agent Workflow Coordination

```mermaid
sequenceDiagram
    participant TaskSystem as Task System
    participant PlanningAgent as Conceptual Planning
    participant ActionAgent as Action Planning
    participant CodeAgent as Code Developer
    participant ReviewAgent as Code Review
    participant MemoryAgent as Memory Bridge

    TaskSystem->>PlanningAgent: New Complex Task
    PlanningAgent->>PlanningAgent: Strategic Analysis
    PlanningAgent->>ActionAgent: High-Level Plan

    ActionAgent->>ActionAgent: Break Down into Tasks
    ActionAgent->>TaskSystem: Create Task Hierarchy
    TaskSystem->>TaskSystem: Generate impl-*.toon files

    loop For Each Implementation Task
        TaskSystem->>CodeAgent: Execute Task
        CodeAgent->>CodeAgent: Analyze Context
        CodeAgent->>CodeAgent: Generate Code
        CodeAgent->>TaskSystem: Update Status

        TaskSystem->>ReviewAgent: Review Code
        ReviewAgent->>ReviewAgent: Quality Check
        ReviewAgent->>ReviewAgent: Test Validation
        ReviewAgent->>TaskSystem: Approval/Feedback

        alt Code Needs Revision
            TaskSystem->>CodeAgent: Implement Changes
        else Code Approved
            TaskSystem->>TaskSystem: Mark Complete
        end
    end

    TaskSystem->>MemoryAgent: Update Documentation
    MemoryAgent->>MemoryAgent: Generate Summaries
    MemoryAgent->>MemoryAgent: Update README/Docs
    MemoryAgent->>TaskSystem: Documentation Complete
```

## 7. Template System Architecture

```mermaid
graph LR
    subgraph "Template Categories"
        ANALYSIS[Analysis Templates]
        DEVELOPMENT[Development Templates]
        PLANNING[Planning Templates]
        AUTOMATION[Automation Templates]
        REVIEW[Review Templates]
        INTEGRATION[Integration Templates]
    end

    subgraph "Template Files"
        ANALYSIS --> PATTERN[pattern.txt]
        ANALYSIS --> ARCH[architecture.txt]
        ANALYSIS --> SECURITY[security.txt]

        DEVELOPMENT --> FEATURE[feature.txt]
        DEVELOPMENT --> COMPONENT[component.txt]
        DEVELOPMENT --> REFACTOR[refactor.txt]

        PLANNING --> BREAKDOWN[task-breakdown.txt]
        PLANNING --> MIGRATION[migration.txt]

        AUTOMATION --> SCAFFOLD[scaffold.txt]
        AUTOMATION --> DEPLOY[deployment.txt]

        REVIEW --> CODE_REVIEW[code-review.txt]

        INTEGRATION --> API[api-design.txt]
        INTEGRATION --> DATABASE[database.txt]
    end

    subgraph "Usage Integration"
        CLI_GEMINI[Gemini CLI]
        CLI_CODEX[Codex CLI]
        AGENTS[Agent System]

        CLI_GEMINI --> ANALYSIS
        CLI_CODEX --> DEVELOPMENT
        CLI_CODEX --> AUTOMATION
        AGENTS --> PLANNING
        AGENTS --> REVIEW
        AGENTS --> INTEGRATION
    end

    subgraph "Template Resolution"
        CAT_CMD["$(cat ~/.claude/workflows/cli-templates/prompts/[category]/[template].txt)"]
        MULTI_TMPL[Multi-Template Composition]
        HEREDOC[HEREDOC Support]
    end

    PATTERN --> CAT_CMD
    FEATURE --> CAT_CMD
    BREAKDOWN --> CAT_CMD

    CAT_CMD --> MULTI_TMPL
    MULTI_TMPL --> HEREDOC
    HEREDOC --> CLI_GEMINI
    HEREDOC --> CLI_CODEX
```

## 8. Complexity Management System

```mermaid
flowchart TD
    INPUT[Task Input] --> ASSESS{Assess Complexity}

    ASSESS -->|<5 tasks| SIMPLE[Simple Workflow]
    ASSESS -->|5-15 tasks| MEDIUM[Medium Workflow]
    ASSESS -->|>15 tasks| COMPLEX[Complex Workflow]

    subgraph "Simple Workflow"
        SIMPLE_STRUCT[Single-Level: impl-N]
        SIMPLE_EXEC[Direct Execution]
        SIMPLE_MIN[Minimal Overhead]

        SIMPLE --> SIMPLE_STRUCT
        SIMPLE_STRUCT --> SIMPLE_EXEC
        SIMPLE_EXEC --> SIMPLE_MIN
    end

    subgraph "Medium Workflow"
        MEDIUM_STRUCT[Two-Level: impl-N.M]
        MEDIUM_PROGRESS[Progress Tracking]
        MEDIUM_DOCS[Auto Documentation]

        MEDIUM --> MEDIUM_STRUCT
        MEDIUM_STRUCT --> MEDIUM_PROGRESS
        MEDIUM_PROGRESS --> MEDIUM_DOCS
    end

    subgraph "Complex Workflow"
        COMPLEX_STRUCT[Deep Hierarchy]
        COMPLEX_ORCHESTRATION[Multi-Agent Orchestration]
        COMPLEX_COORD[Full Coordination]

        COMPLEX --> COMPLEX_STRUCT
        COMPLEX_STRUCT --> COMPLEX_ORCHESTRATION
        COMPLEX_ORCHESTRATION --> COMPLEX_COORD
    end

    subgraph "Dynamic Adaptation"
        RUNTIME_UPGRADE[Runtime Complexity Upgrade]
        SATURATION_CONTROL[Task Saturation Control]
        INTELLIGENT_DECOMP[Intelligent Decomposition]
    end

    SIMPLE_MIN --> RUNTIME_UPGRADE
    MEDIUM_DOCS --> RUNTIME_UPGRADE
    COMPLEX_COORD --> SATURATION_CONTROL
    SATURATION_CONTROL --> INTELLIGENT_DECOMP
```

## Key Architectural Changes Since v1.0

### Major Enhancements:
1. **Intelligent Task Saturation Control**: Prevents overwhelming agents with too many simultaneous tasks
2. **Gemini Wrapper Intelligence**: Automatic token management and approval mode detection
3. **Path-Specific Analysis**: Task-specific path management for precise CLI analysis
4. **Template System Integration**: Unified template system across all CLI tools
5. **Session Context Passing**: Proper context management for agent coordination
6. **On-Demand File Creation**: Improved performance through lazy initialization
7. **Enhanced Error Handling**: Comprehensive error logging and recovery
8. **Codex Full-Auto Mode**: Maximum autonomous development capabilities
9. **Cross-Tool Template Compatibility**: Seamless template sharing between Gemini and Codex

### Performance Improvements:
- 10-minute execution timeout for complex operations
- Sub-millisecond JSON query performance
- Atomic session switching with zero overhead
- Intelligent file discovery reducing context switching

## 9. Complete Development Workflow (Workflow vs Task Commands)

```mermaid
graph TD
    START[Project Requirement] --> SESSION["/workflow:session:start"]

    SESSION --> PLANNING_CHOICE{Choose Planning Method}

    PLANNING_CHOICE -->|Collaborative Analysis| BRAINSTORM["/workflow:brainstorm"]
    PLANNING_CHOICE -->|AI-Powered Planning| GEMINI_PLAN["/gemini:mode:plan"]
    PLANNING_CHOICE -->|Document Analysis| DOC_ANALYSIS["Document Review"]
    PLANNING_CHOICE -->|Direct Planning| DIRECT_PLAN["/workflow:plan"]

    subgraph "Brainstorming Path"
        BRAINSTORM --> SYNTHESIS["/workflow:brainstorm:synthesis"]
        SYNTHESIS --> BRAINSTORM_PLAN["/workflow:plan --from-brainstorming"]
    end

    subgraph "Gemini Planning Path"
        GEMINI_PLAN --> GEMINI_ANALYSIS["Gemini Analysis Results"]
        GEMINI_ANALYSIS --> GEMINI_WF_PLAN["/workflow:plan"]
    end

    subgraph "Document Analysis Path"
        DOC_ANALYSIS --> DOC_INSIGHTS["Extract Requirements"]
        DOC_INSIGHTS --> DOC_PLAN["/workflow:plan"]
    end

    BRAINSTORM_PLAN --> WORKFLOW_EXECUTE
    GEMINI_WF_PLAN --> WORKFLOW_EXECUTE
    DOC_PLAN --> WORKFLOW_EXECUTE
    DIRECT_PLAN --> WORKFLOW_EXECUTE

    WORKFLOW_EXECUTE["/workflow:execute"] --> TASK_CREATION["Auto-Create Tasks"]

    subgraph "Task Management Layer"
        TASK_CREATION --> TASK_BREAKDOWN["/task:breakdown"]
        TASK_BREAKDOWN --> TASK_EXECUTE["/task:execute"]
        TASK_EXECUTE --> TASK_STATUS{Task Status}

        TASK_STATUS -->|More Tasks| NEXT_TASK["/task:execute next"]
        TASK_STATUS -->|Blocked| TASK_REPLAN["/task:replan"]
        TASK_STATUS -->|Complete| TASK_DONE[Task Complete]

        NEXT_TASK --> TASK_EXECUTE
        TASK_REPLAN --> TASK_EXECUTE
    end

    TASK_DONE --> ALL_DONE{All Tasks Done?}
    ALL_DONE -->|No| TASK_EXECUTE
    ALL_DONE -->|Yes| WORKFLOW_REVIEW["/workflow:review"]

    WORKFLOW_REVIEW --> FINAL_DOCS["/update-memory-related"]
    FINAL_DOCS --> PROJECT_COMPLETE[Project Complete]
```

## 10. Workflow Command Relationships

```mermaid
graph LR
    subgraph "Session Management"
        WFS_START["/workflow:session:start"]
        WFS_RESUME["/workflow:session:resume"]
        WFS_LIST["/workflow:session:list"]
        WFS_COMPLETE["/workflow:session:complete"]

        WFS_START --> WFS_LIST
        WFS_LIST --> WFS_RESUME
        WFS_RESUME --> WFS_COMPLETE
    end

    subgraph "Planning Phase"
        WF_BRAINSTORM["/workflow:brainstorm"]
        WF_PLAN["/workflow:plan"]
        WF_PLAN_DEEP["/workflow:plan-deep"]

        WF_BRAINSTORM --> WF_PLAN
        WF_PLAN_DEEP --> WF_PLAN
    end

    subgraph "Execution Phase"
        WF_EXECUTE["/workflow:execute"]
        WF_REVIEW["/workflow:review"]

        WF_EXECUTE --> WF_REVIEW
    end

    subgraph "Task Layer"
        TASK_CREATE["/task:create"]
        TASK_BREAKDOWN["/task:breakdown"]
        TASK_EXECUTE["/task:execute"]
        TASK_REPLAN["/task:replan"]

        TASK_CREATE --> TASK_BREAKDOWN
        TASK_BREAKDOWN --> TASK_EXECUTE
        TASK_EXECUTE --> TASK_REPLAN
        TASK_REPLAN --> TASK_EXECUTE
    end

    WFS_START --> WF_BRAINSTORM
    WF_PLAN --> WF_EXECUTE
    WF_EXECUTE --> TASK_CREATE
```

## 11. Planning Method Selection Flow

```mermaid
flowchart TD
    PROJECT_START[New Project/Feature] --> COMPLEXITY{Assess Complexity}

    COMPLEXITY -->|Simple < 5 tasks| SIMPLE_FLOW
    COMPLEXITY -->|Medium 5-15 tasks| MEDIUM_FLOW
    COMPLEXITY -->|Complex > 15 tasks| COMPLEX_FLOW

    subgraph SIMPLE_FLOW["Simple Workflow"]
        S_DIRECT["/workflow:plan (direct)"]
        S_EXECUTE["/workflow:execute --type=simple"]
        S_TASKS["Direct task execution"]

        S_DIRECT --> S_EXECUTE --> S_TASKS
    end

    subgraph MEDIUM_FLOW["Medium Workflow"]
        M_CHOICE{Planning Method?}
        M_GEMINI["/gemini:mode:plan"]
        M_DOCS["Review existing docs"]
        M_PLAN["/workflow:plan"]
        M_EXECUTE["/workflow:execute --type=medium"]
        M_BREAKDOWN["/task:breakdown"]

        M_CHOICE -->|AI Planning| M_GEMINI
        M_CHOICE -->|Documentation| M_DOCS
        M_GEMINI --> M_PLAN
        M_DOCS --> M_PLAN
        M_PLAN --> M_EXECUTE
        M_EXECUTE --> M_BREAKDOWN
    end

    subgraph COMPLEX_FLOW["Complex Workflow"]
        C_BRAINSTORM["/workflow:brainstorm --perspectives=multiple"]
        C_SYNTHESIS["/workflow:brainstorm:synthesis"]
        C_PLAN_DEEP["/workflow:plan-deep"]
        C_PLAN["/workflow:plan --from-brainstorming"]
        C_EXECUTE["/workflow:execute --type=complex"]
        C_TASKS["Hierarchical task management"]

        C_BRAINSTORM --> C_SYNTHESIS
        C_SYNTHESIS --> C_PLAN_DEEP
        C_PLAN_DEEP --> C_PLAN
        C_PLAN --> C_EXECUTE
        C_EXECUTE --> C_TASKS
    end
```

## 12. Brainstorming to Execution Pipeline

```mermaid
sequenceDiagram
    participant User
    participant WF as Workflow System
    participant BS as Brainstorm Agents
    participant PLAN as Planning Agent
    participant TASK as Task System
    participant EXEC as Execution Agents

    User->>WF: /workflow:session:start "Feature Name"
    WF->>User: Session Created

    User->>BS: /workflow:brainstorm "topic" --perspectives=system-architect,security-expert
    BS->>BS: Multiple Agent Perspectives
    BS->>WF: Generate Ideas & Analysis

    User->>BS: /workflow:brainstorm:synthesis
    BS->>WF: Consolidated Recommendations

    User->>PLAN: /workflow:plan --from-brainstorming
    PLAN->>PLAN: Convert Ideas to Implementation Plan
    PLAN->>WF: Generate IMPL_PLAN.md + TODO_LIST.md

    User->>WF: /workflow:execute --type=complex
    WF->>TASK: Auto-create task hierarchy
    TASK->>TASK: Create impl-*.toon files

    loop Task Execution
        User->>EXEC: /task:execute impl-1
        EXEC->>EXEC: Execute Implementation
        EXEC->>TASK: Update task status

        alt Task needs breakdown
            EXEC->>TASK: /task:breakdown impl-1
            TASK->>TASK: Create subtasks
        else Task blocked
            EXEC->>TASK: /task:replan impl-1
            TASK->>TASK: Adjust task plan
        end
    end

    User->>WF: /workflow:review
    WF->>User: Quality validation complete

    User->>WF: /update-memory-related
    WF->>User: Documentation updated
```

## 13. Task Command Hierarchy and Dependencies

```mermaid
graph TB
    subgraph "Workflow Layer"
        WF_PLAN["/workflow:plan"]
        WF_EXECUTE["/workflow:execute"]
        WF_REVIEW["/workflow:review"]
    end

    subgraph "Task Management Layer"
        TASK_CREATE["/task:create"]
        TASK_BREAKDOWN["/task:breakdown"]
        TASK_REPLAN["/task:replan"]
    end

    subgraph "Task Execution Layer"
        TASK_EXECUTE["/task:execute"]

        subgraph "Execution Modes"
            MANUAL["--mode=guided"]
            AUTO["--mode=auto"]
        end

        subgraph "Agent Selection"
            CODE_AGENT["--agent=code-developer"]
            PLAN_AGENT["--agent=planning-agent"]
            REVIEW_AGENT["--agent=code-review-test-agent"]
        end
    end

    subgraph "Task Hierarchy"
        MAIN_TASK["impl-1 (Main Task)"]
        SUB_TASK1["impl-1.1 (Subtask)"]
        SUB_TASK2["impl-1.2 (Subtask)"]

        MAIN_TASK --> SUB_TASK1
        MAIN_TASK --> SUB_TASK2
    end

    WF_PLAN --> TASK_CREATE
    WF_EXECUTE --> TASK_CREATE
    TASK_CREATE --> TASK_BREAKDOWN
    TASK_BREAKDOWN --> MAIN_TASK
    MAIN_TASK --> SUB_TASK1
    MAIN_TASK --> SUB_TASK2

    SUB_TASK1 --> TASK_EXECUTE
    SUB_TASK2 --> TASK_EXECUTE

    TASK_EXECUTE --> MANUAL
    TASK_EXECUTE --> AUTO
    TASK_EXECUTE --> CODE_AGENT
    TASK_EXECUTE --> PLAN_AGENT
    TASK_EXECUTE --> REVIEW_AGENT

    TASK_EXECUTE --> TASK_REPLAN
    TASK_REPLAN --> TASK_BREAKDOWN
```

## 14. CLI Integration in Workflow Context

```mermaid
graph LR
    subgraph "Planning Phase CLIs"
        GEMINI_PLAN["/gemini:mode:plan"]
        GEMINI_ANALYZE["/gemini:analyze"]
        CODEX_PLAN["/codex:mode:plan"]
    end

    subgraph "Execution Phase CLIs"
        GEMINI_EXEC["/gemini:execute"]
        CODEX_AUTO["/codex:mode:auto"]
        CODEX_EXEC["/codex:execute"]
    end

    subgraph "Workflow Commands"
        WF_BRAINSTORM["/workflow:brainstorm"]
        WF_PLAN["/workflow:plan"]
        WF_EXECUTE["/workflow:execute"]
    end

    subgraph "Task Commands"
        TASK_CREATE["/task:create"]
        TASK_EXECUTE["/task:execute"]
    end

    subgraph "Context Integration"
        UPDATE_MEMORY["/update-memory-related"]
        CONTEXT["/context"]
    end

    GEMINI_PLAN --> WF_PLAN
    GEMINI_ANALYZE --> WF_BRAINSTORM
    CODEX_PLAN --> WF_PLAN

    WF_PLAN --> TASK_CREATE
    WF_EXECUTE --> TASK_EXECUTE

    TASK_EXECUTE --> GEMINI_EXEC
    TASK_EXECUTE --> CODEX_AUTO
    TASK_EXECUTE --> CODEX_EXEC

    CODEX_AUTO --> UPDATE_MEMORY
    GEMINI_EXEC --> CONTEXT

    UPDATE_MEMORY --> WF_EXECUTE
    CONTEXT --> TASK_EXECUTE
```
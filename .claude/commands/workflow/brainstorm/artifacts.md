---
name: artifacts
description: Interactive clarification generating confirmed guidance specification through role-based analysis and synthesis
argument-hint: "topic or challenge description [--count N]"
allowed-tools: TodoWrite(*), Read(*), Write(*), Glob(*)
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


## Overview

Six-phase workflow: **Automatic project context collection** → Extract topic challenges → Select roles → Generate task-specific questions → Detect conflicts → Generate confirmed guidance (declarative statements only).

**Input**: `"GOAL: [objective] SCOPE: [boundaries] CONTEXT: [background]" [--count N]`
**Output**: `.workflow/WFS-{topic}/.brainstorming/guidance-specification.md` (CONFIRMED/SELECTED format)
**Core Principle**: Questions dynamically generated from project context + topic keywords/challenges, NOT from generic templates

**Parameters**:
- `topic` (required): Topic or challenge description (structured format recommended)
- `--count N` (optional): Number of roles user WANTS to select (system will recommend N+2 options for user to choose from, default: 3)

## Task Tracking

**⚠️ TodoWrite Rule**: EXTEND auto-parallel's task list (NOT replace/overwrite)

**When called from auto-parallel**:
- Find the artifacts parent task: "Execute artifacts command for interactive framework generation"
- Mark parent task as "in_progress"
- APPEND artifacts sub-tasks AFTER the parent task (Phase 0-5)
- Mark each sub-task as it completes
- When Phase 5 completes, mark parent task as "completed"
- **PRESERVE all other auto-parallel tasks** (role agents, synthesis)

**Standalone Mode**:
```json
[
  {"content": "Initialize session (.workflow/.active-* check, parse --count parameter)", "status": "pending", "activeForm": "Initializing"},
  {"content": "Phase 0: Automatic project context collection (call context-gather)", "status": "pending", "activeForm": "Phase 0 context collection"},
  {"content": "Phase 1: Extract challenges, output 2-4 task-specific questions, wait for user input", "status": "pending", "activeForm": "Phase 1 topic analysis"},
  {"content": "Phase 2: Recommend count+2 roles, output role selection, wait for user input", "status": "pending", "activeForm": "Phase 2 role selection"},
  {"content": "Phase 3: Generate 3-4 questions per role, output and wait for answers (max 10 per round)", "status": "pending", "activeForm": "Phase 3 role questions"},
  {"content": "Phase 4: Detect conflicts, output clarifications, wait for answers (max 10 per round)", "status": "pending", "activeForm": "Phase 4 conflict resolution"},
  {"content": "Phase 5: Transform Q&A to declarative statements, write guidance-specification.md", "status": "pending", "activeForm": "Phase 5 document generation"}
]
```

## User Interaction Protocol

### Question Output Format

All questions output as structured text (detailed format with descriptions):

```markdown
【问题{N} - {短标签}】{问题文本}
a) {选项标签}
   说明：{选项说明和影响}
b) {选项标签}
   说明：{选项说明和影响}
c) {选项标签}
   说明：{选项说明和影响}

请回答：{N}a 或 {N}b 或 {N}c
```

**Multi-select format** (Phase 2 role selection):
```markdown
【角色选择】请选择 {count} 个角色参与头脑风暴分析

a) {role-name} ({中文名})
   推荐理由：{基于topic的相关性说明}
b) {role-name} ({中文名})
   推荐理由：{基于topic的相关性说明}
...

支持格式：
- 分别选择：2a 2c 2d (选择第2题的a、c、d选项)
- 合并语法：2acd (选择a、c、d)
- 逗号分隔：2a,c,d

请输入选择：
```

### Input Parsing Rules

**Supported formats** (intelligent parsing):

1. **Space-separated**: `1a 2b 3c` → Q1:a, Q2:b, Q3:c
2. **Comma-separated**: `1a,2b,3c` → Q1:a, Q2:b, Q3:c
3. **Multi-select combined**: `2abc` → Q2: options a,b,c
4. **Multi-select spaces**: `2 a b c` → Q2: options a,b,c
5. **Multi-select comma**: `2a,b,c` → Q2: options a,b,c
6. **Natural language**: `问题1选a` → 1a (fallback parsing)

**Parsing algorithm**:
- Extract question numbers and option letters
- Validate question numbers match output
- Validate option letters exist for each question
- If ambiguous/invalid, output example format and request re-input

**Error handling** (lenient):
- Recognize common variations automatically
- If parsing fails, show example and wait for clarification
- Support re-input without penalty

### Batching Strategy

**Batch limits**:
- **Default**: Maximum 10 questions per round
- **Phase 2 (role selection)**: Display all recommended roles at once (count+2 roles)
- **Auto-split**: If questions > 10, split into multiple rounds with clear round indicators

**Round indicators**:
```markdown
===== 第 1 轮问题 (共2轮) =====
【问题1 - ...】...
【问题2 - ...】...
...
【问题10 - ...】...

请回答 (格式: 1a 2b ... 10c)：
```

### Interaction Flow

**Standard flow**:
1. Output questions in formatted text
2. Output expected input format example
3. Wait for user input
4. Parse input with intelligent matching
5. If parsing succeeds → Store answers and continue
6. If parsing fails → Show error, example, and wait for re-input

**No question/option limits**: Text-based interaction removes previous 4-question and 4-option restrictions

## Execution Phases

### Session Management
- Check `.workflow/.active-*` markers first
- Multiple sessions → Prompt selection | Single → Use it | None → Create `WFS-[topic-slug]`
- Parse `--count N` parameter from user input (default: 3 if not specified)
- Store decisions in `workflow-session.toon` including count parameter

### Phase 0: Automatic Project Context Collection

**Goal**: Gather project architecture, documentation, and relevant code context BEFORE user interaction

**Detection Mechanism** (execute first):
```javascript
// Check if context-package already exists
const contextPackagePath = `.workflow/WFS-{session-id}/.process/context-package.toon`;

if (file_exists(contextPackagePath)) {
  // Validate package
  const package = Read(contextPackagePath);
  if (package.metadata.session_id === session_id) {
    console.log("✅ Valid context-package found, skipping Phase 0");
    return; // Skip to Phase 1
  }
}
```

**Implementation**: Invoke `context-search-agent` only if package doesn't exist

```javascript
Task(
  subagent_type="context-search-agent",
  description="Gather project context for brainstorm",
  prompt=`
You are executing as context-search-agent (.claude/agents/context-search-agent.md).

## Execution Mode
**BRAINSTORM MODE** (Lightweight) - Phase 1-2 only (skip deep analysis)

## Session Information
- **Session ID**: ${session_id}
- **Task Description**: ${task_description}
- **Output Path**: .workflow/${session_id}/.process/context-package.toon

## Mission
Execute complete context-search-agent workflow for implementation planning:

### Phase 1: Initialization & Pre-Analysis
1. **Detection**: Check for existing context-package (early exit if valid)
2. **Foundation**: Initialize code-index, get project structure, load docs
3. **Analysis**: Extract keywords, determine scope, classify complexity

### Phase 2: Multi-Source Context Discovery
Execute all 3 discovery tracks:
- **Track 1**: Reference documentation (CLAUDE.md, architecture docs)
- **Track 2**: Web examples (use Exa MCP for unfamiliar tech/APIs)
- **Track 3**: Codebase analysis (5-layer discovery: files, content, patterns, deps, config/tests)

### Phase 3: Synthesis, Assessment & Packaging
1. Apply relevance scoring and build dependency graph
2. Synthesize 3-source data (docs > code > web)
3. Integrate brainstorm artifacts (if .brainstorming/ exists, read content)
4. Perform conflict detection with risk assessment
5. Generate and validate context-package.toon

## Output Requirements
Complete context-package.toon with:
- **metadata**: task_description, keywords, complexity, tech_stack, session_id
- **project_context**: architecture_patterns, coding_conventions, tech_stack
- **assets**: {documentation[], source_code[], config[], tests[]} with relevance scores
- **dependencies**: {internal[], external[]} with dependency graph
- **brainstorm_artifacts**: {guidance_specification, role_analyses[], synthesis_output} with content
- **conflict_detection**: {risk_level, risk_factors, affected_modules[], mitigation_strategy}

## Quality Validation
Before completion verify:
- [ ] Valid JSON format with all required fields
- [ ] File relevance accuracy >80%
- [ ] Dependency graph complete (max 2 transitive levels)
- [ ] Conflict risk level calculated correctly
- [ ] No sensitive data exposed
- [ ] Total files ≤50 (prioritize high-relevance)

Execute autonomously following agent documentation.
Report completion with statistics.
`
)
```

**Graceful Degradation**:
- If agent fails: Log warning, continue to Phase 1 without project context
- If package invalid: Re-run context-search-agent

### Phase 1: Topic Analysis & Intent Classification

**Goal**: Extract keywords/challenges to drive all subsequent question generation, **enriched by Phase 0 project context**

**Steps**:
1. **Load Phase 0 context** (if available):
   - Read `.workflow/WFS-{session-id}/.process/context-package.toon`
   - Extract: tech_stack, existing modules, conflict_risk, relevant files

2. **Deep topic analysis** (context-aware):
   - Extract technical entities from topic + existing codebase
   - Identify core challenges considering existing architecture
   - Consider constraints (timeline/budget/compliance)
   - Define success metrics based on current project state

3. **Generate 2-4 context-aware probing questions**:
   - Reference existing tech stack in questions
   - Consider integration with existing modules
   - Address identified conflict risks from Phase 0
   - Target root challenges and trade-off priorities

4. **User interaction**: Output questions using text format (see User Interaction Protocol), wait for user input

5. **Parse user answers**: Use intelligent parsing to extract answers from user input (support multiple formats)

6. **Storage**: Store answers to `session.intent_context` with `{extracted_keywords, identified_challenges, user_answers, project_context_used}`

**Example Output**:
```markdown
===== Phase 1: 项目意图分析 =====

【问题1 - 核心挑战】实时协作平台的主要技术挑战？
a) 实时数据同步
   说明：100+用户同时在线，状态同步复杂度高
b) 可扩展性架构
   说明：用户规模增长时的系统扩展能力
c) 冲突解决机制
   说明：多用户同时编辑的冲突处理策略

【问题2 - 优先级】MVP阶段最关注的指标？
a) 功能完整性
   说明：实现所有核心功能
b) 用户体验
   说明：流畅的交互体验和响应速度
c) 系统稳定性
   说明：高可用性和数据一致性

请回答 (格式: 1a 2b)：
```

**User input examples**:
- `1a 2c` → Q1:a, Q2:c
- `1a,2c` → Q1:a, Q2:c

**⚠️ CRITICAL**: Questions MUST reference topic keywords. Generic "Project type?" violates dynamic generation.

### Phase 2: Role Selection

**⚠️ CRITICAL**: User MUST interact to select roles. NEVER auto-select without user confirmation.

**Available Roles**:
- data-architect (数据架构师)
- product-manager (产品经理)
- product-owner (产品负责人)
- scrum-master (敏捷教练)
- subject-matter-expert (领域专家)
- system-architect (系统架构师)
- test-strategist (测试策略师)
- ui-designer (UI 设计师)
- ux-expert (UX 专家)

**Steps**:
1. **Intelligent role recommendation** (AI analysis):
   - Analyze Phase 1 extracted keywords and challenges
   - Use AI reasoning to determine most relevant roles for the specific topic
   - Recommend count+2 roles (e.g., if user wants 3 roles, recommend 5 options)
   - Provide clear rationale for each recommended role based on topic context

2. **User selection** (text interaction):
   - Output all recommended roles at once (no batching needed for count+2 roles)
   - Display roles with labels and relevance rationale
   - Wait for user input in multi-select format
   - Parse user input (support multiple formats)
   - **Storage**: Store selections to `session.selected_roles`

**Example Output**:
```markdown
===== Phase 2: 角色选择 =====

【角色选择】请选择 3 个角色参与头脑风暴分析

a) system-architect (系统架构师)
   推荐理由：实时同步架构设计和技术选型的核心角色
b) ui-designer (UI设计师)
   推荐理由：协作界面用户体验和实时状态展示
c) product-manager (产品经理)
   推荐理由：功能优先级和MVP范围决策
d) data-architect (数据架构师)
   推荐理由：数据同步模型和存储方案设计
e) ux-expert (UX专家)
   推荐理由：多用户协作交互流程优化

支持格式：
- 分别选择：2a 2c 2d (选择a、c、d)
- 合并语法：2acd (选择a、c、d)
- 逗号分隔：2a,c,d (选择a、c、d)

请输入选择：
```

**User input examples**:
- `2acd` → Roles: a, c, d (system-architect, product-manager, data-architect)
- `2a 2c 2d` → Same result
- `2a,c,d` → Same result

**Role Recommendation Rules**:
- NO hardcoded keyword-to-role mappings
- Use intelligent analysis of topic, challenges, and requirements
- Consider role synergies and coverage gaps
- Explain WHY each role is relevant to THIS specific topic
- Default recommendation: count+2 roles for user to choose from

### Phase 3: Role-Specific Questions (Dynamic Generation)

**Goal**: Generate deep questions mapping role expertise to Phase 1 challenges

**Algorithm**:
```
FOR each selected role:
  1. Map Phase 1 challenges to role domain:
     - "real-time sync" + system-architect → State management pattern
     - "100 users" + system-architect → Communication protocol
     - "low latency" + system-architect → Conflict resolution

  2. Generate 3-4 questions per role probing implementation depth, trade-offs, edge cases:
     Q: "How handle real-time state sync for 100+ users?" (explores approach)
     Q: "How resolve conflicts when 2 users edit simultaneously?" (explores edge case)
     Options: [Event Sourcing/Centralized/CRDT] (concrete, explain trade-offs for THIS use case)

  3. Output questions in text format per role:
     - Display all questions for current role (3-4 questions, no 10-question limit)
     - Questions in Chinese (用中文提问)
     - Wait for user input
     - Parse answers using intelligent parsing
     - Store answers to session.role_decisions[role]
```

**Batching Strategy**:
- Each role outputs all its questions at once (typically 3-4 questions)
- No need to split per role (within 10-question batch limit)
- Multiple roles processed sequentially (one role at a time for clarity)

**Output Format**: Follow standard format from "User Interaction Protocol" section (single-choice question format)

**Example Topic-Specific Questions** (system-architect role for "real-time collaboration platform"):
- "100+ 用户实时状态同步方案?" → Options: Event Sourcing / 集中式状态管理 / CRDT
- "两个用户同时编辑冲突如何解决?" → Options: 自动合并 / 手动解决 / 版本控制
- "低延迟通信协议选择?" → Options: WebSocket / SSE / 轮询
- "系统扩展性架构方案?" → Options: 微服务 / 单体+缓存 / Serverless

**Quality Requirements**: See "Question Generation Guidelines" section for detailed rules

### Phase 4: Cross-Role Clarification (Conflict Detection)

**Goal**: Resolve ACTUAL conflicts from Phase 3 answers, not pre-defined relationships

**Algorithm**:
```
1. Analyze Phase 3 answers for conflicts:
   - Contradictory choices: product-manager "fast iteration" vs system-architect "complex Event Sourcing"
   - Missing integration: ui-designer "Optimistic updates" but system-architect didn't address conflict handling
   - Implicit dependencies: ui-designer "Live cursors" but no auth approach defined

2. FOR each detected conflict:
   Generate clarification questions referencing SPECIFIC Phase 3 choices

3. Output clarification questions in text format:
   - Batch conflicts into rounds (max 10 questions per round)
   - Display questions with context from Phase 3 answers
   - Questions in Chinese (用中文提问)
   - Wait for user input
   - Parse answers using intelligent parsing
   - Store answers to session.cross_role_decisions

4. If NO conflicts: Skip Phase 4 (inform user: "未检测到跨角色冲突，跳过Phase 4")
```

**Batching Strategy**:
- Maximum 10 clarification questions per round
- If conflicts > 10, split into multiple rounds
- Prioritize most critical conflicts first

**Output Format**: Follow standard format from "User Interaction Protocol" section (single-choice question format with background context)

**Example Conflict Detection** (from Phase 3 answers):
- **Architecture Conflict**: "CRDT 与 UI 回滚期望冲突，如何解决?"
  - Background: system-architect chose CRDT, ui-designer expects rollback UI
  - Options: 采用 CRDT / 显示合并界面 / 切换到 OT
- **Integration Gap**: "实时光标功能缺少身份认证方案"
  - Background: ui-designer chose live cursors, no auth defined
  - Options: OAuth 2.0 / JWT Token / Session-based

**Quality Requirements**: See "Question Generation Guidelines" section for conflict-specific rules

### Phase 5: Generate Guidance Specification

**Steps**:
1. Load all decisions: `intent_context` + `selected_roles` + `role_decisions` + `cross_role_decisions`
2. Transform Q&A pairs to declarative: Questions → Headers, Answers → CONFIRMED/SELECTED statements
3. Generate guidance-specification.md (template below) - **PRIMARY OUTPUT FILE**
4. Update workflow-session.toon with **METADATA ONLY**:
   - session_id (e.g., "WFS-topic-slug")
   - selected_roles[] (array of role names, e.g., ["system-architect", "ui-designer", "product-manager"])
   - topic (original user input string)
   - timestamp (ISO-8601 format)
   - phase_completed: "artifacts"
   - count_parameter (number from --count flag)
5. Validate: No interrogative sentences in .md file, all decisions traceable, no content duplication in .toon (legacy `.json` still readable)

**⚠️ CRITICAL OUTPUT SEPARATION**:
- **guidance-specification.md**: Full guidance content (decisions, rationale, integration points)
- **workflow-session.toon**: Session metadata ONLY (no guidance content, no decisions, no Q&A pairs)
- **NO content duplication**: Guidance stays in .md, metadata stays in .toon (legacy `.json` reference only when reading old sessions)

## Output Document Template

**File**: `.workflow/WFS-{topic}/.brainstorming/guidance-specification.md`

```markdown
# [Project] - Confirmed Guidance Specification

**Metadata**: [timestamp, type, focus, roles]

## 1. Project Positioning & Goals
**CONFIRMED Objectives**: [from topic + Phase 1]
**CONFIRMED Success Criteria**: [from Phase 1 answers]

## 2-N. [Role] Decisions
### SELECTED Choices
**[Question topic]**: [User's answer]
- **Rationale**: [From option description]
- **Impact**: [Implications]

### Cross-Role Considerations
**[Conflict resolved]**: [Resolution from Phase 4]
- **Affected Roles**: [Roles involved]

## Cross-Role Integration
**CONFIRMED Integration Points**: [API/Data/Auth from multiple roles]

## Risks & Constraints
**Identified Risks**: [From answers] → Mitigation: [Approach]

## Next Steps
**⚠️ Automatic Continuation** (when called from auto-parallel):
- auto-parallel will assign agents to generate role-specific analysis documents
- Each selected role gets dedicated conceptual-planning-agent
- Agents read this guidance-specification.md for framework context

## Appendix: Decision Tracking
| Decision ID | Category | Question | Selected | Phase | Rationale |
|-------------|----------|----------|----------|-------|-----------|
| D-001 | Intent | [Q] | [A] | 1 | [Why] |
| D-002 | Roles | [Selected] | [Roles] | 2 | [Why] |
| D-003+ | [Role] | [Q] | [A] | 3 | [Why] |
```

## Question Generation Guidelines

### Core Principle: Developer-Facing Questions with User Context

**Target Audience**: 开发者（理解技术但需要从用户需求出发）

**Generation Philosophy**:
1. **Phase 1**: 用户场景、业务约束、优先级（建立上下文）
2. **Phase 2**: 基于话题分析的智能角色推荐（非关键词映射）
3. **Phase 3**: 业务需求 + 技术选型（需求驱动的技术决策）
4. **Phase 4**: 技术冲突的业务权衡（帮助开发者理解影响）

### Universal Quality Rules

**Question Structure** (all phases):
```
[业务场景/需求前提] + [技术关注点]
```

**Option Structure** (all phases):
```
标签：[技术方案简称] + (业务特征)
说明：[业务影响] + [技术权衡]
```

**MUST Include** (all phases):
- ✅ All questions in Chinese (用中文提问)
- ✅ 业务场景作为问题前提
- ✅ 技术选项的业务影响说明
- ✅ 量化指标和约束条件

**MUST Avoid** (all phases):
- ❌ 纯技术选型无业务上下文
- ❌ 过度抽象的用户体验问题
- ❌ 脱离话题的通用架构问题

### Phase-Specific Requirements

**Phase 1 Requirements**:
- Questions MUST reference topic keywords (NOT generic "Project type?")
- Focus: 用户使用场景（谁用？怎么用？多频繁？）、业务约束（预算、时间、团队、合规）
- Success metrics: 性能指标、用户体验目标
- Priority ranking: MVP vs 长期规划

**Phase 3 Requirements**:
- Questions MUST reference Phase 1 keywords (e.g., "real-time", "100 users")
- Options MUST be concrete approaches with relevance to topic
- Each option includes trade-offs specific to this use case
- Include 业务需求驱动的技术问题、量化指标（并发数、延迟、可用性）

**Phase 4 Requirements**:
- Questions MUST reference SPECIFIC Phase 3 choices in background context
- Options address the detected conflict directly
- Each option explains impact on both conflicting roles
- NEVER use static "Cross-Role Matrix" - ALWAYS analyze actual Phase 3 answers
- Focus: 技术冲突的业务权衡、帮助开发者理解不同选择的影响

## Validation Checklist

Generated guidance-specification.md MUST:
- ✅ No interrogative sentences (use CONFIRMED/SELECTED)
- ✅ Every decision traceable to user answer
- ✅ Cross-role conflicts resolved or documented
- ✅ Next steps concrete and specific
- ✅ All Phase 1-4 decisions in session metadata

## Update Mechanism

```
IF guidance-specification.md EXISTS:
  Prompt: "Regenerate completely / Update sections / Cancel"
ELSE:
  Run full Phase 1-5 flow
```

## Governance Rules

**Output Requirements**:
- All decisions MUST use CONFIRMED/SELECTED (NO "?" in decision sections)
- Every decision MUST trace to user answer
- Conflicts MUST be resolved (not marked "TBD")
- Next steps MUST be actionable
- Topic preserved as authoritative reference in session

**CRITICAL**: Guidance is single source of truth for downstream phases. Ambiguity violates governance.

## Storage Validation

**workflow-session.toon** (metadata only):
```json
{
  "session_id": "WFS-{topic-slug}",
  "type": "brainstorming",
  "topic": "{original user input}",
  "selected_roles": ["system-architect", "ui-designer", "product-manager"],
  "phase_completed": "artifacts",
  "timestamp": "2025-10-24T10:30:00Z",
  "count_parameter": 3
}
```

**⚠️ Rule**: Session JSON stores ONLY metadata (session_id, selected_roles[], topic, timestamps). All guidance content goes to guidance-specification.md.

## File Structure

```
.workflow/WFS-[topic]/
├── .active-brainstorming
├── workflow-session.toon              # Session metadata ONLY
└── .brainstorming/
    └── guidance-specification.md      # Full guidance content
```

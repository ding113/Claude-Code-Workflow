# Implementation Details

Detailed implementation logic for command-guide skill operation modes.

## Architecture Overview

```
User Query
    ↓
Intent Recognition
    ↓
Mode Selection (1 of 6)
    ↓
Index/File/Reference Query
    ↓
Optional CLI Analysis (Mode 6)
    ↓
Response Formation
    ↓
User Output + Recommendations
```

---

## Intent Recognition

### Step 1: Parse User Input

Analyze query for trigger keywords and patterns:

```javascript
function recognizeIntent(userQuery) {
  const query = userQuery.toLowerCase();

  // Mode 5: Issue Reporting (highest priority)
  if (query.includes('ccw-issue') || query.includes('ccw-help') ||
      query.match(/报告.*bug/) || query.includes('功能建议')) {
    return 'ISSUE_REPORTING';
  }

  // Mode 1: Command Search
  if (query.includes('搜索') || query.includes('find') ||
      query.includes('search') || query.match(/.*相关.*命令/)) {
    return 'COMMAND_SEARCH';
  }

  // Mode 2: Recommendations
  if (query.includes('下一步') || query.includes("what's next") ||
      query.includes('推荐') || query.match(/after.*\/\w+:\w+/)) {
    return 'RECOMMENDATIONS';
  }

  // Mode 3: Documentation
  if (query.includes('参数') || query.includes('怎么用') ||
      query.includes('如何使用') || query.match(/\/\w+:\w+.*详情/)) {

    // Special case: CLI tools usage guide
    if (query.match(/cli.*工具/) || query.match(/如何.*使用.*cli/) ||
        query.match(/gemini|codex.*使用/) || query.match(/优雅.*使用/) ||
        query.includes('cli能力') || query.includes('cli特性') ||
        query.includes('语义调用') || query.includes('命令调用')) {
      return 'CLI_TOOLS_GUIDE';
    }

    return 'DOCUMENTATION';
  }

  // Mode 4: Onboarding
  if (query.includes('新手') || query.includes('入门') ||
      query.includes('getting started') || query.includes('常用命令')) {
    return 'ONBOARDING';
  }

  // Mode 6: Deep Command Analysis
  // Triggered by specific command/agent names or complexity indicators
  if (query.match(/\/\w+:\w+/) || // Contains command name pattern
      query.match(/agent.*工作|实现.*原理|命令.*细节/) || // Asks about internals
      query.includes('详细说明') || query.includes('实现细节') ||
      query.match(/对比.*命令|workflow.*对比/) || // Comparison queries
      query.match(/\w+-agent/) || // Agent name pattern
      query.includes('最佳实践') && query.match(/\w+:\w+/)) { // Best practices for specific command
    return 'DEEP_ANALYSIS';
  }

  // Default: Ask for clarification
  return 'CLARIFY';
}
```

---

## Mode 1: Command Search 🔍

### Trigger Analysis

**Keywords**: 搜索, find, search, [topic] 相关命令

**Examples**:
- "搜索 planning 命令"
- "find commands for testing"
- "实现相关的命令有哪些"

### Processing Flow

```
1. Extract Search Parameters
   ↓
2. Determine Search Type
   ├─ Keyword Search (in name/description)
   ├─ Category Search (workflow/cli/memory/task)
   └─ Use-Case Search (planning/implementation/testing)
   ↓
3. Query Appropriate Index
   ├─ Keyword → all-commands.json
   ├─ Category → by-category.json
   └─ Use-Case → by-use-case.json
   ↓
4. Filter and Rank Results
   ↓
5. Format Response
   ├─ List matching commands
   ├─ Show key metadata (name, description, args)
   └─ Suggest related commands
```

### Implementation

```javascript
async function searchCommands(query, searchType) {
  let results = [];

  switch (searchType) {
    case 'keyword':
      // Load all-commands.json
      const allCommands = await readIndex('all-commands.json');
      results = allCommands.filter(cmd =>
        cmd.name.toLowerCase().includes(query.toLowerCase()) ||
        cmd.description.toLowerCase().includes(query.toLowerCase())
      );
      break;

    case 'category':
      // Load by-category.json
      const byCategory = await readIndex('by-category.json');
      const category = extractCategory(query); // e.g., "workflow"
      results = flattenCategory(byCategory[category]);
      break;

    case 'use-case':
      // Load by-use-case.json
      const byUseCase = await readIndex('by-use-case.json');
      const useCase = extractUseCase(query); // e.g., "planning"
      results = byUseCase[useCase] || [];
      break;
  }

  // Rank by relevance
  results = rankResults(results, query);

  // Add related commands
  results = await enrichWithRelated(results);

  return results;
}
```

---

## Mode 2: Smart Recommendations 🤖

### Trigger Analysis

**Keywords**: 下一步, what's next, 推荐, after [command]

**Examples**:
- "执行完 /workflow:plan 后做什么？"
- "What's next after planning?"
- "推荐下一个命令"

### Processing Flow

```
1. Extract Context
   ├─ Current/Last Command
   ├─ Workflow State
   └─ User's Current Task
   ↓
2. Query Relationships
   └─ Load command-relationships.json
   ↓
3. Find Next Steps
   ├─ Check next_steps array
   ├─ Consider prerequisites
   └─ Check related_commands
   ↓
4. Generate Recommendations
   ├─ Primary recommendation (most common next step)
   ├─ Alternative options
   └─ Rationale for each
   ↓
5. Add Workflow Context
   └─ Link to workflow-patterns.md
```

### Implementation

```javascript
async function getRecommendations(currentCommand) {
  // Load relationships
  const relationships = await readIndex('command-relationships.json');

  // Get relationship data
  const cmdData = relationships[currentCommand];

  if (!cmdData) {
    return defaultRecommendations();
  }

  // Primary next steps
  const nextSteps = cmdData.next_steps || [];

  // Alternative related commands
  const alternatives = cmdData.related_commands || [];

  // Build recommendations
  const recommendations = {
    primary: await enrichCommand(nextSteps[0]),
    alternatives: await enrichCommands(alternatives),
    workflow_pattern: findWorkflowPattern(currentCommand),
    rationale: generateRationale(currentCommand, nextSteps[0])
  };

  return recommendations;
}
```

---

## Mode 3: Full Documentation 📖

### Trigger Analysis

**Keywords**: 参数, 怎么用, 如何使用, [command] 详情

**Examples**:
- "/workflow:plan 的参数是什么？"
- "如何使用 /cli:execute？"
- "task:create 详细文档"

**Special Case - CLI Tools Guide**:
**Keywords**: cli工具, 如何使用cli, gemini/codex使用, 优雅使用, cli能力, cli特性, 语义调用, 命令调用

**Examples**:
- "如何优雅的使用cli工具"
- "cli工具能做什么"
- "gemini和codex的区别"
- "语义调用是什么"

### Processing Flow

```
1. Extract Command Name
   └─ Parse /workflow:plan or workflow:plan
   ↓
2. Locate in Index
   └─ Search all-commands.json
   ↓
3. Read Full Command File
   └─ Use file_path from index
   ↓
4. Extract Documentation
   ├─ Parameters section
   ├─ Arguments specification
   ├─ Examples section
   └─ Best practices
   ↓
5. Format Response
   ├─ Command overview
   ├─ Full parameter list
   ├─ Usage examples
   └─ Related commands
```

### Implementation

```javascript
async function getDocumentation(commandName, queryType = 'DOCUMENTATION') {
  // Special case: CLI tools usage guide
  if (queryType === 'CLI_TOOLS_GUIDE') {
    const guideContent = await readFile('guides/cli-tools-guide.md');
    return {
      type: 'CLI_TOOLS_GUIDE',
      title: 'CLI 工具使用指南',
      content: guideContent,
      sections: {
        introduction: extractSection(guideContent, '## 🎯 快速理解'),
        comparison: extractSection(guideContent, '## 📋 三大工具能力对比'),
        how_to_use: extractSection(guideContent, '## 🚀 如何调用'),
        capabilities: extractSection(guideContent, '## 💡 能力特性清单'),
        scenarios: extractSection(guideContent, '## 🔄 典型使用场景'),
        quick_reference: extractSection(guideContent, '## 📚 快速参考'),
        faq: extractSection(guideContent, '## 🆘 常见问题')
      },
      related_docs: [
        'intelligent-tools-strategy.md',
        'workflow-patterns.md',
        'getting-started.md'
      ]
    };
  }

  // Normal command documentation
  // Normalize command name
  const normalized = normalizeCommandName(commandName);

  // Find in index
  const allCommands = await readIndex('all-commands.json');
  const command = allCommands.find(cmd => cmd.name === normalized);

  if (!command) {
    return { error: 'Command not found' };
  }

  // Read full command file
  const commandFilePath = path.join(
    '../commands',
    command.file_path
  );
  const fullDoc = await readCommandFile(commandFilePath);

  // Parse sections
  const documentation = {
    name: command.name,
    description: command.description,
    arguments: command.arguments,
    difficulty: command.difficulty,
    usage_scenario: command.usage_scenario,
    parameters: extractSection(fullDoc, '## Parameters'),
    examples: extractSection(fullDoc, '## Examples'),
    best_practices: extractSection(fullDoc, '## Best Practices'),
    related: await getRelatedCommands(command.name)
  };

  return documentation;
}
```

---

## Mode 4: Beginner Onboarding 🎓

### Trigger Analysis

**Keywords**: 新手, 入门, getting started, 常用命令, 如何开始

**Examples**:
- "我是新手，如何开始？"
- "getting started with workflows"
- "最常用的命令有哪些？"

### Processing Flow

```
1. Assess User Level
   └─ Identify as beginner
   ↓
2. Load Essential Commands
   └─ Read essential-commands.json
   ↓
3. Build Learning Path
   ├─ Step 1: Core commands (Top 5)
   ├─ Step 2: Basic workflow
   ├─ Step 3: Intermediate commands
   └─ Step 4: Advanced features
   ↓
4. Provide Resources
   ├─ Link to getting-started.md
   ├─ Link to workflow-patterns.md
   └─ Suggest first task
   ↓
5. Interactive Guidance
   └─ Offer to walk through first workflow
```

### Implementation

```javascript
async function onboardBeginner() {
  // Load essential commands
  const essentialCommands = await readIndex('essential-commands.json');

  // Group by difficulty
  const beginner = essentialCommands.filter(cmd =>
    cmd.difficulty === 'Beginner' || cmd.difficulty === 'Intermediate'
  );

  // Create learning path
  const learningPath = {
    step1: {
      title: 'Core Commands (Start Here)',
      commands: beginner.slice(0, 5),
      guide: 'guides/getting-started.md'
    },
    step2: {
      title: 'Your First Workflow',
      pattern: 'Plan → Execute',
      commands: ['workflow:plan', 'workflow:execute'],
      guide: 'guides/workflow-patterns.md#basic-workflow'
    },
    step3: {
      title: 'Intermediate Skills',
      commands: beginner.slice(5, 10),
      guide: 'guides/workflow-patterns.md#common-patterns'
    }
  };

  // Resources
  const resources = {
    getting_started: 'guides/getting-started.md',
    workflow_patterns: 'guides/workflow-patterns.md',
    cli_tools: 'guides/cli-tools-guide.md',
    troubleshooting: 'guides/troubleshooting.md'
  };

  return {
    learning_path: learningPath,
    resources: resources,
    first_task: 'Try: /workflow:plan "create a simple feature"'
  };
}
```

---

## Mode 5: Issue Reporting 📝

### Trigger Analysis

**Keywords**: CCW-issue, CCW-help, 报告 bug, 功能建议, 问题咨询

**Examples**:
- "CCW-issue"
- "我要报告一个 bug"
- "CCW-help 有问题"
- "想提个功能建议"

### Processing Flow

```
1. Detect Issue Type
   └─ Use AskUserQuestion if unclear
   ↓
2. Select Template
   ├─ Bug → templates/issue-bug.md
   ├─ Feature → templates/issue-feature.md
   └─ Question → templates/issue-question.md
   ↓
3. Collect Information
   └─ Interactive Q&A
      ├─ Problem description
      ├─ Steps to reproduce (bug)
      ├─ Expected vs actual (bug)
      ├─ Use case (feature)
      └─ Context
   ↓
4. Generate Filled Template
   └─ Populate template with collected data
   ↓
5. Save or Display
   ├─ Save to templates/.generated/
   └─ Display for user to copy
```

### Implementation

```javascript
async function reportIssue(issueType) {
  // Determine type (bug/feature/question)
  if (!issueType) {
    issueType = await askUserQuestion({
      question: 'What type of issue would you like to report?',
      options: ['Bug Report', 'Feature Request', 'Question']
    });
  }

  // Select template
  const templatePath = {
    'bug': 'templates/issue-bug.md',
    'feature': 'templates/issue-feature.md',
    'question': 'templates/issue-question.md'
  }[issueType.toLowerCase()];

  const template = await readTemplate(templatePath);

  // Collect information
  const info = await collectIssueInfo(issueType);

  // Fill template
  const filledTemplate = fillTemplate(template, {
    ...info,
    timestamp: new Date().toISOString(),
    auto_context: gatherAutoContext()
  });

  // Save
  const outputPath = `templates/.generated/${issueType}-${Date.now()}.md`;
  await writeFile(outputPath, filledTemplate);

  return {
    template: filledTemplate,
    file_path: outputPath,
    instructions: 'Copy content to GitHub Issues or use: gh issue create -F ' + outputPath
  };
}
```

---

## Mode 6: Deep Command Analysis 🔬

**Path Configuration Note**:
This mode uses absolute paths (`~/.claude/skills/command-guide/reference`) to ensure the skill works correctly regardless of where it's installed. The skill is designed to be installed in `~/.claude/skills/` (user's global Claude configuration directory).

### Trigger Analysis

**Keywords**: 详细说明, 命令原理, agent 如何工作, 实现细节, 对比命令, 最佳实践

**Examples**:
- "action-planning-agent 如何工作？"
- "/workflow:plan 的实现原理是什么？"
- "对比 workflow:plan 和 workflow:tdd-plan"
- "ui-design-agent 详细说明"

### Processing Flow

```
1. Parse Query
   ├─ Identify target command(s)/agent(s)
   ├─ Determine query complexity
   └─ Extract specific questions
   ↓
2. Classify Query Type
   ├─ Simple: Single entity, basic explanation
   └─ Complex: Multi-entity comparison, best practices, workflows
   ↓
3. Simple Query Path
   ├─ Locate file in reference/
   ├─ Read markdown content
   ├─ Extract relevant sections
   └─ Format response
   ↓
4. Complex Query Path
   ├─ Identify all relevant files
   ├─ Construct CLI analysis prompt
   ├─ Execute gemini analysis
   └─ Return comprehensive results
   ↓
5. Response Enhancement
   ├─ Add usage examples
   ├─ Link to related docs
   └─ Suggest next steps
```

### Query Classification Logic

```javascript
function classifyDeepAnalysisQuery(query) {
  const complexityIndicators = {
    multiEntity: query.match(/对比|比较|区别/) && query.match(/(\/\w+:\w+.*){2,}/),
    bestPractices: query.includes('最佳实践') || query.includes('推荐用法'),
    workflowAnalysis: query.match(/工作流.*分析|流程.*说明/),
    architecturalDepth: query.includes('架构') || query.includes('设计思路'),
    crossReference: query.match(/和.*一起用|配合.*使用/)
  };

  const isComplex = Object.values(complexityIndicators).some(v => v);

  return {
    isComplex,
    indicators: complexityIndicators,
    requiresCLI: isComplex
  };
}
```

### Simple Query Implementation

```javascript
async function handleSimpleQuery(query) {
  // Extract entity name (command or agent)
  const entityName = extractEntityName(query); // e.g., "action-planning-agent" or "workflow:plan"

  // Determine if command or agent
  const isAgent = entityName.includes('-agent') || entityName.includes('agent');
  const isCommand = entityName.includes(':') || entityName.startsWith('/');

  // Base path for reference documentation
  const basePath = '~/.claude/skills/command-guide/reference';

  let filePath;
  if (isAgent) {
    // Agent query - use absolute path
    const agentFileName = entityName.replace(/^\//, '').replace(/-agent$/, '-agent');
    filePath = `${basePath}/agents/${agentFileName}.md`;
  } else if (isCommand) {
    // Command query - need to find in command hierarchy
    const cmdName = entityName.replace(/^\//, '');
    filePath = await locateCommandFile(cmdName, basePath);
  }

  // Read documentation
  const docContent = await readFile(filePath);

  // Extract relevant sections based on query keywords
  const sections = extractRelevantSections(docContent, query);

  // Format response
  return {
    entity: entityName,
    type: isAgent ? 'agent' : 'command',
    documentation: sections,
    full_path: filePath,
    related: await findRelatedEntities(entityName)
  };
}

async function locateCommandFile(commandName, basePath) {
  // Parse command category from name
  // e.g., "workflow:plan" → "~/.claude/skills/command-guide/reference/commands/workflow/plan.md"
  const [category, name] = commandName.split(':');

  // Search in reference/commands hierarchy using absolute paths
  const possiblePaths = [
    `${basePath}/commands/${category}/${name}.md`,
    `${basePath}/commands/${category}/${name}/*.md`,
    `${basePath}/commands/${name}.md`
  ];

  for (const path of possiblePaths) {
    if (await fileExists(path)) {
      return path;
    }
  }

  throw new Error(`Command file not found: ${commandName}`);
}

function extractRelevantSections(markdown, query) {
  // Parse markdown into sections
  const sections = parseMarkdownSections(markdown);

  // Determine which sections are relevant
  const keywords = extractKeywords(query);
  const relevantSections = {};

  // Always include overview/description
  if (sections['## Overview'] || sections['## Description']) {
    relevantSections.overview = sections['## Overview'] || sections['## Description'];
  }

  // Include specific sections based on keywords
  if (keywords.includes('参数') || keywords.includes('参数说明')) {
    relevantSections.parameters = sections['## Parameters'] || sections['## Arguments'];
  }

  if (keywords.includes('例子') || keywords.includes('示例') || keywords.includes('example')) {
    relevantSections.examples = sections['## Examples'] || sections['## Usage'];
  }

  if (keywords.includes('工作流') || keywords.includes('流程')) {
    relevantSections.workflow = sections['## Workflow'] || sections['## Process Flow'];
  }

  if (keywords.includes('最佳实践') || keywords.includes('建议')) {
    relevantSections.best_practices = sections['## Best Practices'] || sections['## Recommendations'];
  }

  return relevantSections;
}
```

### Complex Query Implementation (CLI-Assisted)

```javascript
async function handleComplexQuery(query, classification) {
  // Identify all entities mentioned in query
  const entities = extractAllEntities(query); // Returns array of command/agent names

  // Build file context for CLI analysis
  const contextPaths = [];
  for (const entity of entities) {
    const path = await resolveEntityPath(entity);
    contextPaths.push(path);
  }

  // Construct CLI prompt based on query type
  const prompt = buildCLIPrompt(query, classification, contextPaths);

  // Execute CLI analysis
  const cliResult = await executeCLIAnalysis(prompt);

  return {
    query_type: 'complex',
    analysis_method: 'CLI-assisted (gemini)',
    entities_analyzed: entities,
    result: cliResult,
    source_files: contextPaths
  };
}

function buildCLIPrompt(userQuery, classification, contextPaths) {
  // Extract key question
  const question = extractCoreQuestion(userQuery);

  // Build context reference
  const contextRef = contextPaths.map(p => `@${p}`).join(' ');

  // Determine analysis focus based on classification
  let taskDescription = '';
  if (classification.indicators.multiEntity) {
    taskDescription = `• Compare the entities mentioned in terms of:
  - Use cases and scenarios
  - Capabilities and features
  - When to use each
  - Workflow integration
• Provide side-by-side comparison
• Recommend usage guidelines`;
  } else if (classification.indicators.bestPractices) {
    taskDescription = `• Analyze best practices for the mentioned entities
• Provide practical usage recommendations
• Include common pitfalls to avoid
• Show example workflows`;
  } else if (classification.indicators.workflowAnalysis) {
    taskDescription = `• Trace the workflow execution
• Explain process flow and dependencies
• Identify key integration points
• Provide usage examples`;
  } else {
    taskDescription = `• Provide comprehensive analysis
• Explain implementation details
• Show practical examples
• Include related concepts`;
  }

  // Construct full prompt using Standard Template
  // Note: CONTEXT uses @**/* because we'll use --include-directories to specify the reference path
  return `PURPOSE: Analyze command/agent documentation to provide comprehensive answer to user query
TASK:
${taskDescription}
MODE: analysis
CONTEXT: @**/*
EXPECTED: Comprehensive answer with examples, comparisons, and recommendations in markdown format
RULES: $(cat ~/.claude/workflows/cli-templates/prompts/analysis/02-analyze-code-patterns.txt) | Focus on practical usage and real-world scenarios | analysis=READ-ONLY

User Question: ${question}`;
}

async function executeCLIAnalysis(prompt) {
  // Use absolute path for reference directory
  // This ensures the command works regardless of where the skill is installed
  const referencePath = '~/.claude/skills/command-guide/reference';

  // Execute gemini with analysis prompt using --include-directories
  // This allows gemini to access reference docs while maintaining correct file context
  const command = `gemini -p "${escapePrompt(prompt)}" -m gemini-3-pro-preview-11-2025 --include-directories ${referencePath}`;

  try {
    const result = await execBash(command, { timeout: 120000 }); // 2 min timeout
    return parseAnalysisResult(result.stdout);
  } catch (error) {
    console.error('Gemini analysis failed:', error);
    throw error;
  }
}

function parseAnalysisResult(rawOutput) {
  // Extract main content from CLI output
  // Remove CLI wrapper/metadata, keep analysis content
  const lines = rawOutput.split('\n');
  const contentStart = lines.findIndex(l => l.trim().startsWith('#') || l.length > 50);
  const content = lines.slice(contentStart).join('\n');

  return {
    raw: rawOutput,
    parsed: content,
    format: 'markdown'
  };
}
```

### Helper Functions

```javascript
function extractEntityName(query) {
  // Extract command name pattern: /workflow:plan or workflow:plan
  const cmdMatch = query.match(/\/?(\w+:\w+)/);
  if (cmdMatch) return cmdMatch[1];

  // Extract agent name pattern: action-planning-agent or action planning agent
  const agentMatch = query.match(/(\w+(?:-\w+)*-agent|\w+\s+agent)/);
  if (agentMatch) return agentMatch[1].replace(/\s+/g, '-');

  return null;
}

function extractAllEntities(query) {
  const entities = [];

  // Find all command patterns
  const commands = query.match(/\/?(\w+:\w+)/g);
  if (commands) {
    entities.push(...commands.map(c => c.replace('/', '')));
  }

  // Find all agent patterns
  const agents = query.match(/(\w+(?:-\w+)*-agent)/g);
  if (agents) {
    entities.push(...agents);
  }

  return [...new Set(entities)]; // Deduplicate
}

async function resolveEntityPath(entityName) {
  // Base path for reference documentation
  const basePath = '~/.claude/skills/command-guide/reference';
  const isAgent = entityName.includes('-agent');

  if (isAgent) {
    // Return relative path within reference directory (used for @context in CLI)
    return `agents/${entityName}.md`;
  } else {
    // Command - need to find in hierarchy
    const [category] = entityName.split(':');
    // Use glob to find the file (glob pattern uses absolute path)
    const matches = await glob(`${basePath}/commands/${category}/**/${entityName.split(':')[1]}.md`);
    if (matches.length > 0) {
      // Return relative path within reference directory
      return matches[0].replace(`${basePath}/`, '');
    }
    throw new Error(`Entity file not found: ${entityName}`);
  }
}

function extractCoreQuestion(query) {
  // Remove common prefixes
  const cleaned = query
    .replace(/^(请|帮我|能否|可以)/g, '')
    .replace(/^(ccw|CCW)[:\s]*/gi, '')
    .trim();

  // Ensure it ends with question mark if it's interrogative
  if (cleaned.match(/什么|如何|为什么|怎么|哪个/) && !cleaned.endsWith('?') && !cleaned.endsWith('？')) {
    return cleaned + '？';
  }

  return cleaned;
}

function escapePrompt(prompt) {
  // Escape special characters for bash
  return prompt
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\$/g, '\\$')
    .replace(/`/g, '\\`');
}
```

### Example Outputs

**Simple Query Example**:
```javascript
// Input: "action-planning-agent 如何工作？"
{
  entity: "action-planning-agent",
  type: "agent",
  documentation: {
    overview: "# Action Planning Agent\n\nGenerates structured task plans...",
    workflow: "## Workflow\n1. Analyze requirements\n2. Break down into tasks...",
    examples: "## Examples\n```bash\n/workflow:plan --agent \"feature\"\n```"
  },
  full_path: "~/.claude/skills/command-guide/reference/agents/action-planning-agent.md",
  related: ["workflow:plan", "task:create", "conceptual-planning-agent"]
}
```

**Complex Query Example**:
```javascript
// Input: "对比 workflow:plan 和 workflow:tdd-plan 的使用场景和最佳实践"
{
  query_type: "complex",
  analysis_method: "CLI-assisted (gemini)",
  entities_analyzed: ["workflow:plan", "workflow:tdd-plan"],
  result: {
    parsed: `# 对比分析: workflow:plan vs workflow:tdd-plan

## 使用场景对比

### workflow:plan
- **适用场景**: 通用功能开发，无特殊测试要求
- **特点**: 灵活的任务分解，focus on implementation
...

### workflow:tdd-plan
- **适用场景**: 测试驱动开发，需要严格测试覆盖
- **特点**: Red-Green-Refactor 循环，test-first
...

## 最佳实践

### workflow:plan 最佳实践
1. 先分析需求，明确目标
2. 合理分解任务，避免过大或过小
...

### workflow:tdd-plan 最佳实践
1. 先写测试，明确预期行为
2. 保持 Red-Green-Refactor 节奏
...

## 选择建议

| 情况 | 推荐命令 |
|------|----------|
| 新功能开发，无特殊测试要求 | workflow:plan |
| 核心模块，需要高测试覆盖 | workflow:tdd-plan |
| 快速原型，验证想法 | workflow:plan |
| 关键业务逻辑 | workflow:tdd-plan |
`,
    format: "markdown"
  },
  source_files: [
    "~/.claude/skills/command-guide/reference/commands/workflow/plan.md",
    "~/.claude/skills/command-guide/reference/commands/workflow/tdd-plan.md"
  ]
}
```

---

## Error Handling

### Not Found
```javascript
if (results.length === 0) {
  return {
    message: 'No commands found matching your query.',
    suggestions: [
      'Try broader keywords',
      'Browse by category: workflow, cli, memory, task',
      'View all commands: essential-commands.json',
      'Need help? Ask: "CCW-help"'
    ]
  };
}
```

### Ambiguous Intent
```javascript
if (intent === 'CLARIFY') {
  return await askUserQuestion({
    question: 'What would you like to do?',
    options: [
      'Search for commands',
      'Get recommendations for next steps',
      'View command documentation',
      'Learn how to get started',
      'Report an issue or get help'
    ]
  });
}
```

---

## Optimization Strategies

### Caching
```javascript
// Cache indexes in memory after first load
const indexCache = new Map();

async function readIndex(filename) {
  if (indexCache.has(filename)) {
    return indexCache.get(filename);
  }

  const data = await readFile(`index/${filename}`);
  const parsed = JSON.parse(data);
  indexCache.set(filename, parsed);
  return parsed;
}
```

### Lazy Loading
```javascript
// Only load full command files when needed
// Use index metadata for most queries
// Read command file only for Mode 3 (Documentation)
```

---

**Last Updated**: 2025-11-06

**Version**: 1.3.0 - Added Mode 6: Deep Command Analysis with reference documentation backup and CLI-assisted complex queries

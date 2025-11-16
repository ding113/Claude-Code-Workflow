---
name: layout-extract
description: Extract structural layout information from reference images, URLs, or text prompts using Claude analysis with variant generation or refinement mode
argument-hint: [--design-id <id>] [--session <id>] [--images "<glob>"] [--urls "<list>"] [--prompt "<desc>"] [--targets "<list>"] [--variants <count>] [--device-type <desktop|mobile|tablet|responsive>] [--interactive] [--refine]
allowed-tools: TodoWrite(*), Read(*), Write(*), Glob(*), Bash(*), AskUserQuestion(*), Task(ui-design-agent), mcp__exa__web_search_exa(*)
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Layout Extraction Command

## Overview

Extract structural layout information from reference images, URLs, or text prompts using AI analysis. Supports two modes:
1. **Exploration Mode** (default): Generate multiple contrasting layout variants
2. **Refinement Mode** (`--refine`): Refine a single existing layout through detailed adjustments

This command separates the "scaffolding" (HTML structure and CSS layout) from the "paint" (visual tokens handled by `style-extract`).

**Strategy**: AI-Driven Structural Analysis

- **Agent-Powered**: Uses `ui-design-agent` for deep structural analysis
- **Dual Mode**: Exploration (multiple contrasting variants) or Refinement (single layout fine-tuning)
- **Output**: `layout-templates.toon` with DOM structure, component hierarchy, and CSS layout rules
- **Device-Aware**: Optimized for specific device types (desktop, mobile, tablet, responsive)
- **Token-Based**: CSS uses `var()` placeholders for spacing and breakpoints

## Phase 0: Setup & Input Validation

### Step 1: Detect Input, Mode & Targets

```bash
# Detect input source
# Priority: --urls + --images → hybrid | --urls → url | --images → image | --prompt → text

# Parse URLs if provided (format: "target:url,target:url,...")
IF --urls:
    url_list = []
    FOR pair IN split(--urls, ","):
        IF ":" IN pair:
            target, url = pair.split(":", 1)
            url_list.append({target: target.strip(), url: url.strip()})
        ELSE:
            # Single URL without target
            url_list.append({target: "page", url: pair.strip()})

    has_urls = true
ELSE:
    has_urls = false
    url_list = []

# Detect refinement mode
refine_mode = --refine OR false

# Set variants count
# Refinement mode: Force variants_count = 1 (ignore user-provided --variants)
# Exploration mode: Use --variants or default to 3 (range: 1-5)
IF refine_mode:
    variants_count = 1
    REPORT: "🔧 Refinement mode enabled: Will generate 1 refined layout per target"
ELSE:
    variants_count = --variants OR 3
    VALIDATE: 1 <= variants_count <= 5
    REPORT: "🔍 Exploration mode: Will generate {variants_count} contrasting layout concepts per target"

# Resolve targets
# Priority: --targets → url_list targets → prompt analysis → default ["page"]
IF --targets:
    targets = split(--targets, ",")
ELSE IF has_urls:
    targets = [url_info.target for url_info in url_list]
ELSE IF --prompt:
    # Extract targets from prompt using pattern matching
    # Looks for keywords: "page names", target descriptors (login, dashboard, etc.)
    # Returns lowercase, hyphenated strings (e.g., ["login", "dashboard"])
    targets = extract_from_prompt(--prompt)
ELSE:
    targets = ["page"]

# Resolve device type
device_type = --device-type OR "responsive"  # desktop|mobile|tablet|responsive

# Determine base path with priority: --design-id > --session > auto-detect
if [ -n "$DESIGN_ID" ]; then
  # Exact match by design ID
  relative_path=$(find .workflow -name "${DESIGN_ID}" -type d -print -quit)
elif [ -n "$SESSION_ID" ]; then
  # Latest in session
  relative_path=$(find .workflow/WFS-$SESSION_ID -name "design-run-*" -type d -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2)
else
  # Latest globally
  relative_path=$(find .workflow -name "design-run-*" -type d -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2)
fi

# Validate and convert to absolute path
if [ -z "$relative_path" ] || [ ! -d "$relative_path" ]; then
  echo "❌ ERROR: Design run not found"
  echo "💡 HINT: Run '/workflow:ui-design:list' to see available design runs"
  exit 1
fi

base_path=$(cd "$relative_path" && pwd)
bash(echo "✓ Base path: $base_path")
```

### Step 2: Load Inputs & Create Directories
```bash
# For image mode
bash(ls {images_pattern})  # Expand glob pattern
Read({image_path})  # Load each image

# For URL mode
# Parse URL list format: "target:url,target:url"
# Validate URLs are accessible

# For text mode
# Validate --prompt is non-empty

# Create output directory
bash(mkdir -p {base_path}/layout-extraction)
```

### Step 2.5: Extract DOM Structure (URL Mode - Auto-Trigger)
```bash
# AUTO-TRIGGER: If URLs are available (from --urls parameter), automatically extract real DOM structure
# This provides accurate layout data to supplement visual analysis

# Check if URLs provided via --urls parameter
IF --urls AND url_list:
    REPORT: "🔍 Auto-triggering URL mode: Extracting DOM structure"

    bash(mkdir -p {base_path}/.intermediates/layout-analysis)

    # For each URL in url_list:
    FOR url_info IN url_list:
        target = url_info.target
        url = url_info.url

        IF mcp_chrome_devtools_available:
            REPORT: "   Processing: {target} ({url})"

            # Read extraction script
            script_content = Read(~/.claude/scripts/extract-layout-structure.js)

            # Open page in Chrome DevTools
            mcp__chrome-devtools__navigate_page(url=url)

            # Execute layout extraction script
            result = mcp__chrome-devtools__evaluate_script(function=script_content)

            # Save DOM structure for this target (intermediate file)
            Write({base_path}/.intermediates/layout-analysis/dom-structure-{target}.toon, result)

            REPORT: "   ✅ DOM structure extracted for '{target}'"
        ELSE:
            REPORT: "   ⚠️ Chrome DevTools MCP not available, falling back to visual analysis"
            BREAK

    dom_structure_available = mcp_chrome_devtools_available
ELSE:
    dom_structure_available = false
```

**Extraction Script Reference**: `~/.claude/scripts/extract-layout-structure.js`

**Usage**: Read the script file and use content directly in `mcp__chrome-devtools__evaluate_script()`

**Script returns**:
- `metadata`: Extraction timestamp, URL, method, version
- `patterns`: Layout pattern statistics (flexColumn, flexRow, grid counts)
- `structure`: Hierarchical DOM tree with layout properties
- `exploration`: (Optional) Progressive exploration results when standard selectors fail

**Benefits**:
- ✅ Real flex/grid configuration (justifyContent, alignItems, gap, etc.)
- ✅ Accurate element bounds (x, y, width, height)
- ✅ Structural hierarchy with depth control
- ✅ Layout pattern identification (flex-row, flex-column, grid-NCol)
- ✅ Progressive exploration: Auto-discovers missing selectors

**Progressive Exploration Strategy** (v2.2.0+):

When script finds <3 main containers, it automatically:
1. **Scans** all large visible containers (≥500×300px)
2. **Extracts** class patterns matching: `main|content|wrapper|container|page|layout|app`
3. **Suggests** new selectors to add to script
4. **Returns** exploration data in `result.exploration`:
   ```json
   {
     "triggered": true,
     "discoveredCandidates": [{classes, bounds, display}],
     "suggestedSelectors": [".wrapper", ".page-index"],
     "recommendation": ".wrapper, .page-index, .app-container"
   }
   ```

**Using Exploration Results**:
```javascript
// After extraction, check for suggestions
IF result.exploration?.triggered:
    REPORT: result.exploration.warning
    REPORT: "Suggested selectors: " + result.exploration.recommendation

    // Update script by adding to commonClassSelectors array
    // Then re-run extraction for better coverage
```

**Selector Update Workflow**:
1. Run extraction on unfamiliar site
2. Check `result.exploration.suggestedSelectors`
3. Add relevant selectors to script's `commonClassSelectors`
4. Re-run extraction → improved container detection

### Step 3: Memory Check
```bash
# 1. Check if inputs cached in session memory
IF session_has_inputs: SKIP Step 2 file reading

# 2. Check if output already exists
bash(find {base_path}/layout-extraction -name "layout-*.toon" -print -quit | grep -q . && echo "exists")
IF exists: SKIP to completion
```

---

**Phase 0 Output**: `input_mode`, `base_path`, `variants_count`, `targets[]`, `device_type`, loaded inputs

## Phase 1: Layout Concept or Refinement Options Generation

### Step 0.5: Load Existing Layout (Refinement Mode)
```bash
IF refine_mode:
    # Load existing layout for refinement
    existing_layouts = {}
    FOR target IN targets:
        layout_files = bash(find {base_path}/layout-extraction -name "layout-{target}-*.toon" -print)
        IF layout_files:
            # Use first/latest layout file for this target
            existing_layouts[target] = Read(first_layout_file)
```

### Step 1: Generate Options (Agent Task 1 - Mode-Specific)
**Executor**: `Task(ui-design-agent)`

**Exploration Mode** (default): Generate contrasting layout concepts
**Refinement Mode** (`--refine`): Generate refinement options for existing layouts

```javascript
// Conditional agent task based on refine_mode
IF NOT refine_mode:
    // EXPLORATION MODE
    Task(ui-design-agent): `
      [LAYOUT_CONCEPT_GENERATION_TASK]
      Generate {variants_count} structurally distinct layout concepts for each target

      SESSION: {session_id} | MODE: explore | BASE_PATH: {base_path}
      TARGETS: {targets} | DEVICE_TYPE: {device_type}

      ## Input Analysis
      - Targets: {targets.join(", ")}
      - Device type: {device_type}
      - Visual references: {loaded_images if available}
      ${dom_structure_available ? "- DOM Structure: Read from .intermediates/layout-analysis/dom-structure-*.toon" : ""}

      ## Analysis Rules
      - For EACH target, generate {variants_count} structurally DIFFERENT layout concepts
      - Concepts must differ in: grid structure, component arrangement, visual hierarchy
  - Each concept should have distinct navigation pattern, content flow, and responsive behavior

  ## Generate for EACH Target
  For target in {targets}:
    For concept_index in 1..{variants_count}:
      1. **Concept Definition**:
         - concept_name (descriptive, e.g., "Classic Three-Column Holy Grail")
         - design_philosophy (1-2 sentences explaining the structural approach)
         - layout_pattern (e.g., "grid-3col", "flex-row", "single-column", "asymmetric-grid")
         - key_components (array of main layout regions)
         - structural_features (list of distinguishing characteristics)

      2. **Wireframe Preview** (simple text representation):
         - ascii_art (simple ASCII box diagram showing layout structure)
         - Example:
           ┌─────────────────┐
           │     HEADER      │
           ├──┬─────────┬────┤
           │ L│  MAIN   │ R  │
           └──┴─────────┴────┘

  ## Output
  Write single JSON file: {base_path}/.intermediates/layout-analysis/analysis-options.toon

  Use schema from INTERACTIVE-DATA-SPEC.md (Layout Extract: analysis-options.toon)

  CRITICAL: Use Write() tool immediately after generating complete JSON
    `
ELSE:
    // REFINEMENT MODE
    Task(ui-design-agent): `
      [LAYOUT_REFINEMENT_OPTIONS_TASK]
      Generate refinement options for existing layout(s)

      SESSION: {session_id} | MODE: refine | BASE_PATH: {base_path}
      TARGETS: {targets} | DEVICE_TYPE: {device_type}

      ## Existing Layouts
      ${FOR target IN targets: "- {target}: {existing_layouts[target]}"}

      ## Input Guidance
      - User prompt: {prompt_guidance if available}
      - Visual references: {loaded_images if available}

      ## Refinement Categories
      Generate 8-12 refinement options per target across these categories:

      1. **Density Adjustments** (2-3 options per target):
         - More compact: Tighter spacing, reduced whitespace
         - More spacious: Increased margins, breathing room
         - Balanced: Moderate adjustments

      2. **Responsiveness Tuning** (2-3 options per target):
         - Breakpoint behavior: Earlier/later column stacking
         - Mobile layout: Different navigation/content priority
         - Tablet optimization: Hybrid desktop/mobile approach

      3. **Grid/Flex Specifics** (2-3 options per target):
         - Column counts: 2-col ↔ 3-col ↔ 4-col
         - Gap sizes: Tighter ↔ wider gutters
         - Alignment: Different flex/grid justification

      4. **Component Arrangement** (1-2 options per target):
         - Navigation placement: Top ↔ side ↔ bottom
         - Sidebar position: Left ↔ right ↔ none
         - Content hierarchy: Different section ordering

      ## Output Format
      Each option (per target):
      - target: Which target this refinement applies to
      - category: "density|responsiveness|grid|arrangement"
      - option_id: unique identifier
      - label: Short descriptive name (e.g., "More Compact Spacing")
      - description: What changes (2-3 sentences)
      - preview_changes: Key structural adjustments
      - impact_scope: Which layout regions affected

      ## Output
      Write single JSON file: {base_path}/.intermediates/layout-analysis/analysis-options.toon

      Use refinement schema:
      {
        "mode": "refinement",
        "device_type": "{device_type}",
        "refinement_options": {
          "{target1}": [array of refinement options],
          "{target2}": [array of refinement options]
        }
      }

      CRITICAL: Use Write() tool immediately after generating complete JSON
    `
```

### Step 2: Verify Options File Created
```bash
bash(test -f {base_path}/.intermediates/layout-analysis/analysis-options.toon && echo "created")

# Quick validation
bash(cat {base_path}/.intermediates/layout-analysis/analysis-options.toon | grep -q "layout_concepts" && echo "valid")
```

**Output**: `analysis-options.toon` with layout concept options for all targets

---

## Phase 1.5: User Confirmation (Optional - Triggered by --interactive)

**Purpose**:
- **Exploration Mode**: Allow user to select preferred layout concept(s) per target
- **Refinement Mode**: Allow user to select refinement options to apply per target

**Trigger Condition**: Execute this phase ONLY if `--interactive` flag is present

### Step 1: Check Interactive Flag
```bash
# Skip this entire phase if --interactive flag is not present
IF NOT --interactive:
    SKIP to Phase 2
    IF refine_mode:
        REPORT: "ℹ️ Non-interactive refinement mode: Will apply all suggested refinements"
    ELSE:
        REPORT: "ℹ️ Non-interactive mode: Will generate all {variants_count} variants per target"

# Interactive mode enabled
REPORT: "🎯 Interactive mode: User selection required for {targets.length} target(s)"
```

### Step 2: Load and Present Options (Mode-Specific)
```bash
# Read options file
options = Read({base_path}/.intermediates/layout-analysis/analysis-options.toon)

# Branch based on mode
IF NOT refine_mode:
    # EXPLORATION MODE
    layout_concepts = options.layout_concepts
ELSE:
    # REFINEMENT MODE
    refinement_options = options.refinement_options
```

### Step 2: Present Options to User (Per Target)
For each target, present layout concept options and capture selection:

```
📋 Layout Concept Options for Target: {target}

We've generated {variants_count} structurally different layout concepts for review.
Please select your preferred concept for this target.

{FOR each concept in layout_concepts[target]:
  ═══════════════════════════════════════════════════
  Concept {concept.index}: {concept.concept_name}
  ═══════════════════════════════════════════════════

  Philosophy: {concept.design_philosophy}
  Pattern: {concept.layout_pattern}

  Components:
  {FOR each component in concept.key_components:
    • {component}
  }

  Features:
  {FOR each feature in concept.structural_features:
    • {feature}
  }

  Wireframe:
  {concept.wireframe_preview.ascii_art}

  ═══════════════════════════════════════════════════
}
```

### Step 3: Capture User Selection and Update Options File (Per Target)

**Interaction Strategy**: If total concepts > 4 OR any target has > 3 concepts, use batch text format:

```
【目标[N] - [target]】选择布局方案
[key]) Concept [index]: [concept_name]
   [design_philosophy]
[key]) Concept [index]: [concept_name]
   [design_philosophy]
...
请回答 (格式: 1a 2b 或 1a,b 2c 多选)：

User input:
  "[N][key] [N][key] ..." → Single selection per target
  "[N][key1,key2] [N][key3] ..." → Multi-selection per target
```

Otherwise, use `AskUserQuestion` below.

```javascript
// Use AskUserQuestion tool for each target (multi-select enabled)
FOR each target:
  AskUserQuestion({
    questions: [{
      question: "Which layout concept(s) do you prefer for '{target}'?",
      header: "Layout for " + target,
      multiSelect: true,  // Multi-selection enabled (default behavior)
      options: [
        {FOR each concept in layout_concepts[target]:
          label: "Concept {concept.index}: {concept.concept_name}",
          description: "{concept.design_philosophy}"
        }
      ]
    }]
  })

  // Parse user response (array of selections)
  selected_options = user_answer

  // Check for user cancellation
  IF selected_options == null OR selected_options.length == 0:
      REPORT: "⚠️ User canceled selection. Workflow terminated."
      EXIT workflow

  // Extract concept indices from array
  selected_indices = []
  FOR each selected_option_text IN selected_options:
      match = selected_option_text.match(/Concept (\d+):/)
      IF match:
          selected_indices.push(parseInt(match[1]))
      ELSE:
          ERROR: "Invalid selection format. Expected 'Concept N: ...' format"
          EXIT workflow

  // Store selections for this target (array of indices)
  selections[target] = {
    selected_indices: selected_indices,  // Array of selected indices
    concept_names: selected_indices.map(i => layout_concepts[target][i-1].concept_name)
  }

  REPORT: "✅ Selected {selected_indices.length} layout(s) for {target}"

// Calculate total selections across all targets
total_selections = sum([len(selections[t].selected_indices) for t in targets])

// Update analysis-options.toon with user selection (embedded in same file)
options_file = Read({base_path}/.intermediates/layout-analysis/analysis-options.toon)
options_file.user_selection = {
  "selected_at": "{current_timestamp}",
  "selection_type": "per_target_multi",
  "session_id": "{session_id}",
  "total_selections": total_selections,
  "selected_variants": selections  // {target: {selected_indices: [...], concept_names: [...]}}
}

// Write updated file back
Write({base_path}/.intermediates/layout-analysis/analysis-options.toon, encodeTOON(options_file, { indent: 2 }))
```

### Step 4: Confirmation Message
```
✅ Selections recorded! Total: {total_selections} layout(s)

{FOR each target, selection in selections:
  • {target}: {selection.selected_indices.length} layout(s) selected
    {FOR each index IN selection.selected_indices:
      - Concept {index}: {layout_concepts[target][index-1].concept_name}
    }
}

Proceeding to generate {total_selections} detailed layout template(s)...
```

**Output**: `analysis-options.toon` updated with embedded `user_selection` field

## Phase 2: Layout Template Generation (Agent Task 2)

**Executor**: `Task(ui-design-agent)` × `Total_Selected_Templates` in **parallel**

### Step 1: Load User Selections or Default to All
```bash
# Read analysis-options.toon which may contain user_selection
options = Read({base_path}/.intermediates/layout-analysis/analysis-options.toon)
layout_concepts = options.layout_concepts

# Check if user_selection field exists (interactive mode)
IF options.user_selection AND options.user_selection.selected_variants:
    # Interactive mode: Use user-selected variants
    selections_per_target = options.user_selection.selected_variants
    total_selections = options.user_selection.total_selections
ELSE:
    # Non-interactive mode: Generate ALL variants for ALL targets (default behavior)
    selections_per_target = {}
    total_selections = 0

    FOR each target in targets:
        selections_per_target[target] = {
            "selected_indices": [1, 2, ..., variants_count],  # All indices
            "concept_names": []  # Will be filled from options
        }
        total_selections += variants_count

# Build task list for all selected concepts across all targets
task_list = []
FOR each target in targets:
    selected_indices = selections_per_target[target].selected_indices  # Array
    concept_names = selections_per_target[target].concept_names        # Array

    FOR i in range(len(selected_indices)):
        idx = selected_indices[i]
        concept = layout_concepts[target][idx - 1]  # 0-indexed array
        variant_id = i + 1  # 1-based variant numbering

        task_list.push({
            target: target,
            variant_id: variant_id,
            concept: concept,
            output_file: "{base_path}/layout-extraction/layout-{target}-{variant_id}.toon"
        })

total_tasks = task_list.length
REPORT: "Generating {total_tasks} layout templates across {targets.length} targets"
```

### Step 2: Launch Parallel Agent Tasks
Generate layout templates for ALL selected concepts in parallel:
```javascript
FOR each task in task_list:
    Task(ui-design-agent): `
      [LAYOUT_TEMPLATE_GENERATION_TASK #{task.variant_id} for {task.target}]
      Generate detailed layout template based on user-selected concept.
      Focus ONLY on structure and layout. DO NOT concern with visual style (colors, fonts, etc.).

      SESSION: {session_id} | BASE_PATH: {base_path}
      TARGET: {task.target} | VARIANT: {task.variant_id}
      DEVICE_TYPE: {device_type}

      USER SELECTION:
      - Selected Concept: {task.concept.concept_name}
      - Philosophy: {task.concept.design_philosophy}
      - Pattern: {task.concept.layout_pattern}
      - Key Components: {task.concept.key_components.join(", ")}
      - Structural Features: {task.concept.structural_features.join(", ")}

      ## Input Analysis
      - Target: {task.target}
      - Device type: {device_type}
      - Visual references: {loaded_images if available}
      ${dom_structure_available ? "- DOM Structure Data: Read from .intermediates/layout-analysis/dom-structure-{task.target}.toon - USE THIS for accurate layout properties" : ""}

      ## Generation Rules
      - Develop the user-selected layout concept into a detailed template
      - Use the selected concept's key_components as foundation
      - Apply the selected layout_pattern (grid-3col, flex-row, etc.)
      - Honor the structural_features defined in the concept
      - Expand the concept with complete DOM structure and CSS layout rules
      ${dom_structure_available ? `
      - IMPORTANT: You have access to real DOM structure data with accurate flex/grid properties
      - Use DOM data as primary source for layout properties
      - Extract real flex/grid configurations (display, flexDirection, justifyContent, alignItems, gap)
      - Use actual element bounds for responsive breakpoint decisions
      - Preserve identified patterns from DOM structure
      ` : ""}

      ## Template Generation

      1. **DOM Structure**:
         - Semantic HTML5 tags: <header>, <nav>, <main>, <aside>, <section>, <footer>
         - ARIA roles and accessibility attributes
         - Use key_components from selected concept
         ${dom_structure_available ? "- Base on extracted DOM tree from .intermediates" : "- Infer from visual analysis"}
         - Device-specific optimizations for {device_type}

      2. **Component Hierarchy**:
         - Array of main layout regions
         - Derived from selected concept's key_components

      3. **CSS Layout Rules**:
         - Implement selected layout_pattern
         ${dom_structure_available ? "- Use real layout properties from DOM structure data" : "- Focus on Grid, Flexbox, position, alignment"}
         - Use CSS Custom Properties: var(--spacing-*), var(--breakpoint-*)
         - Device-specific styles (mobile-first @media for responsive)
         - NO colors, NO fonts, NO shadows - layout structure only

      ## Output Files

      Generate 2 files:

      1. **layout-templates.toon** - {task.output_file}
         Write single-template JSON object with:
         - target: "{task.target}"
         - variant_id: "layout-{task.variant_id}"
         - source_image_path (string): Reference image path
         - device_type: "{device_type}"
         - design_philosophy (string from selected concept)
         - dom_structure (JSON object)
         - component_hierarchy (array of strings)
         - css_layout_rules (string)

      ## Critical Requirements
      - ✅ Use Write() tool to generate JSON file
      - ✅ Single template for {task.target} variant {task.variant_id}
      - ✅ Structure only, no visual styling
      - ✅ Token-based CSS (var())
      - ✅ Can use Exa MCP to research modern layout patterns and obtain code examples (Explore/Text mode)
      - ✅ Maintain consistency with selected concept
    `
```

**Output**: Agent generates multiple layout template files (one per selected concept)

### Step 3: Verify Output Files
```bash
# Count generated files
expected_count = total_tasks
actual_count = bash(ls {base_path}/layout-extraction/layout-*.toon | wc -l)

# Verify all files were created
IF actual_count == expected_count:
    REPORT: "✓ All {expected_count} layout template files generated"
ELSE:
    ERROR: "Expected {expected_count} files, found {actual_count}"

# Verify file structure (sample check)
bash(cat {base_path}/layout-extraction/layout-{first_target}-1.toon | grep -q "variant_id" && echo "valid structure")
```

**Output**: All layout template files created and verified (one file per selected concept)

## Completion

### Todo Update
```javascript
TodoWrite({todos: [
  {content: "Setup and input validation", status: "completed", activeForm: "Validating inputs"},
  {content: "Layout concept analysis (agent)", status: "completed", activeForm: "Analyzing layout patterns"},
  {content: "User selection confirmation", status: "completed", activeForm: "Confirming selections"},
  {content: "Generate layout templates (parallel)", status: "completed", activeForm: "Generating templates"},
  {content: "Verify output files", status: "completed", activeForm: "Verifying files"}
]});
```

### Output Message
```
✅ Layout extraction complete!

Configuration:
- Session: {session_id}
- Device Type: {device_type}
- Targets: {targets.join(", ")}
- Total Templates: {total_tasks} ({targets.length} targets with multi-selection)
{IF has_urls AND dom_structure_available:
- 🔍 URL Mode: DOM structure extracted from {len(url_list)} URL(s)
- Accuracy: Real flex/grid properties from live pages
}
{IF has_urls AND NOT dom_structure_available:
- ⚠️ URL Mode: Chrome DevTools unavailable, used visual analysis fallback
}

User Selections:
{FOR each target in targets:
- {target}: {selections_per_target[target].concept_names.join(", ")} ({selections_per_target[target].selected_indices.length} variants)
}

Generated Templates:
{base_path}/layout-extraction/
{FOR each target in targets:
  {FOR each variant_id in range(1, selections_per_target[target].selected_indices.length + 1):
    └── layout-{target}-{variant_id}.toon
  }
}

Intermediate Files:
- {base_path}/.intermediates/layout-analysis/
  ├── analysis-options.toon (concept proposals + user selections embedded)
  {IF dom_structure_available:
  ├── dom-structure-*.toon ({len(url_list)} DOM extracts)
  }

Next: /workflow:ui-design:generate will combine these structural templates with design systems to produce final prototypes.
```

## Simple Bash Commands

### Path Operations
```bash
# Find design directory
bash(find .workflow -type d -name "design-run-*" | head -1)

# Create output directories
bash(mkdir -p {base_path}/layout-extraction)
```

### Validation Commands
```bash
# Check if already extracted
bash(find {base_path}/layout-extraction -name "layout-*.toon" -print -quit | grep -q . && echo "exists")

# Count generated files
bash(ls {base_path}/layout-extraction/layout-*.toon | wc -l)

# Validate JSON structure (sample check)
bash(cat {base_path}/layout-extraction/layout-{first_target}-1.toon | grep -q "variant_id" && echo "valid")
```

### File Operations
```bash
# Load image references
bash(ls {images_pattern})
Read({image_path})

# Write layout templates
bash(echo '{json}' > {base_path}/layout-extraction/layout-templates.toon)
```

## Output Structure

```
{base_path}/
├── .intermediates/                    # Intermediate analysis files
│   └── layout-analysis/
│       ├── analysis-options.toon      # Generated layout concepts + user selections (embedded)
│       └── dom-structure-{target}.toon   # Extracted DOM structure (URL mode only)
└── layout-extraction/                 # Final layout templates
    └── layout-{target}-{variant}.toon # Structural layout template JSON
```

## Layout Template File Format

Each `layout-{target}-{variant}.toon` file contains a single template:

```json
{
  "extraction_metadata": {
    "session_id": "...",
    "input_mode": "image|url|prompt|hybrid",
    "device_type": "desktop|mobile|tablet|responsive",
    "timestamp": "...",
    "target": "home",
    "variant_id": "layout-1"
  },
  "template":
    {
      "target": "home",
      "variant_id": "layout-1",
      "source_image_path": "{base_path}/screenshots/home.png",
      "device_type": "responsive",
      "design_philosophy": "Responsive 3-column holy grail layout with fixed header and footer",
      "dom_structure": {
        "tag": "body",
        "children": [
          {
            "tag": "header",
            "attributes": {"class": "layout-header"},
            "children": [{"tag": "nav"}]
          },
          {
            "tag": "div",
            "attributes": {"class": "layout-main-wrapper"},
            "children": [
              {"tag": "main", "attributes": {"class": "layout-main-content"}},
              {"tag": "aside", "attributes": {"class": "layout-sidebar-left"}},
              {"tag": "aside", "attributes": {"class": "layout-sidebar-right"}}
            ]
          },
          {"tag": "footer", "attributes": {"class": "layout-footer"}}
        ]
      },
      "component_hierarchy": [
        "header",
        "main-content",
        "sidebar-left",
        "sidebar-right",
        "footer"
      ],
      "css_layout_rules": ".layout-main-wrapper { display: grid; grid-template-columns: 1fr 3fr 1fr; gap: var(--spacing-6); } @media (max-width: var(--breakpoint-md)) { .layout-main-wrapper { grid-template-columns: 1fr; } }"
    }
  ]
}
```

**Requirements**: Token-based CSS (var()), semantic HTML5, device-specific structure, accessibility attributes

## Error Handling

### Common Errors
```
ERROR: No inputs provided
→ Provide --images, --urls, or --prompt

ERROR: Invalid target name
→ Use lowercase, alphanumeric, hyphens only

ERROR: Agent task failed
→ Check agent output, retry with simplified prompt

ERROR: MCP search failed
→ Check network connection, retry command
```

### Recovery Strategies
- **Partial success**: Keep successfully extracted templates
- **Invalid JSON**: Retry with stricter format requirements
- **Missing inspiration**: Works without (less informed exploration)

## Key Features

- **Auto-Trigger URL Mode** - Automatically extracts DOM structure when --urls provided (no manual flag needed)
- **Hybrid Extraction Strategy** - Combines real DOM structure data with AI visual analysis
- **Accurate Layout Properties** - Chrome DevTools extracts real flex/grid configurations, bounds, and hierarchy
- **Separation of Concerns** - Decouples layout (structure) from style (visuals)
- **Multi-Selection Workflow** - Generate N concepts → User selects multiple → Parallel template generation
- **Structural Exploration** - Enables A/B testing of different layouts through multi-selection
- **Token-Based Layout** - CSS uses `var()` placeholders for instant design system adaptation
- **Device-Specific** - Tailored structures for different screen sizes
- **Graceful Fallback** - Falls back to visual analysis if Chrome DevTools unavailable
- **Foundation for Assembly** - Provides structural blueprint for prototype generation
- **Agent-Powered** - Deep structural analysis with AI


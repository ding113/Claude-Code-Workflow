---
name: explore-auto
description: Interactive exploratory UI design workflow with style-centric batch generation, creates design variants from prompts/images with parallel execution and user selection
argument-hint: "[--input "<value>"] [--targets "<list>"] [--target-type "page|component"] [--session <id>] [--style-variants <count>] [--layout-variants <count>]"
allowed-tools: SlashCommand(*), TodoWrite(*), Read(*), Bash(*), Glob(*), Write(*), Task(conceptual-planning-agent)
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# UI Design Auto Workflow Command

## Overview & Execution Model

**Fully autonomous orchestrator**: Executes all design phases sequentially from style extraction to design integration, with optional batch planning.

**Unified Target System**: Generates `style_variants × layout_variants × targets` prototypes, where targets can be:
- **Pages** (full-page layouts): home, dashboard, settings, etc.
- **Components** (isolated UI elements): navbar, card, hero, form, etc.
- **Mixed**: Can combine both in a single workflow

**Autonomous Flow** (⚠️ CONTINUOUS EXECUTION - DO NOT STOP):
1. User triggers: `/workflow:ui-design:explore-auto [params]`
2. Phase 5: Target confirmation → User confirms → **IMMEDIATELY triggers Phase 7**
3. Phase 7 (style-extract) → **Attach tasks → Execute → Collapse** → Auto-continues to Phase 8
4. Phase 8 (animation-extract, conditional):
   - **IF should_extract_animation**: **Attach tasks → Execute → Collapse** → Auto-continues to Phase 9
   - **ELSE**: Skip (use code import) → Auto-continues to Phase 9
5. Phase 9 (layout-extract) → **Attach tasks → Execute → Collapse** → Auto-continues to Phase 10
6. **Phase 10 (ui-assembly)** → **Attach tasks → Execute → Collapse** → Auto-continues to Phase 11
7. **Phase 11 (preview-generation)** → **Execute script → Generate preview files** → Reports completion

**Phase Transition Mechanism**:
- **Phase 5 (User Interaction)**: User confirms targets → IMMEDIATELY triggers Phase 7
- **Phase 7-10 (Autonomous)**: `SlashCommand` invocation **ATTACHES** tasks to current workflow
- **Task Execution**: Orchestrator **EXECUTES** these attached tasks itself
- **Task Collapse**: After tasks complete, collapse them into phase summary
- **Phase Transition**: Automatically execute next phase after collapsing
- **Phase 11 (Script Execution)**: Execute preview generation script
- No additional user interaction after Phase 5 confirmation

**Auto-Continue Mechanism**: TodoWrite tracks phase status with dynamic task attachment/collapse. After executing all attached tasks, you MUST immediately collapse them, restore phase summary, and execute the next phase. No user intervention required. The workflow is NOT complete until reaching Phase 11 (preview generation).

**Task Attachment Model**: SlashCommand invocation is NOT delegation - it's task expansion. The orchestrator executes these attached tasks itself, not waiting for external completion.

**Target Type Detection**: Automatically inferred from prompt/targets, or explicitly set via `--target-type`.

## Core Rules

1. **Start Immediately**: TodoWrite initialization → Phase 7 execution
2. **No Preliminary Validation**: Sub-commands handle their own validation
3. **Parse & Pass**: Extract data from each output for next phase
4. **Default to All**: When selecting variants/prototypes, use ALL generated items
5. **Track Progress**: Update TodoWrite dynamically with task attachment/collapse pattern
6. **⚠️ CRITICAL: Task Attachment Model** - SlashCommand invocation **ATTACHES** tasks to current workflow. Orchestrator **EXECUTES** these attached tasks itself, not waiting for external completion. This is NOT delegation - it's task expansion.
7. **⚠️ CRITICAL: DO NOT STOP** - This is a continuous multi-phase workflow. After executing all attached tasks, you MUST immediately collapse them and execute the next phase. Workflow is NOT complete until Phase 11 (preview generation).

## Parameter Requirements

**Recommended Parameter**:
- `--input "<value>"`: Unified input source (auto-detects type)
  - **Glob pattern** (images): `"design-refs/*"`, `"screenshots/*.png"`
  - **File/directory path** (code): `"./src/components"`, `"/path/to/styles"`
  - **Text description** (prompt): `"modern dashboard with 3 styles"`, `"minimalist design"`
  - **Combination**: `"design-refs/* modern dashboard"` (glob + description)
  - Multiple inputs: Separate with `|` → `"design-refs/*|modern style"`

**Detection Logic**:
- Contains `*` or matches existing files → **glob pattern** (images)
- Existing file/directory path → **code import**
- Pure text without paths → **design prompt**
- Contains `|` separator → **multiple inputs** (glob|prompt or path|prompt)

**Legacy Parameters** (deprecated, use `--input` instead):
- `--images "<glob>"`: Reference image paths (shows deprecation warning)
- `--prompt "<description>"`: Design description (shows deprecation warning)

**Optional Parameters** (all have smart defaults):
- `--targets "<list>"`: Comma-separated targets (pages/components) to generate (inferred from prompt/session if omitted)
- `--target-type "page|component|auto"`: Explicitly set target type (default: `auto` - intelligent detection)
- `--device-type "desktop|mobile|tablet|responsive|auto"`: Device type for layout optimization (default: `auto` - intelligent detection)
  - **Desktop**: 1920×1080px - Mouse-driven, spacious layouts
  - **Mobile**: 375×812px - Touch-friendly, compact layouts
  - **Tablet**: 768×1024px - Hybrid touch/mouse layouts
  - **Responsive**: 1920×1080px base with mobile-first breakpoints
- `--session <id>`: Workflow session ID (standalone mode if omitted)
- `--style-variants <count>`: Style variants (default: inferred from prompt or 3, range: 1-5)
- `--layout-variants <count>`: Layout variants per style (default: inferred or 3, range: 1-5)

**Legacy Target Parameters** (maintained for backward compatibility):
- `--pages "<list>"`: Alias for `--targets` with `--target-type page`
- `--components "<list>"`: Alias for `--targets` with `--target-type component`

**Input Rules**:
- Must provide: `--input` OR (legacy: `--images`/`--prompt`) OR `--targets`
- `--input` can combine multiple input types
- If `--targets` not provided, intelligently inferred from prompt/session

**Supported Target Types**:
- **Pages** (full layouts): home, dashboard, settings, profile, login, etc.
- **Components** (UI elements):
  - Navigation: navbar, header, menu, breadcrumb, tabs, sidebar
  - Content: hero, card, list, table, grid, timeline
  - Input: form, search, filter, input-group
  - Feedback: modal, alert, toast, badge, progress
  - Media: gallery, carousel, video-player, image-card
  - Other: footer, pagination, dropdown, tooltip, avatar

**Intelligent Prompt Parsing**: Extracts variant counts from natural language:
- "Generate **3 style variants**" → `--style-variants 3`
- "**2 layout options**" → `--layout-variants 2`
- "Create **4 styles** with **2 layouts each**" → `--style-variants 4 --layout-variants 2`
- Explicit flags override prompt inference

## Execution Modes

**Matrix Mode** (style-centric):
- Generates `style_variants × layout_variants × targets` prototypes
- **Phase 1**: `style_variants` complete design systems (extract)
- **Phase 2**: Layout templates extraction (layout-extract)
- **Phase 3**: Style-centric batch generation (generate)
  - Sub-phase 1: `targets × layout_variants` target-specific layout plans
  - **Sub-phase 2**: `S` style-centric agents (each handles `L×T` combinations)
  - Sub-phase 3: `style_variants × layout_variants × targets` final prototypes
  - Performance: Efficient parallel execution with S agents
  - Quality: HTML structure adapts to design_attributes
  - Pages: Full-page layouts with complete structure
  - Components: Isolated elements with minimal wrapper

**Integrated vs. Standalone**:
- `--session` flag determines session integration or standalone execution

## 11-Phase Execution

### Phase 1: Parameter Parsing & Input Detection
```bash
# Step 0: Parse and normalize parameters
images_input = null
prompt_text = null

# Handle legacy parameters with deprecation warning
IF --images OR --prompt:
    WARN: "⚠️  DEPRECATION: --images and --prompt are deprecated. Use --input instead."
    WARN: "   Example: --input \"design-refs/*\" or --input \"modern dashboard\""
    images_input = --images
    prompt_text = --prompt

# Parse unified --input parameter
IF --input:
    # Split by | separator for multiple inputs
    input_parts = split(--input, "|")

    FOR part IN input_parts:
        part = trim(part)

        # Detection logic
        IF contains(part, "*") OR glob_matches_files(part):
            # Glob pattern detected → images
            images_input = part
        ELSE IF file_or_directory_exists(part):
            # File/directory path → will be handled in code detection
            IF NOT prompt_text:
                prompt_text = part
            ELSE:
                prompt_text = prompt_text + " " + part
        ELSE:
            # Pure text → prompt
            IF NOT prompt_text:
                prompt_text = part
            ELSE:
                prompt_text = prompt_text + " " + part

# Step 1: Detect design source from parsed inputs
code_files_detected = false
code_base_path = null
has_visual_input = false

IF prompt_text:
    # Extract potential file paths from prompt
    potential_paths = extract_paths_from_text(prompt_text)
    FOR path IN potential_paths:
        IF file_or_directory_exists(path):
            code_files_detected = true
            code_base_path = path
            BREAK

IF images_input:
    # Check if images parameter points to existing files
    IF glob_matches_files(images_input):
        has_visual_input = true

# Step 2: Determine design source strategy
design_source = "unknown"
IF code_files_detected AND has_visual_input:
    design_source = "hybrid"  # Both code and visual
ELSE IF code_files_detected:
    design_source = "code_only"  # Only code files
ELSE IF has_visual_input OR --prompt:
    design_source = "visual_only"  # Only visual/prompt
ELSE:
    ERROR: "No design source provided (code files, images, or prompt required)"
    EXIT 1

STORE: design_source, code_base_path, has_visual_input
```

### Phase 2: Intelligent Prompt Parsing
```bash
# Parse variant counts from prompt or use explicit/default values
IF prompt_text AND (NOT --style-variants OR NOT --layout-variants):
    style_variants = regex_extract(prompt_text, r"(\d+)\s*style") OR --style-variants OR 3
    layout_variants = regex_extract(prompt_text, r"(\d+)\s*layout") OR --layout-variants OR 3
ELSE:
    style_variants = --style-variants OR 3
    layout_variants = --layout-variants OR 3

VALIDATE: 1 <= style_variants <= 5, 1 <= layout_variants <= 5

# Interactive mode (always enabled)
interactive_mode = true  # Always use interactive mode
```

### Phase 3: Device Type Inference
```bash
# Device type inference
device_type = "auto"

# Step 1: Explicit parameter (highest priority)
IF --device-type AND --device-type != "auto":
    device_type = --device-type
    device_source = "explicit"
ELSE:
    # Step 2: Prompt analysis
    IF prompt_text:
        device_keywords = {
            "desktop": ["desktop", "web", "laptop", "widescreen", "large screen"],
            "mobile": ["mobile", "phone", "smartphone", "ios", "android"],
            "tablet": ["tablet", "ipad", "medium screen"],
            "responsive": ["responsive", "adaptive", "multi-device", "cross-platform"]
        }
        detected_device = detect_device_from_prompt(prompt_text, device_keywords)
        IF detected_device:
            device_type = detected_device
            device_source = "prompt_inference"

    # Step 3: Target type inference
    IF device_type == "auto":
        # Components are typically desktop-first, pages can vary
        device_type = target_type == "component" ? "desktop" : "responsive"
        device_source = "target_type_inference"

STORE: device_type, device_source
```

**Device Type Presets**:
- **Desktop**: 1920×1080px - Mouse-driven, spacious layouts
- **Mobile**: 375×812px - Touch-friendly, compact layouts
- **Tablet**: 768×1024px - Hybrid touch/mouse layouts
- **Responsive**: 1920×1080px base with mobile-first breakpoints

**Detection Keywords**:
- Prompt contains "mobile", "phone", "smartphone" → mobile
- Prompt contains "tablet", "ipad" → tablet
- Prompt contains "desktop", "web", "laptop" → desktop
- Prompt contains "responsive", "adaptive" → responsive
- Otherwise: Inferred from target type (components→desktop, pages→responsive)

### Phase 4: Run Initialization & Directory Setup
```bash
design_id = "design-run-$(date +%Y%m%d)-$RANDOM"
relative_base_path = --session ? ".workflow/WFS-{session}/${design_id}" : ".workflow/${design_id}"

# Create directory and convert to absolute path
Bash(mkdir -p "${relative_base_path}/style-extraction")
Bash(mkdir -p "${relative_base_path}/prototypes")
base_path=$(cd "${relative_base_path}" && pwd)

Write({base_path}/.run-metadata.toon): {
  "design_id": "${design_id}", "session_id": "${session_id}", "timestamp": "...",
  "workflow": "ui-design:auto",
  "architecture": "style-centric-batch-generation",
  "parameters": { "style_variants": ${style_variants}, "layout_variants": ${layout_variants},
                  "targets": "${inferred_target_list}", "target_type": "${target_type}",
                  "prompt": "${prompt_text}", "images": "${images_input}",
                  "input": "${--input}",
                  "device_type": "${device_type}", "device_source": "${device_source}" },
  "status": "in_progress",
  "performance_mode": "optimized"
}

# Initialize default flags for animation extraction logic
animation_complete = false  # Default: always extract animations unless code import proves complete
needs_visual_supplement = false  # Will be set to true in hybrid mode
skip_animation_extraction = false  # User preference for code import scenario
```

### Phase 5: Unified Target Inference with Intelligent Type Detection
```bash
# Priority: --pages/--components (legacy) → --targets → --prompt analysis → synthesis → default
target_list = []; target_type = "auto"; target_source = "none"

# Step 1-2: Explicit parameters (legacy or unified)
IF --pages: target_list = split(--pages); target_type = "page"; target_source = "explicit_legacy"
ELSE IF --components: target_list = split(--components); target_type = "component"; target_source = "explicit_legacy"
ELSE IF --targets:
    target_list = split(--targets); target_source = "explicit"
    target_type = --target-type != "auto" ? --target-type : detect_target_type(target_list)

# Step 3: Prompt analysis (Claude internal analysis)
ELSE IF prompt_text:
    analysis_result = analyze_prompt(prompt_text)  # Extract targets, types, purpose
    target_list = analysis_result.targets
    target_type = analysis_result.primary_type OR detect_target_type(target_list)
    target_source = "prompt_analysis"

# Step 4: Session synthesis
ELSE IF --session AND exists(role analysis documents):
    target_list = extract_targets_from_synthesis(); target_type = "page"; target_source = "synthesis"

# Step 5: Fallback
IF NOT target_list: target_list = ["home"]; target_type = "page"; target_source = "default"

# Validate and clean
validated_targets = [normalize(t) for t in target_list if is_valid(t)]
IF NOT validated_targets: validated_targets = ["home"]; target_type = "page"
IF --target-type != "auto": target_type = --target-type

# Interactive confirmation
DISPLAY_CONFIRMATION(target_type, target_source, validated_targets, device_type, device_source):
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  "{emoji} {LABEL} CONFIRMATION (Style-Centric)"
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  "Type: {target_type} | Source: {target_source}"
  "Targets ({count}): {', '.join(validated_targets)}"
  "Device: {device_type} | Source: {device_source}"
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  "Performance: {style_variants} agent calls"
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  "Modification Options:"
  "  • 'continue/yes/ok' - Proceed with current configuration"
  "  • 'targets: a,b,c' - Replace target list"
  "  • 'skip: x,y' - Remove specific targets"
  "  • 'add: z' - Add new targets"
  "  • 'type: page|component' - Change target type"
  "  • 'device: desktop|mobile|tablet|responsive' - Change device type"
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

user_input = WAIT_FOR_USER_INPUT()

# Process user modifications
MATCH user_input:
  "continue|yes|ok" → proceed
  "targets: ..." → validated_targets = parse_new_list()
  "skip: ..." → validated_targets = remove_items()
  "add: ..." → validated_targets = add_items()
  "type: ..." → target_type = extract_type()
  "device: ..." → device_type = extract_device()
  default → proceed with current list

STORE: inferred_target_list, target_type, target_inference_source

# ⚠️ CRITICAL: User confirmation complete, IMMEDIATELY initialize TodoWrite and execute Phase 7
# This is the only user interaction point in the workflow
# After this point, all subsequent phases execute automatically without user intervention
```

**Helper Function: detect_target_type()**
```bash
detect_target_type(target_list):
    page_keywords = ["home", "dashboard", "settings", "profile", "login", "signup", "auth", ...]
    component_keywords = ["navbar", "header", "footer", "hero", "card", "button", "form", ...]

    page_matches = count_matches(target_list, page_keywords + ["page", "screen", "view"])
    component_matches = count_matches(target_list, component_keywords + ["component", "widget"])

    RETURN "component" IF component_matches > page_matches ELSE "page"
```

### Phase 6: Code Import & Completeness Assessment (Conditional)
```bash
IF design_source IN ["code_only", "hybrid"]:
    REPORT: "🔍 Phase 6: Code Import ({design_source})"
    command = "/workflow:ui-design:import-from-code --design-id \"{design_id}\" --source \"{code_base_path}\""

    TRY:
        # SlashCommand invocation ATTACHES import-from-code's tasks to current workflow
        # Orchestrator will EXECUTE these attached tasks itself:
        #   - Phase 0: Discover and categorize code files
        #   - Phase 1.1-1.3: Style/Animation/Layout Agent extraction
        SlashCommand(command)
    CATCH error:
        WARN: "⚠️ Code import failed: {error}"
        WARN: "Cleaning up incomplete import directories"
        Bash(rm -rf "{base_path}/style-extraction" "{base_path}/animation-extraction" "{base_path}/layout-extraction" 2>/dev/null)

        IF design_source == "code_only":
            REPORT: "Cannot proceed with code-only mode after import failure"
            EXIT 1
        ELSE:  # hybrid mode
            WARN: "Continuing with visual-only mode"
            design_source = "visual_only"

    # Check file existence and assess completeness
    style_exists = exists("{base_path}/style-extraction/style-1/design-tokens.toon")
    animation_exists = exists("{base_path}/animation-extraction/animation-tokens.toon")
    layout_count = bash(ls {base_path}/layout-extraction/layout-*.toon 2>/dev/null | wc -l)
    layout_exists = (layout_count > 0)

    style_complete = false
    animation_complete = false
    layout_complete = false
    missing_categories = []

    # Style completeness check
    IF style_exists:
        tokens = Read("{base_path}/style-extraction/style-1/design-tokens.toon")
        style_complete = (
            tokens.colors?.brand && tokens.colors?.surface &&
            tokens.typography?.font_family && tokens.spacing &&
            Object.keys(tokens.colors.brand || {}).length >= 3 &&
            Object.keys(tokens.spacing || {}).length >= 8
        )
        IF NOT style_complete AND tokens._metadata?.completeness?.missing_categories:
            missing_categories.extend(tokens._metadata.completeness.missing_categories)
    ELSE:
        missing_categories.push("style tokens")

    # Animation completeness check
    IF animation_exists:
        anim = Read("{base_path}/animation-extraction/animation-tokens.toon")
        animation_complete = (
            anim.duration && anim.easing &&
            Object.keys(anim.duration || {}).length >= 3 &&
            Object.keys(anim.easing || {}).length >= 3
        )
        IF NOT animation_complete AND anim._metadata?.completeness?.missing_items:
            missing_categories.extend(anim._metadata.completeness.missing_items)
    ELSE:
        missing_categories.push("animation tokens")

    # Layout completeness check
    IF layout_exists:
        # Read first layout file to verify structure
        first_layout = bash(ls {base_path}/layout-extraction/layout-*.toon 2>/dev/null | head -1)
        layout_data = Read(first_layout)
        layout_complete = (
            layout_count >= 1 &&
            layout_data.template?.dom_structure &&
            layout_data.template?.css_layout_rules
        )
        IF NOT layout_complete:
            missing_categories.push("complete layout structure")
    ELSE:
        missing_categories.push("layout templates")

    needs_visual_supplement = false

    IF design_source == "code_only" AND NOT (style_complete AND layout_complete):
        REPORT: "⚠️  Missing: {', '.join(missing_categories)}"
        REPORT: "Options: 'continue' | 'supplement: <images>' | 'cancel'"
        user_response = WAIT_FOR_USER_INPUT()
        MATCH user_response:
            "continue" → needs_visual_supplement = false
            "supplement: ..." → needs_visual_supplement = true; --images = extract_path(user_response)
            "cancel" → EXIT 0
            default → needs_visual_supplement = false
    ELSE IF design_source == "hybrid":
        needs_visual_supplement = true

    # Animation reuse confirmation (code import with complete animations)
    IF design_source == "code_only" AND animation_complete:
        REPORT: "✅ 检测到完整的动画系统（来自代码导入）"
        REPORT: "   Duration scales: {duration_count} | Easing functions: {easing_count}"
        REPORT: ""
        REPORT: "Options:"
        REPORT: "  • 'reuse' (默认) - 复用已有动画系统"
        REPORT: "  • 'regenerate' - 重新生成动画系统（交互式）"
        REPORT: "  • 'cancel' - 取消工作流"
        user_response = WAIT_FOR_USER_INPUT()
        MATCH user_response:
            "reuse" → skip_animation_extraction = true
            "regenerate" → skip_animation_extraction = false
            "cancel" → EXIT 0
            default → skip_animation_extraction = true  # Default: reuse

    STORE: needs_visual_supplement, style_complete, animation_complete, layout_complete, skip_animation_extraction
```

### Phase 7: Style Extraction
```bash
IF design_source == "visual_only" OR needs_visual_supplement:
    REPORT: "🎨 Phase 7: Style Extraction (variants: {style_variants})"
    command = "/workflow:ui-design:style-extract --design-id \"{design_id}\" " +
              (images_input ? "--images \"{images_input}\" " : "") +
              (prompt_text ? "--prompt \"{prompt_text}\" " : "") +
              "--variants {style_variants} --interactive"

    # SlashCommand invocation ATTACHES style-extract's tasks to current workflow
    # Orchestrator will EXECUTE these attached tasks itself
    SlashCommand(command)

    # After executing all attached tasks, collapse them into phase summary
ELSE:
    REPORT: "✅ Phase 7: Style (Using Code Import)"
```

### Phase 8: Animation Extraction
```bash
# Determine if animation extraction is needed
should_extract_animation = false

IF (design_source == "visual_only" OR needs_visual_supplement):
    # Pure visual input or hybrid mode requiring visual supplement
    should_extract_animation = true
ELSE IF NOT animation_complete:
    # Code import but animations are incomplete
    should_extract_animation = true
ELSE IF design_source == "code_only" AND animation_complete AND NOT skip_animation_extraction:
    # Code import with complete animations, but user chose to regenerate
    should_extract_animation = true

IF should_extract_animation:
    REPORT: "🚀 Phase 8: Animation Extraction"

    # Build command with available inputs
    command_parts = [f"/workflow:ui-design:animation-extract --design-id \"{design_id}\""]

    IF images_input:
        command_parts.append(f"--images \"{images_input}\"")

    IF prompt_text:
        command_parts.append(f"--prompt \"{prompt_text}\"")

    command_parts.append("--interactive")

    command = " ".join(command_parts)

    # SlashCommand invocation ATTACHES animation-extract's tasks to current workflow
    # Orchestrator will EXECUTE these attached tasks itself
    SlashCommand(command)

    # After executing all attached tasks, collapse them into phase summary
ELSE:
    REPORT: "✅ Phase 8: Animation (Using Code Import)"

# Output: animation-tokens.toon + animation-guide.md
# When phase finishes, IMMEDIATELY execute Phase 9 (auto-continue)
```

### Phase 9: Layout Extraction
```bash
targets_string = ",".join(inferred_target_list)

IF (design_source == "visual_only" OR needs_visual_supplement) OR (NOT layout_complete):
    REPORT: "🚀 Phase 9: Layout Extraction ({targets_string}, variants: {layout_variants}, device: {device_type})"
    command = "/workflow:ui-design:layout-extract --design-id \"{design_id}\" " +
              (images_input ? "--images \"{images_input}\" " : "") +
              (prompt_text ? "--prompt \"{prompt_text}\" " : "") +
              "--targets \"{targets_string}\" --variants {layout_variants} --device-type \"{device_type}\" --interactive"

    # SlashCommand invocation ATTACHES layout-extract's tasks to current workflow
    # Orchestrator will EXECUTE these attached tasks itself
    SlashCommand(command)

    # After executing all attached tasks, collapse them into phase summary
ELSE:
    REPORT: "✅ Phase 9: Layout (Using Code Import)"
```

### Phase 10: UI Assembly
```bash
command = "/workflow:ui-design:generate --design-id \"{design_id}\"" + (--session ? " --session {session_id}" : "")

total = style_variants × layout_variants × len(inferred_target_list)

REPORT: "🚀 Phase 10: UI Assembly | Matrix: {s}×{l}×{n} = {total} prototypes"
REPORT: "   → Pure assembly: Combining layout templates + design tokens"
REPORT: "   → Device: {device_type} (from layout templates)"
REPORT: "   → Assembly tasks: {total} combinations"

# SlashCommand invocation ATTACHES generate's tasks to current workflow
# Orchestrator will EXECUTE these attached tasks itself
SlashCommand(command)

# After executing all attached tasks, collapse them into phase summary
# When phase finishes, IMMEDIATELY execute Phase 11 (auto-continue)
# Output:
# - {target}-style-{s}-layout-{l}.html (assembled prototypes)
# - {target}-style-{s}-layout-{l}.css
# Note: compare.html and PREVIEW.md will be generated in Phase 11
```

### Phase 11: Generate Preview Files
```bash
REPORT: "🚀 Phase 11: Generate Preview Files"

# Update TodoWrite to reflect preview generation phase
TodoWrite({todos: [
  {"content": "Execute style extraction", "status": "completed", "activeForm": "Executing style extraction"},
  {"content": "Execute animation extraction", "status": "completed", "activeForm": "Executing animation extraction"},
  {"content": "Execute layout extraction", "status": "completed", "activeForm": "Executing layout extraction"},
  {"content": "Execute UI assembly", "status": "completed", "activeForm": "Executing UI assembly"},
  {"content": "Generate preview files", "status": "in_progress", "activeForm": "Generating preview files"}
]})

# Execute preview generation script
Bash(~/.claude/scripts/ui-generate-preview.sh "${base_path}/prototypes")

# Verify output files
IF NOT exists("${base_path}/prototypes/compare.html"):
    ERROR: "Preview generation failed: compare.html not found"
    EXIT 1

IF NOT exists("${base_path}/prototypes/PREVIEW.md"):
    ERROR: "Preview generation failed: PREVIEW.md not found"
    EXIT 1

# Mark preview generation as complete
TodoWrite({todos: [
  {"content": "Execute style extraction", "status": "completed", "activeForm": "Executing style extraction"},
  {"content": "Execute animation extraction", "status": "completed", "activeForm": "Executing animation extraction"},
  {"content": "Execute layout extraction", "status": "completed", "activeForm": "Executing layout extraction"},
  {"content": "Execute UI assembly", "status": "completed", "activeForm": "Executing UI assembly"},
  {"content": "Generate preview files", "status": "completed", "activeForm": "Generating preview files"}
]})

REPORT: "✅ Preview files generated successfully"
REPORT: "   → compare.html (interactive matrix view)"
REPORT: "   → PREVIEW.md (usage instructions)"

# Workflow complete, display final report
```

## TodoWrite Pattern
```javascript
// Initialize IMMEDIATELY after Phase 5 user confirmation to track multi-phase execution (5 orchestrator-level tasks)
TodoWrite({todos: [
  {"content": "Execute style extraction", "status": "in_progress", "activeForm": "Executing style extraction"},
  {"content": "Execute animation extraction", "status": "pending", "activeForm": "Executing animation extraction"},
  {"content": "Execute layout extraction", "status": "pending", "activeForm": "Executing layout extraction"},
  {"content": "Execute UI assembly", "status": "pending", "activeForm": "Executing UI assembly"},
  {"content": "Generate preview files", "status": "pending", "activeForm": "Generating preview files"}
]})

// ⚠️ CRITICAL: Dynamic TodoWrite task attachment strategy:
//
// **Key Concept**: SlashCommand invocation ATTACHES tasks to current workflow.
// Orchestrator EXECUTES these attached tasks itself, not waiting for external completion.
//
// Phase 7-10 SlashCommand Invocation Pattern:
// 1. SlashCommand invocation ATTACHES sub-command tasks to TodoWrite
// 2. TodoWrite expands to include attached tasks
// 3. Orchestrator EXECUTES attached tasks sequentially
// 4. After all attached tasks complete, COLLAPSE them into phase summary
// 5. Update next phase to in_progress
// 6. IMMEDIATELY execute next phase (auto-continue)
//
// Phase 11 Script Execution Pattern:
// 1. Mark "Generate preview files" as in_progress
// 2. Execute preview generation script via Bash tool
// 3. Verify output files (compare.html, PREVIEW.md)
// 4. Mark "Generate preview files" as completed
//
// Benefits:
// ✓ Real-time visibility into sub-command task progress
// ✓ Clean orchestrator-level summary after each phase
// ✓ Clear mental model: SlashCommand = attach tasks, not delegate work
// ✓ Script execution for preview generation (no delegation)
// ✓ Dynamic attachment/collapse maintains clarity
```

## Completion Output
```
✅ UI Design Explore-Auto Workflow Complete!

Architecture: Style-Centric Batch Generation
Run ID: {run_id} | Session: {session_id or "standalone"}
Type: {icon} {target_type} | Device: {device_type} | Matrix: {s}×{l}×{n} = {total} prototypes

Phase 7: {s} complete design systems (style-extract with multi-select)
Phase 9: {n×l} layout templates (layout-extract with multi-select)
  - Device: {device_type} layouts
  - {n} targets × {l} layout variants = {n×l} structural templates
  - User-selected concepts generated in parallel
Phase 10: UI Assembly (generate)
  - Pure assembly: layout templates + design tokens
  - {s}×{l}×{n} = {total} final prototypes
Phase 11: Preview files generated (compare.html, PREVIEW.md)

Assembly Process:
✅ Separation of Concerns: Layout (structure) + Style (tokens) kept separate
✅ Layout Extraction: {n×l} reusable structural templates
✅ Multi-Selection Workflow: User selects multiple variants from generated options
✅ Pure Assembly: No design decisions in generate phase
✅ Device-Optimized: Layouts designed for {device_type}

Design Quality:
✅ Token-Driven Styling: 100% var() usage
✅ Structural Variety: {l} distinct layouts per target (user-selected)
✅ Style Variety: {s} independent design systems (user-selected)
✅ Device-Optimized: Layouts designed for {device_type}

📂 {base_path}/
  ├── .intermediates/          (Intermediate analysis files)
  │   ├── style-analysis/      (analysis-options.toon with embedded user_selection, computed-styles.toon if URL mode)
  │   ├── animation-analysis/  (analysis-options.toon with embedded user_selection, animations-*.toon if URL mode)
  │   └── layout-analysis/     (analysis-options.toon with embedded user_selection, dom-structure-*.toon if URL mode)
  ├── style-extraction/        ({s} complete design systems)
  ├── animation-extraction/    (animation-tokens.toon, animation-guide.md)
  ├── layout-extraction/       ({n×l} layout template files: layout-{target}-{variant}.toon)
  ├── prototypes/              ({total} assembled prototypes)
  └── .run-metadata.toon       (includes device type)

🌐 Preview: {base_path}/prototypes/compare.html
  - Interactive {s}×{l} matrix view
  - Side-by-side comparison
  - Target-specific layouts with style-aware structure
  - Toggle between {n} targets

{icon} Targets: {', '.join(targets)} (type: {target_type})
  - Each target has {l} custom-designed layouts
  - Each style × target × layout has unique HTML structure (not just CSS!)
  - Layout plans stored as structured JSON
  - Optimized for {device_type} viewing

Next: Open compare.html to preview all design variants
```


---
name: workflow:status
description: Generate on-demand task status views from JSON task data with optional task-id filtering for detailed view
argument-hint: "[optional: task-id]"
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Workflow Status Command (/workflow:status)

## Overview
Generates on-demand views from JSON task data. No synchronization needed - all views are calculated from the current state of JSON files.

## Usage
```bash
/workflow:status                    # Show current workflow overview
/workflow:status impl-1             # Show specific task details
/workflow:status --validate         # Validate workflow integrity
```

## Implementation Flow

### Step 1: Find Active Session
```bash
find .workflow/ -name ".active-*" -type f 2>/dev/null | head -1
```

### Step 2: Load Session Data
```bash
cat .workflow/WFS-session/workflow-session.toon
```

### Step 3: Scan Task Files
```bash
find .workflow/WFS-session/.task/ -name "*.toon" -type f 2>/dev/null
```

### Step 4: Generate Task Status
```bash
cat .workflow/WFS-session/.task/impl-1.toon | jq -r '.status'
```

### Step 5: Count Task Progress
```bash
find .workflow/WFS-session/.task/ -name "*.toon" -type f | wc -l
find .workflow/WFS-session/.summaries/ -name "*.md" -type f 2>/dev/null | wc -l
```

### Step 6: Display Overview
```markdown
# Workflow Overview
**Session**: WFS-session-name
**Progress**: 3/8 tasks completed

## Active Tasks
- [IN PROGRESS] impl-1: Current task in progress
- [ ] impl-2: Next pending task

## Completed Tasks
- [COMPLETED] impl-0: Setup completed
```

## Simple Bash Commands

### Basic Operations
- **Find active session**: `find .workflow/ -name ".active-*" -type f`
- **Read session info**: `cat .workflow/session/workflow-session.toon`
- **List tasks**: `find .workflow/session/.task/ -name "*.toon" -type f`
- **Check task status**: `cat task.toon | jq -r '.status'`
- **Count completed**: `find .summaries/ -name "*.md" -type f | wc -l`

### Task Status Check
- **pending**: Not started yet
- **active**: Currently in progress
- **completed**: Finished with summary
- **blocked**: Waiting for dependencies

### Validation Commands
```bash
# Check session exists
test -f .workflow/.active-* && echo "Session active"

# Validate task files
for f in .workflow/session/.task/*.toon; do jq empty "$f" && echo "Valid: $f"; done

# Check summaries match
find .task/ -name "*.toon" -type f | wc -l
find .summaries/ -name "*.md" -type f 2>/dev/null | wc -l
```

## Simple Output Format

### Default Overview
```
Session: WFS-user-auth
Status: ACTIVE
Progress: 5/12 tasks

Current: impl-3 (Building API endpoints)
Next: impl-4 (Adding authentication)
Completed: impl-1, impl-2
```

### Task Details
```
Task: impl-1
Title: Build authentication module
Status: completed
Agent: code-developer
Created: 2025-09-15
Completed: 2025-09-15
Summary: .summaries/impl-1-summary.md
```

### Validation Results
```
Session file valid
8 task files found
3 summaries found
5 tasks pending completion
```
---
name: complete
description: Mark active workflow session as complete, archive with lessons learned, update manifest, remove active flag
examples:
  - /workflow:session:complete
  - /workflow:session:complete --detailed
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Complete Workflow Session (/workflow:session:complete)

## Overview
Mark the currently active workflow session as complete, analyze it for lessons learned, move it to the archive directory, and remove the active flag marker.

## Usage
```bash
/workflow:session:complete           # Complete current active session
/workflow:session:complete --detailed # Show detailed completion summary
```

## Implementation Flow

### Phase 1: Prepare for Archival (Minimal Manual Operations)

**Purpose**: Find active session, move to archive location, pass control to agent. Minimal operations.

#### Step 1.1: Find Active Session and Get Name
```bash
# Find active marker
bash(find .workflow/ -name ".active-*" -type f | head -1)

# Extract session name from marker path
bash(basename .workflow/.active-WFS-session-name | sed 's/^\.active-//')
```
**Output**: Session name `WFS-session-name`

#### Step 1.2: Move Session to Archive
```bash
# Create archive directory if needed
bash(mkdir -p .workflow/.archives/)

# Move session to archive location
bash(mv .workflow/WFS-session-name .workflow/.archives/WFS-session-name)
```
**Result**: Session now at `.workflow/.archives/WFS-session-name/`

### Phase 2: Agent-Orchestrated Completion (All Data Processing)

**Purpose**: Agent analyzes archived session, generates metadata, updates manifest, and removes active marker.

#### Agent Invocation

Invoke `universal-executor` agent to complete the archival process.

**Agent Task**:
```
Task(
  subagent_type="universal-executor",
  description="Complete session archival",
  prompt=`
Complete workflow session archival. Session already moved to archive location.

## Context
- Session: .workflow/.archives/WFS-session-name/
- Active marker: .workflow/.active-WFS-session-name

## Tasks

1. **Extract session data** from workflow-session.toon (session_id, description/topic, started_at/timestamp, completed_at, status)
   - If status != "completed", update it with timestamp

2. **Count files**: tasks (.task/*.toon) and summaries (.summaries/*.md)

3. **Generate lessons**: Use gemini with ~/.claude/workflows/cli-templates/prompts/archive/analysis-simple.txt (fallback: analyze files directly)
   - Return: {successes, challenges, watch_patterns}

4. **Build archive entry**:
   - Calculate: duration_hours, success_rate, tags (3-5 keywords)
   - Construct complete JSON with session_id, description, archived_at, archive_path, metrics, tags, lessons

5. **Update manifest**: Initialize .workflow/.archives/manifest.toon if needed, append entry

6. **Remove active marker**

7. **Return result**: {"status": "success", "session_id": "...", "archived_at": "...", "metrics": {...}, "lessons_summary": {...}}

## Error Handling
- On failure: return {"status": "error", "task": "...", "message": "..."}
- Do NOT remove marker if failed
  `
)
```

**Expected Output**:
- Agent returns JSON result confirming successful archival
- Display completion summary to user based on agent response

## Workflow Execution Strategy

### Two-Phase Approach (Optimized)

**Phase 1: Minimal Manual Setup** (2 simple operations)
- Find active session and extract name
- Move session to archive location
- **No data extraction** - agent handles all data processing
- **No counting** - agent does this from archive location
- **Total**: 2 bash commands (find + move)

**Phase 2: Agent-Driven Completion** (1 agent invocation)
- Extract all session data from archived location
- Count tasks and summaries
- Generate lessons learned analysis
- Build complete archive metadata
- Update manifest
- Remove active marker
- Return success/error result

## Quick Commands

```bash
# Phase 1: Find and move
bash(find .workflow/ -name ".active-*" -type f | head -1)
bash(basename .workflow/.active-WFS-session-name | sed 's/^\.active-//')
bash(mkdir -p .workflow/.archives/)
bash(mv .workflow/WFS-session-name .workflow/.archives/WFS-session-name)

# Phase 2: Agent completes archival
Task(subagent_type="universal-executor", description="Complete session archival", prompt=`...`)
```

## Archive Query Commands

After archival, you can query the manifest:

```bash
# List all archived sessions
jq '.archives[].session_id' .workflow/.archives/manifest.toon

# Find sessions by keyword
jq '.archives[] | select(.description | test("auth"; "i"))' .workflow/.archives/manifest.toon

# Get specific session details
jq '.archives[] | select(.session_id == "WFS-user-auth")' .workflow/.archives/manifest.toon

# List all watch patterns across sessions
jq '.archives[].lessons.watch_patterns[]' .workflow/.archives/manifest.toon
```


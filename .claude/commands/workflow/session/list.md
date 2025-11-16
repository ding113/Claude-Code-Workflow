---
name: list
description: List all workflow sessions with status filtering, shows session metadata and progress information
examples:
  - /workflow:session:list
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# List Workflow Sessions (/workflow:session:list)

## Overview
Display all workflow sessions with their current status, progress, and metadata.

## Usage
```bash
/workflow:session:list       # Show all sessions with status
```

## Implementation Flow

### Step 1: Find All Sessions
```bash
ls .workflow/WFS-* 2>/dev/null
```

### Step 2: Check Active Session
```bash
ls .workflow/.active-* 2>/dev/null | head -1
```

### Step 3: Read Session Metadata
```bash
jq -r '.session_id, .status, .project' .workflow/WFS-session/workflow-session.toon
```

### Step 4: Count Task Progress
```bash
find .workflow/WFS-session/.task/ -name "*.toon" -type f 2>/dev/null | wc -l
find .workflow/WFS-session/.summaries/ -name "*.md" -type f 2>/dev/null | wc -l
```

### Step 5: Get Creation Time
```bash
jq -r '.created_at // "unknown"' .workflow/WFS-session/workflow-session.toon
```

## Simple Bash Commands

### Basic Operations
- **List sessions**: `find .workflow/ -maxdepth 1 -type d -name "WFS-*"`
- **Find active**: `find .workflow/ -name ".active-*" -type f`
- **Read session data**: `jq -r '.session_id, .status' session.toon`
- **Count tasks**: `find .task/ -name "*.toon" -type f | wc -l`
- **Count completed**: `find .summaries/ -name "*.md" -type f 2>/dev/null | wc -l`
- **Get timestamp**: `jq -r '.created_at' session.toon`

## Simple Output Format

### Session List Display
```
Workflow Sessions:

[ACTIVE] WFS-oauth-integration
   Project: OAuth2 authentication system
   Status: active
   Progress: 3/8 tasks completed
   Created: 2025-09-15T10:30:00Z

[PAUSED] WFS-user-profile
   Project: User profile management
   Status: paused
   Progress: 1/5 tasks completed
   Created: 2025-09-14T14:15:00Z

[COMPLETED] WFS-database-migration
   Project: Database schema migration
   Status: completed
   Progress: 4/4 tasks completed
   Created: 2025-09-13T09:00:00Z

Total: 3 sessions (1 active, 1 paused, 1 completed)
```

### Status Indicators
- **[ACTIVE]**: Active session
- **[PAUSED]**: Paused session
- **[COMPLETED]**: Completed session
- **[ERROR]**: Error/corrupted session

### Quick Commands
```bash
# Count all sessions
ls .workflow/WFS-* | wc -l

# Show only active
ls .workflow/.active-* | basename | sed 's/^\.active-//'

# Show recent sessions
ls -t .workflow/WFS-*/workflow-session.toon | head -3
```
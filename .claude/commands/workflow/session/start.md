---
name: start
description: Discover existing sessions or start new workflow session with intelligent session management and conflict detection
argument-hint: [--auto|--new] [optional: task description for new session]
examples:
  - /workflow:session:start
  - /workflow:session:start --auto "implement OAuth2 authentication"
  - /workflow:session:start --new "fix login bug"
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Start Workflow Session (/workflow:session:start)

## Overview
Manages workflow sessions with three operation modes: discovery (manual), auto (intelligent), and force-new.

## Mode 1: Discovery Mode (Default)

### Usage
```bash
/workflow:session:start
```

### Step 1: Check Active Sessions
```bash
bash(ls .workflow/.active-* 2>/dev/null)
```

### Step 2: List All Sessions
```bash
bash(ls -1 .workflow/WFS-* 2>/dev/null | head -5)
```

### Step 3: Display Session Metadata
```bash
bash(cat .workflow/WFS-promptmaster-platform/workflow-session.toon)
```

### Step 4: User Decision
Present session information and wait for user to select or create session.

**Output**: `SESSION_ID: WFS-[user-selected-id]`

## Mode 2: Auto Mode (Intelligent)

### Usage
```bash
/workflow:session:start --auto "task description"
```

### Step 1: Check Active Sessions Count
```bash
bash(ls .workflow/.active-* 2>/dev/null | wc -l)
```

### Step 2a: No Active Sessions → Create New
```bash
# Generate session slug
bash(echo "implement OAuth2 auth" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-50)

# Create directory structure
bash(mkdir -p .workflow/WFS-implement-oauth2-auth/.process)
bash(mkdir -p .workflow/WFS-implement-oauth2-auth/.task)
bash(mkdir -p .workflow/WFS-implement-oauth2-auth/.summaries)

# Create metadata
bash(echo '{"session_id":"WFS-implement-oauth2-auth","project":"implement OAuth2 auth","status":"planning"}' > .workflow/WFS-implement-oauth2-auth/workflow-session.toon)

# Mark as active
bash(touch .workflow/.active-WFS-implement-oauth2-auth)
```

**Output**: `SESSION_ID: WFS-implement-oauth2-auth`

### Step 2b: Single Active Session → Check Relevance
```bash
# Extract session ID
bash(ls .workflow/.active-* 2>/dev/null | head -1 | xargs basename | sed 's/^\.active-//')

# Read project name from metadata
bash(cat .workflow/WFS-promptmaster-platform/workflow-session.toon | grep -o '"project":"[^"]*"' | cut -d'"' -f4)

# Check keyword match (manual comparison)
# If task contains project keywords → Reuse session
# If task unrelated → Create new session (use Step 2a)
```

**Output (reuse)**: `SESSION_ID: WFS-promptmaster-platform`
**Output (new)**: `SESSION_ID: WFS-[new-slug]`

### Step 2c: Multiple Active Sessions → Use First
```bash
# Get first active session
bash(ls .workflow/.active-* 2>/dev/null | head -1 | xargs basename | sed 's/^\.active-//')

# Output warning and session ID
# WARNING: Multiple active sessions detected
# SESSION_ID: WFS-first-session
```

## Mode 3: Force New Mode

### Usage
```bash
/workflow:session:start --new "task description"
```

### Step 1: Generate Unique Session Slug
```bash
# Convert to slug
bash(echo "fix login bug" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-50)

# Check if exists, add counter if needed
bash(ls .workflow/WFS-fix-login-bug 2>/dev/null && echo "WFS-fix-login-bug-2" || echo "WFS-fix-login-bug")
```

### Step 2: Create Session Structure
```bash
bash(mkdir -p .workflow/WFS-fix-login-bug/.process)
bash(mkdir -p .workflow/WFS-fix-login-bug/.task)
bash(mkdir -p .workflow/WFS-fix-login-bug/.summaries)
```

### Step 3: Create Metadata
```bash
bash(echo '{"session_id":"WFS-fix-login-bug","project":"fix login bug","status":"planning"}' > .workflow/WFS-fix-login-bug/workflow-session.toon)
```

### Step 4: Mark Active and Clean Old Markers
```bash
bash(rm .workflow/.active-* 2>/dev/null)
bash(touch .workflow/.active-WFS-fix-login-bug)
```

**Output**: `SESSION_ID: WFS-fix-login-bug`

## Output Format Specification

### Success
```
SESSION_ID: WFS-session-slug
```

### Error
```
ERROR: --auto mode requires task description
ERROR: Failed to create session directory
```

### Analysis (Auto Mode)
```
ANALYSIS: Task relevance = high
DECISION: Reusing existing session
SESSION_ID: WFS-promptmaster-platform
```

## Command Integration

### For /workflow:plan (Use Auto Mode)
```bash
SlashCommand(command="/workflow:session:start --auto \"implement OAuth2 authentication\"")

# Parse session ID from output
grep "^SESSION_ID:" | awk '{print $2}'
```

### For Interactive Workflows (Use Discovery Mode)
```bash
SlashCommand(command="/workflow:session:start")
```

### For New Isolated Work (Use Force New Mode)
```bash
SlashCommand(command="/workflow:session:start --new \"experimental feature\"")
```

## Simple Bash Commands

### Basic Operations
```bash
# Check active sessions
bash(ls .workflow/.active-*)

# List all sessions
bash(ls .workflow/WFS-*)

# Read session metadata
bash(cat .workflow/WFS-[session-id]/workflow-session.toon)

# Create session directories
bash(mkdir -p .workflow/WFS-[session-id]/.process)
bash(mkdir -p .workflow/WFS-[session-id]/.task)
bash(mkdir -p .workflow/WFS-[session-id]/.summaries)

# Mark session as active
bash(touch .workflow/.active-WFS-[session-id])

# Clean active markers
bash(rm .workflow/.active-*)
```

### Generate Session Slug
```bash
bash(echo "Task Description" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-50)
```

### Create Metadata JSON
```bash
bash(echo '{"session_id":"WFS-test","project":"test project","status":"planning"}' > .workflow/WFS-test/workflow-session.toon)
```

## Session ID Format
- Pattern: `WFS-[lowercase-slug]`
- Characters: `a-z`, `0-9`, `-` only
- Max length: 50 characters
- Uniqueness: Add numeric suffix if collision (`WFS-auth-2`, `WFS-auth-3`)
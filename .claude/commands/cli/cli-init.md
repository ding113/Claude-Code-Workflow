---
name: cli-init
description: Generate .gemini/ config directory with settings.json and ignore files based on workspace technology detection
argument-hint: "[--tool gemini] [--output path] [--preview]"
allowed-tools: Bash(*), Read(*), Write(*), Glob(*)
---

# CLI Initialization Command (/cli:cli-init)

## Overview
Initializes CLI tool configurations for the workspace by:
1. Analyzing current workspace using `get_modules_by_depth.sh` to identify technology stacks
2. Generating ignore file (`.geminiignore`) with filtering rules optimized for detected technologies
3. Creating configuration directory (`.gemini/`) with settings.json file

**Supported Tools**: gemini

## Core Functionality

### Configuration Generation
1. **Workspace Analysis**: Runs `get_modules_by_depth.sh` to analyze project structure
2. **Technology Stack Detection**: Identifies tech stacks based on file extensions, directories, and configuration files
3. **Config Creation**: Generates tool-specific configuration directories and settings files
4. **Ignore Rules Generation**: Creates ignore files with filtering patterns for detected technologies

### Generated Files

#### Configuration Directories
Creates tool-specific configuration directories:

**For Gemini** (`.gemini/`):
- `.gemini/settings.json`:
```json
{
  "contextfilename": ["CLAUDE.md","GEMINI.md"]
}
```

#### Ignore Files
Uses gitignore syntax to filter files from CLI tool analysis:
- `.geminiignore` - For Gemini CLI

Content based on detected technologies.

### Supported Technology Stacks

#### Frontend Technologies
- **React/Next.js**: Ignores build artifacts, .next/, node_modules
- **Vue/Nuxt**: Ignores .nuxt/, dist/, .cache/
- **Angular**: Ignores dist/, .angular/, node_modules
- **Webpack/Vite**: Ignores build outputs, cache directories

#### Backend Technologies
- **Node.js**: Ignores node_modules, package-lock.json, npm-debug.log
- **Python**: Ignores __pycache__, .venv, *.pyc, .pytest_cache
- **Java**: Ignores target/, .gradle/, *.class, .mvn/
- **Go**: Ignores vendor/, *.exe, go.sum (when appropriate)
- **C#/.NET**: Ignores bin/, obj/, *.dll, *.pdb

#### Database & Infrastructure
- **Docker**: Ignores .dockerignore, docker-compose.override.yml
- **Kubernetes**: Ignores *.secret.yaml, helm charts temp files
- **Database**: Ignores *.db, *.sqlite, database dumps

### Generated Rules Structure

#### Base Rules (Always Included)
```
# Version Control
.git/
.svn/
.hg/

# OS Files
.DS_Store
Thumbs.db
*.tmp
*.swp

# IDE Files
.vscode/
.idea/
.vs/

# Logs
*.log
logs/
```

#### Technology-Specific Rules
Rules are added based on detected technologies:

**Node.js Projects** (package.json detected):
```
# Node.js
node_modules/
npm-debug.log*
.npm/
.yarn/
package-lock.json
yarn.lock
.pnpm-store/
```

**Python Projects** (requirements.txt, setup.py, pyproject.toml detected):
```
# Python
__pycache__/
*.py[cod]
.venv/
venv/
.pytest_cache/
.coverage
htmlcov/
```

**Java Projects** (pom.xml, build.gradle detected):
```
# Java
target/
.gradle/
*.class
*.jar
*.war
.mvn/
```

## Command Options

### Tool Selection

**Initialize Gemini**:
```bash
/cli:cli-init
```
- Creates `.gemini/` directory with settings.json
- Creates `.geminiignore` file
- Sets contextfilename to "CLAUDE.md"

### Preview Mode
```bash
/cli:cli-init --preview
```
- Shows what would be generated without creating files
- Displays detected technologies, configuration, and ignore rules

### Custom Output Path
```bash
/cli:cli-init --output=.config/
```
- Generates files in specified directory
- Creates directories if they don't exist

### Combined Options
```bash
/cli:cli-init --preview
/cli:cli-init --output=.config/
```

## EXECUTION INSTRUCTIONS - START HERE

**When this command is triggered, follow these exact steps:**

### Step 1: Parse Tool Selection
```bash
# Extract --tool flag (default: gemini)
# Options: gemini
```

### Step 2: Workspace Analysis (MANDATORY FIRST)
```bash
# Analyze workspace structure
bash(~/.claude/scripts/get_modules_by_depth.sh json)
```

### Step 3: Technology Detection
```bash
# Check for common tech stack indicators
bash(find . -name "package.json" -not -path "*/node_modules/*" | head -1)
bash(find . -name "requirements.txt" -o -name "setup.py" -o -name "pyproject.toml" | head -1)
bash(find . -name "pom.xml" -o -name "build.gradle" | head -1)
bash(find . -name "Dockerfile" | head -1)
```

### Step 4: Generate Configuration Files

**For Gemini**:
```bash
# Create .gemini/ directory and settings.json
mkdir -p .gemini
Write({file_path: '.gemini/settings.json', content: '{"contextfilename": "CLAUDE.md"}'})

# Create .geminiignore file with detected technology rules
# Backup existing files if present
```

### Step 5: Validation
```bash
# Verify generated files are valid
bash(ls -la .gemini* 2>/dev/null || echo "Configuration files created")
```

## Implementation Process (Technical Details)

### Phase 1: Tool Selection
1. Parse `--tool` flag from command arguments
2. Determine which configurations to generate:
   - `gemini` (default): Generate .gemini/ and .geminiignore

### Phase 2: Workspace Analysis
1. Execute `get_modules_by_depth.sh json` to get structured project data
2. Parse JSON output to identify directories and files
3. Scan for technology indicators:
   - Configuration files (package.json, requirements.txt, etc.)
   - Directory patterns (src/, tests/, etc.)
   - File extensions (.js, .py, .java, etc.)
4. Detect project name from directory name or package.json

### Phase 3: Technology Detection
```bash
# Technology detection logic
detect_nodejs() {
    [ -f "package.json" ] || find . -name "package.json" -not -path "*/node_modules/*" | head -1
}

detect_python() {
    [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ] || \
    find . -name "*.py" -not -path "*/__pycache__/*" | head -1
}

detect_java() {
    [ -f "pom.xml" ] || [ -f "build.gradle" ] || \
    find . -name "*.java" | head -1
}
```

### Phase 4: Configuration Generation
Create configuration:

1. **Config Directory**:
   - Create `.gemini/` directory if it doesn't exist
   - Generate `settings.json` with contextfilename setting
   - Set contextfilename to "CLAUDE.md" by default

2. **Settings.json Format**:
```json
{
  "contextfilename": "CLAUDE.md"
}
```

### Phase 5: Ignore Rules Generation
1. Start with base rules (always included)
2. Add technology-specific rules based on detection
3. Add workspace-specific patterns if found
4. Sort and deduplicate rules
5. Generate content for `.geminiignore`

### Phase 6: File Creation
1. **Generate config directory**: Create `.gemini/` directory with settings.json
2. **Generate ignore file**: Create organized ignore file with sections
3. **Create backups**: Backup existing files if present
4. **Validate**: Check generated files are valid

## Generated File Format

### Configuration Files
```json
// .gemini/settings.json
{
  "contextfilename": "CLAUDE.md"
}
```

### Ignore Files
```
# .geminiignore
# Generated by Claude Code /cli:cli-init command
# Creation date: 2024-01-15 10:30:00
# Detected technologies: Node.js, Python, Docker
#
# This file uses gitignore syntax to filter files for CLI tool analysis
# Edit this file to customize filtering rules for your project

# ============================================================================
# Base Rules (Always Applied)
# ============================================================================

# Version Control
.git/
.svn/
.hg/

# ============================================================================
# Node.js (Detected: package.json found)
# ============================================================================

node_modules/
npm-debug.log*
.npm/
yarn-error.log
package-lock.json

# ============================================================================
# Python (Detected: requirements.txt, *.py files found)
# ============================================================================

__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.coverage

# ============================================================================
# Docker (Detected: Dockerfile found)
# ============================================================================

.dockerignore
docker-compose.override.yml

# ============================================================================
# Custom Rules (Add your project-specific rules below)
# ============================================================================

```

## Error Handling

### Missing Dependencies
- If `get_modules_by_depth.sh` not found, show error with path to script
- Gracefully handle cases where script fails

### Write Permissions
- Check write permissions before attempting file creation
- Show clear error message if cannot write to target location

### Backup Existing Files
- If `.gemini/` directory exists, create backup as `.gemini.backup/`
- If `.geminiignore` exists, create backup as `.geminiignore.backup`
- Include timestamp in backup filename

## Integration Points

### Workflow Commands
- **After `/cli:plan`**: Suggest running cli-init for better analysis
- **Before analysis**: Recommend updating ignore patterns for cleaner results

### CLI Tool Integration
- Automatically update when new technologies detected
- Integrate with `intelligent-tools-strategy.md` recommendations

## Usage Examples

### Basic Project Setup
```bash
# Initialize Gemini CLI tool
/cli:cli-init

# Preview what would be generated
/cli:cli-init --preview

# Generate in subdirectory
/cli:cli-init --output=.config/
```

### Technology Migration
```bash
# After adding new tech stack (e.g., Docker)
/cli:cli-init  # Regenerates config and ignore files with new rules

# Check what changed
/cli:cli-init --preview  # Compare with existing configuration
```

## Key Benefits

- **Automatic Detection**: No manual configuration needed
- **Technology Aware**: Rules adapted to actual project stack
- **Maintainable**: Clear sections for easy customization
- **Consistent**: Follows gitignore syntax standards
- **Safe**: Creates backups of existing files

## Tool Selection Guide

| Scenario | Command | Result |
|----------|---------|--------|
| **New project setup** | `/cli:cli-init` | Creates .gemini/ and .geminiignore |
| **Preview before commit** | `/cli:cli-init --preview` | Shows what would be generated |
| **Update configurations** | `/cli:cli-init` | Regenerates files with backups |

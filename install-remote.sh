#!/usr/bin/env bash
# Claude Code Workflow (CCW) - Remote Installation Script
# One-liner remote installation for Claude Code Workflow system

set -e  # Exit on error

# Script metadata
SCRIPT_NAME="Claude Code Workflow (CCW) Remote Installer"
INSTALLER_VERSION="2.2.0"
BRANCH="${BRANCH:-main}"

# Version control
VERSION_TYPE="${VERSION_TYPE:-stable}"  # stable, latest, branch
TAG_VERSION=""

# Colors for output
COLOR_RESET='\033[0m'
COLOR_SUCCESS='\033[0;32m'
COLOR_INFO='\033[0;36m'
COLOR_WARNING='\033[0;33m'
COLOR_ERROR='\033[0;31m'

# Variables
INSTALL_GLOBAL=false
INSTALL_DIR=""
FORCE=false
NO_BACKUP=false
NON_INTERACTIVE=false
BACKUP_ALL=false

# Functions
function write_color() {
    local message="$1"
    local color="${2:-$COLOR_RESET}"
    echo -e "${color}${message}${COLOR_RESET}"
}

function show_header() {
    write_color "==== $SCRIPT_NAME v$INSTALLER_VERSION ====" "$COLOR_INFO"
    write_color "========================================================" "$COLOR_INFO"
    echo ""
}

function test_prerequisites() {
    # Test bash version
    if [ "${BASH_VERSINFO[0]}" -lt 2 ]; then
        write_color "ERROR: Bash 2.0 or higher is required" "$COLOR_ERROR"
        write_color "Current version: ${BASH_VERSION}" "$COLOR_ERROR"
        return 1
    fi

    # Test required commands
    for cmd in curl unzip; do
        if ! command -v "$cmd" &> /dev/null; then
            write_color "ERROR: Required command '$cmd' not found" "$COLOR_ERROR"
            write_color "Please install: $cmd" "$COLOR_ERROR"
            return 1
        fi
    done

    # Check for optional but recommended commands
    if ! command -v git &> /dev/null; then
        write_color "WARNING: 'git' not found - version detection may be limited" "$COLOR_WARNING"
        write_color "Hint: Install git for better version tracking" "$COLOR_INFO"
        write_color "      On Ubuntu/Debian: sudo apt-get install git" "$COLOR_INFO"
        write_color "      On WSL: sudo apt-get update && sudo apt-get install git" "$COLOR_INFO"
        echo ""
    else
        write_color "✓ Git available" "$COLOR_SUCCESS"
    fi

    # Test internet connectivity
    if curl -sSf --connect-timeout 10 "https://github.com" &> /dev/null; then
        write_color "✓ Network connection OK" "$COLOR_SUCCESS"
    else
        write_color "ERROR: Cannot connect to GitHub" "$COLOR_ERROR"
        write_color "Please check your network connection and try again." "$COLOR_ERROR"
        echo ""
        write_color "Common causes:" "$COLOR_INFO"
        echo "  • Internet connection is down or unstable"
        echo "  • Firewall or proxy is blocking GitHub access"
        echo "  • DNS resolution issues"
        echo "  • GitHub is temporarily unavailable"
        echo ""
        write_color "Troubleshooting steps:" "$COLOR_INFO"
        echo "  1. Check your internet connection"
        echo "  2. Try accessing https://github.com in your browser"
        echo "  3. If using a proxy, configure it properly"
        echo "  4. Check firewall settings"
        echo "  5. Wait a few minutes and try again"
        echo ""
        return 1
    fi

    return 0
}

function get_temp_directory() {
    local temp_dir
    temp_dir=$(mktemp -d -t claude-code-workflow-install.XXXXXX)
    echo "$temp_dir"
}

function get_latest_release() {
    local api_url="https://api.github.com/repos/ding113/Claude-Code-Workflow/releases/latest"

    if command -v jq &> /dev/null; then
        # Use jq if available
        local tag
        tag=$(curl -fsSL "$api_url" 2>/dev/null | jq -r '.tag_name' 2>/dev/null)
        if [ -n "$tag" ] && [ "$tag" != "null" ]; then
            echo "$tag"
            return 0
        fi
    else
        # Fallback: parse JSON with grep/sed
        local tag
        tag=$(curl -fsSL "$api_url" 2>/dev/null | grep -o '"tag_name":\s*"[^"]*"' | sed 's/"tag_name":\s*"\([^"]*\)"/\1/')
        if [ -n "$tag" ]; then
            echo "$tag"
            return 0
        fi
    fi

    write_color "WARNING: Failed to fetch latest release" "$COLOR_WARNING" >&2
    write_color "Falling back to 'main' branch" "$COLOR_INFO" >&2
    return 1
}

function download_repository() {
    local temp_dir="$1"
    local version_type="${2:-stable}"
    local branch="${3:-main}"
    local tag="${4:-}"
    local repo_url="https://github.com/ding113/Claude-Code-Workflow"
    local zip_url=""
    local download_type=""

    # Determine download URL based on version type
    case "$version_type" in
        stable)
            # Download latest stable release
            if [ -z "$tag" ]; then
                tag=$(get_latest_release)
                if [ -z "$tag" ]; then
                    # Fallback to main branch if API fails
                    zip_url="${repo_url}/archive/refs/heads/main.zip"
                    download_type="main branch (fallback)"
                else
                    zip_url="${repo_url}/archive/refs/tags/${tag}.zip"
                    download_type="stable release $tag"
                fi
            else
                zip_url="${repo_url}/archive/refs/tags/${tag}.zip"
                download_type="stable release $tag"
            fi
            ;;
        latest)
            # Download latest main branch
            zip_url="${repo_url}/archive/refs/heads/main.zip"
            download_type="latest main branch"
            ;;
        branch)
            # Download specific branch
            zip_url="${repo_url}/archive/refs/heads/${branch}.zip"
            download_type="branch $branch"
            ;;
        *)
            write_color "ERROR: Invalid version type: $version_type" "$COLOR_ERROR" >&2
            return 1
            ;;
    esac

    local zip_path="${temp_dir}/repo.zip"

    write_color "Downloading from GitHub..." "$COLOR_INFO" >&2
    write_color "Source: $repo_url" "$COLOR_INFO" >&2
    write_color "Type: $download_type" "$COLOR_INFO" >&2

    # Download with curl
    local download_error=""
    if download_error=$(curl -fsSL -o "$zip_path" "$zip_url" 2>&1); then
        # Verify the download
        if [ -f "$zip_path" ]; then
            local file_size
            file_size=$(du -h "$zip_path" 2>/dev/null | cut -f1)

            # Check if file is empty
            if [ ! -s "$zip_path" ]; then
                echo "" >&2
                write_color "ERROR: Downloaded file is empty (0 bytes)" "$COLOR_ERROR" >&2
                echo "" >&2
                write_color "Common causes:" "$COLOR_INFO" >&2
                echo "  • Network connection was interrupted" >&2
                echo "  • Invalid version tag or branch name" >&2
                echo "  • GitHub API or server issues" >&2
                echo "" >&2
                write_color "Troubleshooting steps:" "$COLOR_INFO" >&2
                echo "  1. Verify the version tag or branch name is correct" >&2
                echo "  2. Wait a few minutes and try again" >&2
                echo "  3. Try a different version (stable/latest)" >&2
                echo "  4. Check GitHub status at https://www.githubstatus.com" >&2
                echo "" >&2
                write_color "Download URL: $zip_url" "$COLOR_INFO" >&2
                echo "" >&2
                return 1
            fi

            write_color "✓ Download complete ($file_size)" "$COLOR_SUCCESS" >&2

            # Output path to stdout for capture
            echo "$zip_path"
            return 0
        else
            write_color "ERROR: Downloaded file does not exist" "$COLOR_ERROR" >&2
            return 1
        fi
    else
        echo "" >&2
        write_color "ERROR: Download failed" "$COLOR_ERROR" >&2
        echo "" >&2
        write_color "Common causes:" "$COLOR_INFO" >&2
        echo "  • Network connection interrupted during download" >&2
        echo "  • GitHub API rate limit exceeded" >&2
        echo "  • Invalid version tag or branch name" >&2
        echo "  • Temporary GitHub service issues" >&2
        echo "  • Firewall or proxy blocking the download" >&2
        echo "" >&2
        write_color "Troubleshooting steps:" "$COLOR_INFO" >&2
        echo "  1. Check your internet connection stability" >&2
        echo "  2. Wait a few minutes and try again (rate limit resets)" >&2
        echo "  3. Verify the version tag or branch name is correct" >&2
        echo "  4. Try a different version (stable/latest)" >&2
        echo "  5. Check GitHub status at https://www.githubstatus.com" >&2
        echo "  6. If using a proxy, verify it's configured correctly" >&2
        echo "" >&2
        write_color "Download URL: $zip_url" "$COLOR_INFO" >&2
        if [ -n "$download_error" ]; then
            write_color "Error details: $download_error" "$COLOR_ERROR" >&2
        fi
        echo "" >&2
        return 1
    fi
}

function extract_repository() {
    local zip_path="$1"
    local temp_dir="$2"

    write_color "Extracting files..." "$COLOR_INFO" >&2

    # Verify zip file exists
    if [ ! -f "$zip_path" ]; then
        write_color "ERROR: ZIP file not found: $zip_path" "$COLOR_ERROR" >&2
        return 1
    fi

    # Verify zip file is not empty
    if [ ! -s "$zip_path" ]; then
        echo "" >&2
        write_color "ERROR: ZIP file is empty (0 bytes)" "$COLOR_ERROR" >&2
        echo "" >&2
        write_color "Common causes:" "$COLOR_INFO" >&2
        echo "  • Download was interrupted" >&2
        echo "  • Network connection issues during download" >&2
        echo "  • Server-side issues" >&2
        echo "" >&2
        write_color "Troubleshooting steps:" "$COLOR_INFO" >&2
        echo "  1. Try downloading again" >&2
        echo "  2. Check your network connection" >&2
        echo "  3. Wait a few minutes and retry" >&2
        echo "" >&2
        return 1
    fi

    # Extract with unzip
    local extract_error=""
    if extract_error=$(unzip -q "$zip_path" -d "$temp_dir" 2>&1); then
        # Find the extracted directory
        local repo_dir
        repo_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "Claude-Code-Workflow-*" 2>/dev/null | head -n 1)

        if [ -n "$repo_dir" ] && [ -d "$repo_dir" ]; then
            write_color "✓ Extraction complete: $repo_dir" "$COLOR_SUCCESS" >&2
            # Output path to stdout for capture
            echo "$repo_dir"
            return 0
        else
            echo "" >&2
            write_color "ERROR: Could not find extracted repository directory" "$COLOR_ERROR" >&2
            write_color "Temp directory contents:" "$COLOR_INFO" >&2
            ls -la "$temp_dir" >&2
            echo "" >&2
            return 1
        fi
    else
        echo "" >&2
        write_color "ERROR: Extraction failed" "$COLOR_ERROR" >&2
        echo "" >&2
        write_color "Common causes:" "$COLOR_INFO" >&2
        echo "  • Downloaded file is corrupted or incomplete" >&2
        echo "  • ZIP file format is invalid" >&2
        echo "  • Insufficient disk space" >&2
        echo "  • Permission issues on temporary directory" >&2
        echo "" >&2
        write_color "Troubleshooting steps:" "$COLOR_INFO" >&2
        echo "  1. Try downloading again (network may have interrupted)" >&2
        echo "  2. Check available disk space: df -h" >&2
        echo "  3. Verify temporary directory permissions" >&2
        echo "  4. Check if 'unzip' command is working: unzip -v" >&2
        echo "" >&2
        write_color "ZIP file: $zip_path" "$COLOR_INFO" >&2
        if [ -f "$zip_path" ]; then
            local zip_size
            zip_size=$(du -h "$zip_path" 2>/dev/null | cut -f1)
            write_color "ZIP size: $zip_size" "$COLOR_INFO" >&2
        fi
        if [ -n "$extract_error" ]; then
            write_color "Error details: $extract_error" "$COLOR_ERROR" >&2
        fi
        echo "" >&2
        return 1
    fi
}

function invoke_local_installer() {
    local repo_dir="$1"
    local version_info="$2"
    local branch_info="$3"
    local commit_sha="$4"
    local installer_path="${repo_dir}/Install-Claude.sh"

    # Make installer executable
    if [ -f "$installer_path" ]; then
        chmod +x "$installer_path"
    else
        write_color "ERROR: Install-Claude.sh not found" "$COLOR_ERROR"
        return 1
    fi

    write_color "Running local installer..." "$COLOR_INFO"
    echo ""

    # Build parameters for local installer
    local params=()

    if [ "$INSTALL_GLOBAL" = true ]; then
        params+=("-InstallMode" "Global")
    fi

    if [ -n "$INSTALL_DIR" ]; then
        params+=("-InstallMode" "Path" "-TargetPath" "$INSTALL_DIR")
    fi

    if [ "$FORCE" = true ]; then
        params+=("-Force")
    fi

    if [ "$NO_BACKUP" = true ]; then
        params+=("-NoBackup")
    fi

    if [ "$NON_INTERACTIVE" = true ]; then
        params+=("-NonInteractive")
    fi

    if [ "$BACKUP_ALL" = true ]; then
        params+=("-BackupAll")
    fi

    # Pass version, branch, and commit information
    if [ -n "$version_info" ]; then
        params+=("-SourceVersion" "$version_info")
    fi

    if [ -n "$branch_info" ]; then
        params+=("-SourceBranch" "$branch_info")
    fi

    if [ -n "$commit_sha" ]; then
        params+=("-SourceCommit" "$commit_sha")
    fi

    # Execute installer
    if (cd "$repo_dir" && "$installer_path" "${params[@]}"); then
        return 0
    else
        write_color "Installation script failed" "$COLOR_ERROR"
        return 1
    fi
}

function cleanup_temp_files() {
    local temp_dir="$1"

    if [ -d "$temp_dir" ]; then
        if rm -rf "$temp_dir"; then
            write_color "✓ Temporary files cleaned up" "$COLOR_INFO"
        else
            write_color "WARNING: Failed to clean temporary files" "$COLOR_WARNING"
        fi
    fi
}

function wait_for_user() {
    local message="${1:-Press Enter to continue...}"

    if [ "$NON_INTERACTIVE" != true ]; then
        echo ""
        write_color "$message" "$COLOR_INFO"
        read -r
        echo ""
    fi
}

function parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                VERSION_TYPE="$2"
                if [[ ! "$VERSION_TYPE" =~ ^(stable|latest|branch)$ ]]; then
                    write_color "ERROR: Invalid version type: $VERSION_TYPE" "$COLOR_ERROR"
                    write_color "Valid options: stable, latest, branch" "$COLOR_ERROR"
                    exit 1
                fi
                shift 2
                ;;
            --tag)
                TAG_VERSION="$2"
                shift 2
                ;;
            --branch)
                BRANCH="$2"
                shift 2
                ;;
            --global)
                INSTALL_GLOBAL=true
                shift
                ;;
            --directory)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --no-backup)
                NO_BACKUP=true
                shift
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --backup-all)
                BACKUP_ALL=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                write_color "Unknown option: $1" "$COLOR_ERROR"
                show_help
                exit 1
                ;;
        esac
    done
}

function show_help() {
    cat << EOF
$SCRIPT_NAME v$INSTALLER_VERSION

Usage: $0 [OPTIONS]

Version Options:
    --version TYPE        Version type: stable (default), latest, or branch
    --tag TAG             Specific release tag (e.g., v3.2.0) - for stable version
    --branch BRANCH       Branch name (default: main) - for branch version

Installation Options:
    --global              Install to global user directory (~/.claude)
    --directory DIR       Install to custom directory
    --force               Force installation without prompts
    --no-backup           Skip backup creation
    --non-interactive     Non-interactive mode (no prompts)
    --backup-all          Backup all files before installation
    --help                Show this help message

Examples:
    # Install latest stable release (recommended)
    $0

    # Install specific stable version
    $0 --version stable --tag v3.2.0

    # Install latest development version
    $0 --version latest

    # Install from specific branch
    $0 --version branch --branch feature/new-feature

    # Global installation without prompts
    $0 --global --non-interactive

    # Custom directory installation
    $0 --directory /opt/claude-code-workflow

Repository: https://github.com/ding113/Claude-Code-Workflow

EOF
}

function show_version_menu() {
    local latest_version="$1"
    local latest_date="$2"
    local commit_id="$3"
    local commit_date="$4"

    echo ""
    write_color "====================================================" "$COLOR_INFO"
    write_color "            Version Selection Menu" "$COLOR_INFO"
    write_color "====================================================" "$COLOR_INFO"
    echo ""

    # Option 1: Latest Stable
    write_color "1) Latest Stable Release (Recommended)" "$COLOR_SUCCESS"
    if [ -n "$latest_version" ] && [ "$latest_version" != "Unknown" ]; then
        echo "   |-- Version: $latest_version"
        if [ -n "$latest_date" ]; then
            echo "   |-- Released: $latest_date"
        fi
        echo "   \-- Production-ready"
    else
        echo "   |-- Version: Auto-detected from GitHub"
        echo "   \-- Production-ready"
    fi
    echo ""

    # Option 2: Latest Development
    write_color "2) Latest Development Version" "$COLOR_WARNING"
    echo "   |-- Branch: main"
    if [ -n "$commit_id" ] && [ -n "$commit_date" ]; then
        echo "   |-- Commit: $commit_id"
        echo "   |-- Updated: $commit_date"
    fi
    echo "   |-- Cutting-edge features"
    echo "   \-- May contain experimental changes"
    echo ""

    # Option 3: Specific Version
    write_color "3) Specific Release Version" "$COLOR_INFO"
    echo "   |-- Install a specific tagged release"
    echo "   \-- Recent: v3.2.0, v3.1.0, v3.0.1"
    echo ""

    write_color "====================================================" "$COLOR_INFO"
    echo ""
}

function get_user_version_choice() {
    if [ "$NON_INTERACTIVE" = true ] || [ "$FORCE" = true ]; then
        # Non-interactive mode: use default stable version
        echo "stable"
        return 0
    fi

    # Detect latest stable version and commit info
    write_color "Detecting latest release and commits..." "$COLOR_INFO"
    local latest_version="Unknown"
    local latest_date=""
    local commit_id=""
    local commit_date=""

    # Get latest release info
    local release_data
    release_data=$(curl -fsSL --connect-timeout 5 "https://api.github.com/repos/ding113/Claude-Code-Workflow/releases/latest" 2>/dev/null)

    if [ -n "$release_data" ]; then
        if command -v jq &> /dev/null; then
            latest_version=$(echo "$release_data" | jq -r '.tag_name' 2>/dev/null)
            local published_at=$(echo "$release_data" | jq -r '.published_at' 2>/dev/null)
            if [ -n "$published_at" ] && [ "$published_at" != "null" ]; then
                # Convert UTC to local time
                if command -v date &> /dev/null; then
                    latest_date=$(date -d "$published_at" '+%Y-%m-%d %H:%M' 2>/dev/null || date -jf '%Y-%m-%dT%H:%M:%SZ' "$published_at" '+%Y-%m-%d %H:%M' 2>/dev/null)
                fi
            fi
        else
            latest_version=$(echo "$release_data" | grep -o '"tag_name":\s*"[^"]*"' | sed 's/"tag_name":\s*"\([^"]*\)"/\1/')
            local published_at=$(echo "$release_data" | grep -o '"published_at":\s*"[^"]*"' | sed 's/"published_at":\s*"\([^"]*\)"/\1/')
            if [ -n "$published_at" ]; then
                # Convert UTC to local time
                if command -v date &> /dev/null; then
                    latest_date=$(date -d "$published_at" '+%Y-%m-%d %H:%M' 2>/dev/null || date -jf '%Y-%m-%dT%H:%M:%SZ' "$published_at" '+%Y-%m-%d %H:%M' 2>/dev/null)
                fi
            fi
        fi
    fi

    if [ -n "$latest_version" ] && [ "$latest_version" != "null" ] && [ "$latest_version" != "Unknown" ]; then
        write_color "Latest stable: $latest_version ($latest_date)" "$COLOR_SUCCESS"
    else
        latest_version="Unknown"
        write_color "Could not detect latest release" "$COLOR_WARNING"
    fi

    # Get latest commit info
    local commit_data
    commit_data=$(curl -fsSL --connect-timeout 5 "https://api.github.com/repos/ding113/Claude-Code-Workflow/commits/main" 2>/dev/null)

    if [ -n "$commit_data" ]; then
        if command -v jq &> /dev/null; then
            commit_id=$(echo "$commit_data" | jq -r '.sha' 2>/dev/null | cut -c1-7)
            local committer_date=$(echo "$commit_data" | jq -r '.commit.committer.date' 2>/dev/null)
            if [ -n "$committer_date" ] && [ "$committer_date" != "null" ]; then
                # Convert UTC to local time
                if command -v date &> /dev/null; then
                    commit_date=$(date -d "$committer_date" '+%Y-%m-%d %H:%M' 2>/dev/null || date -jf '%Y-%m-%dT%H:%M:%SZ' "$committer_date" '+%Y-%m-%d %H:%M' 2>/dev/null)
                fi
            fi
        else
            commit_id=$(echo "$commit_data" | grep -o '"sha":\s*"[^"]*"' | head -1 | sed 's/"sha":\s*"\([^"]*\)"/\1/' | cut -c1-7)
            local committer_date=$(echo "$commit_data" | grep -o '"date":\s*"[^"]*"' | head -1 | sed 's/"date":\s*"\([^"]*\)"/\1/')
            if [ -n "$committer_date" ]; then
                # Convert UTC to local time
                if command -v date &> /dev/null; then
                    commit_date=$(date -d "$committer_date" '+%Y-%m-%d %H:%M' 2>/dev/null || date -jf '%Y-%m-%dT%H:%M:%SZ' "$committer_date" '+%Y-%m-%d %H:%M' 2>/dev/null)
                fi
            fi
        fi
    fi

    if [ -n "$commit_id" ] && [ -n "$commit_date" ]; then
        write_color "Latest commit: $commit_id ($commit_date)" "$COLOR_SUCCESS"
    else
        write_color "Could not detect latest commit" "$COLOR_WARNING"
    fi

    show_version_menu "$latest_version" "$latest_date" "$commit_id" "$commit_date"

    read -p "Select version to install (1-3, default: 1): " choice

    case "$choice" in
        2)
            echo ""
            write_color "✓ Selected: Latest Development Version (main branch)" "$COLOR_SUCCESS"
            VERSION_TYPE="latest"
            TAG_VERSION=""
            BRANCH="main"
            ;;
        3)
            echo ""
            write_color "Available recent releases:" "$COLOR_INFO"
            echo "  v3.2.0, v3.1.0, v3.0.1, v3.0.0"
            echo ""
            read -p "Enter version tag (e.g., v3.2.0): " tag_input

            if [ -z "$tag_input" ]; then
                write_color "⚠ No tag specified, using latest stable" "$COLOR_WARNING"
                VERSION_TYPE="stable"
                TAG_VERSION=""
            else
                echo ""
                write_color "✓ Selected: Specific Version $tag_input" "$COLOR_SUCCESS"
                VERSION_TYPE="stable"
                TAG_VERSION="$tag_input"
            fi
            BRANCH="main"
            ;;
        *)
            echo ""
            if [ "$latest_version" != "Unknown" ]; then
                write_color "✓ Selected: Latest Stable Release ($latest_version)" "$COLOR_SUCCESS"
            else
                write_color "✓ Selected: Latest Stable Release (auto-detect)" "$COLOR_SUCCESS"
            fi
            VERSION_TYPE="stable"
            TAG_VERSION=""
            BRANCH="main"
            ;;
    esac
}

function main() {
    show_header

    write_color "This will download and install Claude Code Workflow System from GitHub." "$COLOR_INFO"
    echo ""

    # Test prerequisites
    write_color "Checking system requirements..." "$COLOR_INFO"
    if ! test_prerequisites; then
        wait_for_user "System check failed! Press Enter to exit..."
        exit 1
    fi

    # Get version choice from user (interactive menu)
    get_user_version_choice

    # Determine version information for display
    local version_info=""
    case "$VERSION_TYPE" in
        stable)
            if [ -n "$TAG_VERSION" ]; then
                version_info="Stable release: $TAG_VERSION"
            else
                version_info="Latest stable release (auto-detected)"
            fi
            ;;
        latest)
            version_info="Latest main branch (development)"
            ;;
        branch)
            version_info="Custom branch: $BRANCH"
            ;;
    esac

    # Confirm installation
    if [ "$NON_INTERACTIVE" != true ] && [ "$FORCE" != true ]; then
        echo ""
        write_color "INSTALLATION DETAILS:" "$COLOR_INFO"
        echo "- Repository: https://github.com/ding113/Claude-Code-Workflow"
        echo "- Version: $version_info"
        echo "- Features: Intelligent workflow orchestration with multi-agent coordination"
        echo ""
        write_color "SECURITY NOTE:" "$COLOR_WARNING"
        echo "- This script will download and execute code from GitHub"
        echo "- Please ensure you trust this source"
        echo ""

        read -p "Continue with installation? (y/N) " -r choice
        if [[ ! $choice =~ ^[Yy]$ ]]; then
            write_color "Installation cancelled" "$COLOR_WARNING"
            exit 0
        fi
    fi

    # Create temp directory
    local temp_dir
    temp_dir=$(get_temp_directory)
    write_color "Temporary directory: $temp_dir" "$COLOR_INFO"

    local success=false

    # Download repository
    local zip_path
    write_color "Starting download process..." "$COLOR_INFO"
    zip_path=$(download_repository "$temp_dir" "$VERSION_TYPE" "$BRANCH" "$TAG_VERSION")
    local download_status=$?

    if [ $download_status -eq 0 ] && [ -n "$zip_path" ] && [ -f "$zip_path" ]; then
        write_color "Download successful: $zip_path" "$COLOR_SUCCESS"

        # Extract repository
        local repo_dir
        write_color "Starting extraction process..." "$COLOR_INFO"
        repo_dir=$(extract_repository "$zip_path" "$temp_dir")
        local extract_status=$?

        if [ $extract_status -eq 0 ] && [ -n "$repo_dir" ] && [ -d "$repo_dir" ]; then
            write_color "Extraction successful: $repo_dir" "$COLOR_SUCCESS"

            # Get commit SHA from the downloaded repository first
            local commit_sha=""
            write_color "Detecting version information..." "$COLOR_INFO"

            if command -v git &> /dev/null && [ -d "$repo_dir/.git" ]; then
                # Try to get from git repository
                commit_sha=$(cd "$repo_dir" && git rev-parse --short HEAD 2>/dev/null || echo "")
                if [ -n "$commit_sha" ]; then
                    write_color "✓ Version detected from git: $commit_sha" "$COLOR_SUCCESS"
                fi
            fi

            if [ -z "$commit_sha" ]; then
                # Fallback: try to get from GitHub API
                write_color "Fetching version from GitHub API..." "$COLOR_INFO"
                local temp_branch="main"
                [ "$VERSION_TYPE" = "branch" ] && temp_branch="$BRANCH"

                local commit_data
                commit_data=$(curl -fsSL --connect-timeout 10 "https://api.github.com/repos/ding113/Claude-Code-Workflow/commits/$temp_branch" 2>/dev/null)

                if [ -n "$commit_data" ]; then
                    if command -v jq &> /dev/null; then
                        commit_sha=$(echo "$commit_data" | jq -r '.sha' 2>/dev/null | cut -c1-7)
                    else
                        commit_sha=$(echo "$commit_data" | grep -o '"sha": *"[^"]*"' | head -1 | cut -d'"' -f4 | cut -c1-7)
                    fi
                fi

                if [ -n "$commit_sha" ] && [ "$commit_sha" != "null" ]; then
                    write_color "✓ Version detected from API: $commit_sha" "$COLOR_SUCCESS"
                else
                    write_color "WARNING: Could not detect version, using 'unknown'" "$COLOR_WARNING"
                    commit_sha="unknown"
                fi
            fi

            # Determine version and branch information to pass
            local version_to_pass=""
            local branch_to_pass=""

            if [ -n "$TAG_VERSION" ]; then
                # Specific tag version - remove 'v' prefix
                version_to_pass="${TAG_VERSION#v}"
            elif [ "$VERSION_TYPE" = "stable" ]; then
                # Auto-detected latest stable
                local latest_tag
                latest_tag=$(get_latest_release)
                if [ -n "$latest_tag" ]; then
                    version_to_pass="${latest_tag#v}"
                else
                    # Fallback: use commit SHA as version
                    version_to_pass="dev-$commit_sha"
                fi
            else
                # Latest development or branch - use commit SHA as version
                version_to_pass="dev-$commit_sha"
            fi

            if [ "$VERSION_TYPE" = "branch" ]; then
                branch_to_pass="$BRANCH"
            elif [ "$VERSION_TYPE" = "latest" ]; then
                branch_to_pass="main"
            elif [ -n "$TAG_VERSION" ]; then
                branch_to_pass="$TAG_VERSION"
            else
                branch_to_pass="main"
            fi

            write_color "Version info: $version_to_pass (branch: $branch_to_pass, commit: $commit_sha)" "$COLOR_INFO"

            # Run local installer with version information
            if invoke_local_installer "$repo_dir" "$version_to_pass" "$branch_to_pass" "$commit_sha"; then
                success=true
                echo ""
                write_color "✓ Remote installation completed successfully!" "$COLOR_SUCCESS"
            else
                write_color "ERROR: Installation script failed" "$COLOR_ERROR"
            fi
        else
            write_color "ERROR: Extraction failed (status: $extract_status)" "$COLOR_ERROR"
            if [ ! -f "$zip_path" ]; then
                write_color "ZIP file does not exist: $zip_path" "$COLOR_ERROR"
            elif [ ! -s "$zip_path" ]; then
                write_color "ZIP file is empty: $zip_path" "$COLOR_ERROR"
            fi
        fi
    else
        write_color "ERROR: Download failed (status: $download_status)" "$COLOR_ERROR"
        if [ -z "$zip_path" ]; then
            write_color "Download did not return a file path" "$COLOR_ERROR"
        elif [ ! -f "$zip_path" ]; then
            write_color "Downloaded file does not exist: $zip_path" "$COLOR_ERROR"
        fi
    fi

    # Cleanup
    cleanup_temp_files "$temp_dir"

    if [ "$success" = true ]; then
        echo ""
        write_color "Next steps:" "$COLOR_INFO"
        echo "1. Review CLAUDE.md for project-specific guidelines"
        echo "2. Try /workflow commands for Agent coordination"
        echo "3. Use /update-memory to manage distributed documentation"

        wait_for_user "Remote installation done! Press Enter to exit..."
        exit 0
    else
        echo ""
        wait_for_user "Installation failed! Press Enter to exit..."
        exit 1
    fi
}

# Parse command line arguments
parse_arguments "$@"

# Run main function
main

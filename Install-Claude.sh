#!/usr/bin/env bash
# Claude Code Workflow System Interactive Installer
# Installation script for Claude Code Workflow System with Agent coordination and distributed memory system.
# Installs globally to user profile directory (~/.claude) by default.

set -e  # Exit on error

# Script metadata
SCRIPT_NAME="Claude Code Workflow System Installer"
VERSION="2.1.0"

# Colors for output
COLOR_RESET='\033[0m'
COLOR_SUCCESS='\033[0;32m'
COLOR_INFO='\033[0;36m'
COLOR_WARNING='\033[0;33m'
COLOR_ERROR='\033[0;31m'
COLOR_PROMPT='\033[0;35m'

# Default parameters
INSTALL_MODE=""
TARGET_PATH=""
FORCE=false
NON_INTERACTIVE=false
BACKUP_ALL=true  # Enabled by default
NO_BACKUP=false
UNINSTALL=false  # Uninstall mode
SOURCE_VERSION=""  # Version from remote installer
SOURCE_BRANCH=""   # Branch from remote installer
SOURCE_COMMIT=""   # Commit SHA from remote installer

# Global manifest directory location
MANIFEST_DIR="${HOME}/.claude-manifests"

# Functions
function write_color() {
    local message="$1"
    local color="${2:-$COLOR_RESET}"
    echo -e "${color}${message}${COLOR_RESET}"
}

function show_banner() {
    echo ""
    # CLAUDE - Cyan color
    write_color '  ______   __                            __                   ' "$COLOR_INFO"
    write_color ' /      \ |  \                          |  \                 ' "$COLOR_INFO"
    write_color '|  $$$$$$\| $$  ______   __    __   ____| $$  ______        ' "$COLOR_INFO"
    write_color '| $$   \$$| $$ |      \ |  \  |  \ /      $$ /      \       ' "$COLOR_INFO"
    write_color '| $$      | $$  \$$$$$$\| $$  | $$|  $$$$$$$|  $$$$$$\      ' "$COLOR_INFO"
    write_color '| $$   __ | $$ /      $$| $$  | $$| $$  | $$| $$    $$      ' "$COLOR_INFO"
    write_color '| $$__/  \| $$|  $$$$$$$| $$__/ $$| $$__| $$| $$$$$$$$      ' "$COLOR_INFO"
    write_color ' \$$    $$| $$ \$$    $$ \$$    $$ \$$    $$ \$$     \       ' "$COLOR_INFO"
    write_color '  \$$$$$$  \$$  \$$$$$$$  \$$$$$$   \$$$$$$$  \$$$$$$$        ' "$COLOR_INFO"
    echo ""

    # CODE - Green color
    write_color ' ______                   __                  ' "$COLOR_SUCCESS"
    write_color '/      \                 |  \                ' "$COLOR_SUCCESS"
    write_color '|  $$$$$$\  ______    ____| $$  ______        ' "$COLOR_SUCCESS"
    write_color '| $$   \$$ /      \  /      $$ /      \       ' "$COLOR_SUCCESS"
    write_color '| $$      |  $$$$$$\|  $$$$$$$|  $$$$$$\      ' "$COLOR_SUCCESS"
    write_color '| $$   __ | $$  | $$| $$  | $$| $$    $$      ' "$COLOR_SUCCESS"
    write_color '| $$__/  \| $$__/ $$| $$__| $$| $$$$$$$$      ' "$COLOR_SUCCESS"
    write_color ' \$$    $$ \$$    $$ \$$    $$ \$$     \      ' "$COLOR_SUCCESS"
    write_color '  \$$$$$$   \$$$$$$   \$$$$$$$  \$$$$$$$       ' "$COLOR_SUCCESS"
    echo ""

    # WORKFLOW - Yellow color
    write_color '__       __                      __         ______   __                         ' "$COLOR_WARNING"
    write_color '|  \  _  |  \                    |  \       /      \ |  \                        ' "$COLOR_WARNING"
    write_color '| $$ / \ | $$  ______    ______  | $$   __ |  $$$$$$\| $$  ______   __   __   __ ' "$COLOR_WARNING"
    write_color '| $$/  $\| $$ /      \  /      \ | $$  /  \| $$_  \$$| $$ /      \ |  \ |  \ |  \' "$COLOR_WARNING"
    write_color '| $$  $$$\ $$|  $$$$$$\|  $$$$$$\| $$_/  $$| $$ \    | $$|  $$$$$$\| $$ | $$ | $$' "$COLOR_WARNING"
    write_color '| $$ $$\$$\$$| $$  | $$| $$   \$$| $$   $$ | $$$$    | $$| $$  | $$| $$ | $$ | $$' "$COLOR_WARNING"
    write_color '| $$$$  \$$$$| $$__/ $$| $$      | $$$$$$\ | $$      | $$| $$__/ $$| $$_/ $$_/ $$' "$COLOR_WARNING"
    write_color '| $$$    \$$$ \$$    $$| $$      | $$  \$$\| $$      | $$ \$$    $$ \$$   $$   $$' "$COLOR_WARNING"
    write_color ' \$$      \$$  \$$$$$$  \$$       \$$   \$$ \$$       \$$  \$$$$$$   \$$$$$\$$$$' "$COLOR_WARNING"
    echo ""
}

function show_header() {
    show_banner
    write_color "    $SCRIPT_NAME v$VERSION" "$COLOR_INFO"
    write_color "    Unified workflow system with comprehensive coordination" "$COLOR_INFO"
    write_color "========================================================================" "$COLOR_INFO"

    if [ "$NO_BACKUP" = true ]; then
        write_color "WARNING: Backup disabled - existing files will be overwritten!" "$COLOR_WARNING"
    else
        write_color "Auto-backup enabled - existing files will be backed up" "$COLOR_SUCCESS"
    fi
    echo ""
}

function test_prerequisites() {
    # Test bash version
    if [ "${BASH_VERSINFO[0]}" -lt 2 ]; then
        write_color "ERROR: Bash 2.0 or higher is required" "$COLOR_ERROR"
        write_color "Current version: ${BASH_VERSION}" "$COLOR_ERROR"
        return 1
    fi

    # Test source files exist
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local claude_dir="$script_dir/.claude"
    local claude_md="$script_dir/CLAUDE.md"
    local codex_dir="$script_dir/.codex"
    local gemini_dir="$script_dir/.gemini"

    if [ ! -d "$claude_dir" ]; then
        write_color "ERROR: .claude directory not found in $script_dir" "$COLOR_ERROR"
        return 1
    fi

    if [ ! -f "$claude_md" ]; then
        write_color "ERROR: CLAUDE.md file not found in $script_dir" "$COLOR_ERROR"
        return 1
    fi

    if [ ! -d "$codex_dir" ]; then
        write_color "ERROR: .codex directory not found in $script_dir" "$COLOR_ERROR"
        return 1
    fi

    if [ ! -d "$gemini_dir" ]; then
        write_color "ERROR: .gemini directory not found in $script_dir" "$COLOR_ERROR"
        return 1
    fi

    write_color "✓ Prerequisites check passed" "$COLOR_SUCCESS"
    return 0
}

function get_user_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local default_index=0

    if [ "$NON_INTERACTIVE" = true ]; then
        write_color "Non-interactive mode: Using default '${options[$default_index]}'" "$COLOR_INFO" >&2
        echo "${options[$default_index]}"
        return
    fi

    # Output prompts to stderr so they don't interfere with function return value
    echo "" >&2
    write_color "$prompt" "$COLOR_PROMPT" >&2
    echo "" >&2

    for i in "${!options[@]}"; do
        echo "  $((i + 1)). ${options[$i]}" >&2
    done

    echo "" >&2

    while true; do
        read -p "Please select (1-${#options[@]}): " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice - 1))]}"
            return
        fi

        write_color "Invalid selection. Please enter a number between 1 and ${#options[@]}" "$COLOR_WARNING" >&2
    done
}

function confirm_action() {
    local message="$1"
    local default_yes="${2:-false}"

    if [ "$FORCE" = true ]; then
        write_color "Force mode: Proceeding with '$message'" "$COLOR_INFO"
        return 0
    fi

    if [ "$NON_INTERACTIVE" = true ]; then
        if [ "$default_yes" = true ]; then
            write_color "Non-interactive mode: $message - Yes" "$COLOR_INFO"
            return 0
        else
            write_color "Non-interactive mode: $message - No" "$COLOR_INFO"
            return 1
        fi
    fi

    local prompt
    if [ "$default_yes" = true ]; then
        prompt="(Y/n)"
    else
        prompt="(y/N)"
    fi

    while true; do
        read -p "$message $prompt " response

        if [ -z "$response" ]; then
            [ "$default_yes" = true ] && return 0 || return 1
        fi

        case "${response,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) write_color "Please answer 'y' or 'n'" "$COLOR_WARNING" ;;
        esac
    done
}

function get_backup_directory() {
    local target_dir="$1"
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local backup_dir="${target_dir}/claude-backup-${timestamp}"

    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

function backup_file_to_folder() {
    local file_path="$1"
    local backup_folder="$2"

    if [ ! -f "$file_path" ]; then
        return 1
    fi

    local file_name=$(basename "$file_path")
    local file_dir=$(dirname "$file_path")
    local relative_path=""

    # Try to determine relative path structure
    if [[ "$file_dir" == *".claude"* ]]; then
        relative_path="${file_dir#*.claude/}"
    fi

    # Create subdirectory structure in backup if needed
    local backup_sub_dir="$backup_folder"
    if [ -n "$relative_path" ]; then
        backup_sub_dir="${backup_folder}/${relative_path}"
        mkdir -p "$backup_sub_dir"
    fi

    local backup_file_path="${backup_sub_dir}/${file_name}"

    if cp "$file_path" "$backup_file_path"; then
        write_color "Backed up: $file_name" "$COLOR_INFO"
        return 0
    else
        write_color "WARNING: Failed to backup file $file_path" "$COLOR_WARNING"
        return 1
    fi
}

function backup_directory_to_folder() {
    local dir_path="$1"
    local backup_folder="$2"

    if [ ! -d "$dir_path" ]; then
        return 1
    fi

    local dir_name=$(basename "$dir_path")
    local backup_dir_path="${backup_folder}/${dir_name}"

    if cp -r "$dir_path" "$backup_dir_path"; then
        write_color "Backed up directory: $dir_name" "$COLOR_INFO"
        return 0
    else
        write_color "WARNING: Failed to backup directory $dir_path" "$COLOR_WARNING"
        return 1
    fi
}

function copy_directory_recursive() {
    local source="$1"
    local destination="$2"

    if [ ! -d "$source" ]; then
        write_color "ERROR: Source directory does not exist: $source" "$COLOR_ERROR"
        return 1
    fi

    mkdir -p "$destination"

    if cp -r "$source/"* "$destination/"; then
        write_color "✓ Directory copied: $source -> $destination" "$COLOR_SUCCESS"
        return 0
    else
        write_color "ERROR: Failed to copy directory" "$COLOR_ERROR"
        return 1
    fi
}

function copy_file_to_destination() {
    local source="$1"
    local destination="$2"
    local description="${3:-file}"
    local backup_folder="${4:-}"

    if [ -f "$destination" ]; then
        # Use BackupAll mode for automatic backup
        if [ "$BACKUP_ALL" = true ] && [ "$NO_BACKUP" = false ]; then
            if [ -n "$backup_folder" ]; then
                backup_file_to_folder "$destination" "$backup_folder"
                write_color "Auto-backed up: $description" "$COLOR_SUCCESS"
            fi
            cp "$source" "$destination"
            write_color "$description updated (with backup)" "$COLOR_SUCCESS"
            return 0
        elif [ "$NO_BACKUP" = true ]; then
            if confirm_action "$description already exists. Replace it? (NO BACKUP)" false; then
                cp "$source" "$destination"
                write_color "$description updated (no backup)" "$COLOR_WARNING"
                return 0
            else
                write_color "Skipping $description installation" "$COLOR_WARNING"
                return 1
            fi
        elif confirm_action "$description already exists. Replace it?" false; then
            if [ -n "$backup_folder" ]; then
                backup_file_to_folder "$destination" "$backup_folder"
                write_color "Existing $description backed up" "$COLOR_SUCCESS"
            fi
            cp "$source" "$destination"
            write_color "$description updated" "$COLOR_SUCCESS"
            return 0
        else
            write_color "Skipping $description installation" "$COLOR_WARNING"
            return 1
        fi
    else
        # Ensure destination directory exists
        local dest_dir=$(dirname "$destination")
        mkdir -p "$dest_dir"
        cp "$source" "$destination"
        write_color "✓ $description installed" "$COLOR_SUCCESS"
        return 0
    fi
}

function backup_critical_config_files() {
    local target_directory="$1"
    local backup_folder="$2"
    shift 2
    local file_names=("$@")

    if [ "$NO_BACKUP" = true ] || [ -z "$backup_folder" ]; then
        return 0
    fi

    if [ ! -d "$target_directory" ]; then
        return 0
    fi

    local backed_up_count=0
    for file_name in "${file_names[@]}"; do
        local file_path="${target_directory}/${file_name}"
        if [ -f "$file_path" ]; then
            if backup_file_to_folder "$file_path" "$backup_folder"; then
                write_color "Critical config backed up: $file_name" "$COLOR_SUCCESS"
                ((backed_up_count++))
            fi
        fi
    done

    if [ "$backed_up_count" -gt 0 ]; then
        write_color "Backed up $backed_up_count critical configuration file(s)" "$COLOR_INFO"
    fi
}

function backup_and_replace_directory() {
    local source="$1"
    local destination="$2"
    local description="${3:-directory}"
    local backup_folder="${4:-}"

    if [ ! -d "$source" ]; then
        write_color "WARNING: Source $description not found: $source" "$COLOR_WARNING"
        return 1
    fi

    # Backup destination if it exists
    if [ -d "$destination" ]; then
        write_color "Found existing $description at: $destination" "$COLOR_INFO"

        # Backup entire directory if backup is enabled
        if [ "$NO_BACKUP" = false ] && [ -n "$backup_folder" ]; then
            write_color "Backing up entire $description..." "$COLOR_INFO"
            if backup_directory_to_folder "$destination" "$backup_folder"; then
                write_color "Backed up $description to: $backup_folder" "$COLOR_SUCCESS"
            fi
        elif [ "$NO_BACKUP" = true ]; then
            if ! confirm_action "Replace existing $description without backup?" false; then
                write_color "Skipping $description installation" "$COLOR_WARNING"
                return 1
            fi
        fi

        # Get all items from source to determine what to clear in destination
        write_color "Clearing conflicting items in destination $description..." "$COLOR_INFO"
        while IFS= read -r -d '' source_item; do
            local item_name=$(basename "$source_item")
            local dest_item_path="${destination}/${item_name}"

            if [ -e "$dest_item_path" ]; then
                write_color "Removing existing: $item_name" "$COLOR_INFO"
                rm -rf "$dest_item_path"
            fi
        done < <(find "$source" -mindepth 1 -maxdepth 1 -print0)
        write_color "Cleared conflicting items in destination" "$COLOR_SUCCESS"
    else
        # Create destination directory if it doesn't exist
        mkdir -p "$destination"
        write_color "Created destination directory: $destination" "$COLOR_INFO"
    fi

    # Copy all items from source to destination
    write_color "Copying $description from $source to $destination..." "$COLOR_INFO"
    while IFS= read -r -d '' item; do
        local item_name=$(basename "$item")
        local dest_path="${destination}/${item_name}"
        cp -r "$item" "$dest_path"
    done < <(find "$source" -mindepth 1 -maxdepth 1 -print0)
    write_color "$description installed successfully" "$COLOR_SUCCESS"

    return 0
}

function merge_directory_contents() {
    local source="$1"
    local destination="$2"
    local description="${3:-directory contents}"
    local backup_folder="${4:-}"

    if [ ! -d "$source" ]; then
        write_color "WARNING: Source $description not found: $source" "$COLOR_WARNING"
        return 1
    fi

    mkdir -p "$destination"
    write_color "Created destination directory: $destination" "$COLOR_INFO"

    local merged_count=0
    local skipped_count=0

    # Find all files recursively
    while IFS= read -r -d '' file; do
        local relative_path="${file#$source/}"
        local dest_path="${destination}/${relative_path}"
        local dest_dir=$(dirname "$dest_path")

        mkdir -p "$dest_dir"

        if [ -f "$dest_path" ]; then
            local file_name=$(basename "$relative_path")

            if [ "$BACKUP_ALL" = true ] && [ "$NO_BACKUP" = false ]; then
                if [ -n "$backup_folder" ]; then
                    backup_file_to_folder "$dest_path" "$backup_folder"
                    write_color "Auto-backed up: $file_name" "$COLOR_INFO"
                fi
                cp "$file" "$dest_path"
                ((merged_count++))
            elif [ "$NO_BACKUP" = true ]; then
                if confirm_action "File '$relative_path' already exists. Replace it? (NO BACKUP)" false; then
                    cp "$file" "$dest_path"
                    ((merged_count++))
                else
                    write_color "Skipped $file_name (no backup)" "$COLOR_WARNING"
                    ((skipped_count++))
                fi
            elif confirm_action "File '$relative_path' already exists. Replace it?" false; then
                if [ -n "$backup_folder" ]; then
                    backup_file_to_folder "$dest_path" "$backup_folder"
                    write_color "Backed up existing $file_name" "$COLOR_INFO"
                fi
                cp "$file" "$dest_path"
                ((merged_count++))
            else
                write_color "Skipped $file_name" "$COLOR_WARNING"
                ((skipped_count++))
            fi
        else
            cp "$file" "$dest_path"
            ((merged_count++))
        fi
    done < <(find "$source" -type f -print0)

    write_color "✓ Merged $merged_count files, skipped $skipped_count files" "$COLOR_SUCCESS"
    return 0
}

function install_global() {
    write_color "Installing Claude Code Workflow System globally..." "$COLOR_INFO"

    local user_home="$HOME"
    local global_claude_dir="${user_home}/.claude"
    local global_claude_md="${global_claude_dir}/CLAUDE.md"
    local global_codex_dir="${user_home}/.codex"
    local global_gemini_dir="${user_home}/.gemini"

    write_color "Global installation path: $user_home" "$COLOR_INFO"

    # Initialize manifest
    local manifest_file=$(new_install_manifest "Global" "$user_home")

    # Source paths
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local source_claude_dir="${script_dir}/.claude"
    local source_claude_md="${script_dir}/CLAUDE.md"
    local source_codex_dir="${script_dir}/.codex"
    local source_gemini_dir="${script_dir}/.gemini"

    # Create backup folder if needed
    local backup_folder=""
    if [ "$NO_BACKUP" = false ]; then
        local has_existing_files=false

        if [ -d "$global_claude_dir" ] && [ "$(ls -A "$global_claude_dir" 2>/dev/null)" ]; then
            has_existing_files=true
        elif [ -d "$global_codex_dir" ] && [ "$(ls -A "$global_codex_dir" 2>/dev/null)" ]; then
            has_existing_files=true
        elif [ -d "$global_gemini_dir" ] && [ "$(ls -A "$global_gemini_dir" 2>/dev/null)" ]; then
            has_existing_files=true
        elif [ -f "$global_claude_md" ]; then
            has_existing_files=true
        fi

        if [ "$has_existing_files" = true ]; then
            backup_folder=$(get_backup_directory "$user_home")
            write_color "Backup folder created: $backup_folder" "$COLOR_INFO"
        fi
    fi

    # Merge .claude directory (incremental overlay - preserves user files)
    write_color "Installing .claude directory (incremental merge)..." "$COLOR_INFO"
    if merge_directory_contents "$source_claude_dir" "$global_claude_dir" ".claude directory" "$backup_folder"; then
        # Track .claude directory in manifest
        add_manifest_entry "$manifest_file" "$global_claude_dir" "Directory"

        # Track files from SOURCE directory, not destination
        while IFS= read -r -d '' source_file; do
            local relative_path="${source_file#$source_claude_dir}"
            local target_path="${global_claude_dir}${relative_path}"
            add_manifest_entry "$manifest_file" "$target_path" "File"
        done < <(find "$source_claude_dir" -type f -print0)
    fi

    # Handle CLAUDE.md file
    write_color "Installing CLAUDE.md to global .claude directory..." "$COLOR_INFO"
    if copy_file_to_destination "$source_claude_md" "$global_claude_md" "CLAUDE.md" "$backup_folder"; then
        # Track CLAUDE.md in manifest
        add_manifest_entry "$manifest_file" "$global_claude_md" "File"
    fi

    # Backup critical config files in .codex directory before installation
    backup_critical_config_files "$global_codex_dir" "$backup_folder" "AGENTS.md"

    # Merge .codex directory (incremental overlay - preserves user files)
    write_color "Installing .codex directory (incremental merge)..." "$COLOR_INFO"
    if merge_directory_contents "$source_codex_dir" "$global_codex_dir" ".codex directory" "$backup_folder"; then
        # Track .codex directory in manifest
        add_manifest_entry "$manifest_file" "$global_codex_dir" "Directory"

        # Track files from SOURCE directory
        while IFS= read -r -d '' source_file; do
            local relative_path="${source_file#$source_codex_dir}"
            local target_path="${global_codex_dir}${relative_path}"
            add_manifest_entry "$manifest_file" "$target_path" "File"
        done < <(find "$source_codex_dir" -type f -print0)
    fi

    # Backup critical config files in .gemini directory before installation
    backup_critical_config_files "$global_gemini_dir" "$backup_folder" "GEMINI.md" "CLAUDE.md"

    # Merge .gemini directory (incremental overlay - preserves user files)
    write_color "Installing .gemini directory (incremental merge)..." "$COLOR_INFO"
    if merge_directory_contents "$source_gemini_dir" "$global_gemini_dir" ".gemini directory" "$backup_folder"; then
        # Track .gemini directory in manifest
        add_manifest_entry "$manifest_file" "$global_gemini_dir" "Directory"

        # Track files from SOURCE directory
        while IFS= read -r -d '' source_file; do
            local relative_path="${source_file#$source_gemini_dir}"
            local target_path="${global_gemini_dir}${relative_path}"
            add_manifest_entry "$manifest_file" "$target_path" "File"
        done < <(find "$source_gemini_dir" -type f -print0)
    fi



    # Remove empty backup folder
    if [ -n "$backup_folder" ] && [ -d "$backup_folder" ]; then
        if [ -z "$(ls -A "$backup_folder" 2>/dev/null)" ]; then
            rm -rf "$backup_folder"
            write_color "Removed empty backup folder" "$COLOR_INFO"
        fi
    fi

    # Create version.json in global .claude directory
    write_color "Creating version.json..." "$COLOR_INFO"
    create_version_json "$global_claude_dir" "Global"

    # Save installation manifest
    save_install_manifest "$manifest_file"

    return 0
}

function install_path() {
    local target_dir="$1"

    write_color "Installing Claude Code Workflow System in hybrid mode..." "$COLOR_INFO"
    write_color "Local path: $target_dir" "$COLOR_INFO"

    local user_home="$HOME"
    local global_claude_dir="${user_home}/.claude"
    write_color "Global path: $user_home" "$COLOR_INFO"

    # Initialize manifest
    local manifest_file=$(new_install_manifest "Path" "$target_dir")

    # Source paths
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local source_claude_dir="${script_dir}/.claude"
    local source_claude_md="${script_dir}/CLAUDE.md"
    local source_codex_dir="${script_dir}/.codex"
    local source_gemini_dir="${script_dir}/.gemini"

    # Local paths
    local local_claude_dir="${target_dir}/.claude"
    local local_codex_dir="${target_dir}/.codex"
    local local_gemini_dir="${target_dir}/.gemini"

    # Create backup folder if needed
    local backup_folder=""
    if [ "$NO_BACKUP" = false ]; then
        if [ -d "$local_claude_dir" ] || [ -d "$local_codex_dir" ] || [ -d "$local_gemini_dir" ] || [ -d "$global_claude_dir" ]; then
            backup_folder=$(get_backup_directory "$target_dir")
            write_color "Backup folder created: $backup_folder" "$COLOR_INFO"
        fi
    fi

    # Create local .claude directory
    mkdir -p "$local_claude_dir"
    write_color "✓ Created local .claude directory" "$COLOR_SUCCESS"

    # Local folders to install
    local local_folders=("agents" "commands" "output-styles")

    write_color "Installing local components (agents, commands, output-styles)..." "$COLOR_INFO"
    for folder in "${local_folders[@]}"; do
        local source_folder="${source_claude_dir}/${folder}"
        local dest_folder="${local_claude_dir}/${folder}"

        if [ -d "$source_folder" ]; then
            # Use incremental merge for local folders (preserves user customizations)
            write_color "Installing local folder: $folder (incremental merge)..." "$COLOR_INFO"
            if merge_directory_contents "$source_folder" "$dest_folder" "$folder folder" "$backup_folder"; then
                # Track local folder in manifest
                add_manifest_entry "$manifest_file" "$dest_folder" "Directory"

                # Track files from SOURCE directory
                while IFS= read -r -d '' source_file; do
                    local relative_path="${source_file#$source_folder}"
                    local target_path="${dest_folder}${relative_path}"
                    add_manifest_entry "$manifest_file" "$target_path" "File"
                done < <(find "$source_folder" -type f -print0)
            fi
            write_color "✓ Installed local folder: $folder" "$COLOR_SUCCESS"
        else
            write_color "WARNING: Source folder not found: $folder" "$COLOR_WARNING"
        fi
    done

    # Global components - exclude local folders
    write_color "Installing global components to $global_claude_dir..." "$COLOR_INFO"

    local merged_count=0

    while IFS= read -r -d '' file; do
        local relative_path="${file#$source_claude_dir/}"
        local top_folder=$(echo "$relative_path" | cut -d'/' -f1)

        # Skip local folders
        if [[ " ${local_folders[*]} " =~ " ${top_folder} " ]]; then
            continue
        fi

        local dest_path="${global_claude_dir}/${relative_path}"
        local dest_dir=$(dirname "$dest_path")

        mkdir -p "$dest_dir"

        if [ -f "$dest_path" ]; then
            if [ "$BACKUP_ALL" = true ] && [ "$NO_BACKUP" = false ]; then
                if [ -n "$backup_folder" ]; then
                    backup_file_to_folder "$dest_path" "$backup_folder"
                fi
                cp "$file" "$dest_path"
                ((merged_count++))
            elif [ "$NO_BACKUP" = true ]; then
                if confirm_action "File '$relative_path' already exists in global location. Replace it? (NO BACKUP)" false; then
                    cp "$file" "$dest_path"
                    ((merged_count++))
                fi
            elif confirm_action "File '$relative_path' already exists in global location. Replace it?" false; then
                if [ -n "$backup_folder" ]; then
                    backup_file_to_folder "$dest_path" "$backup_folder"
                fi
                cp "$file" "$dest_path"
                ((merged_count++))
            fi
        else
            cp "$file" "$dest_path"
            ((merged_count++))
        fi
    done < <(find "$source_claude_dir" -type f -print0)

    write_color "✓ Merged $merged_count files to global location" "$COLOR_SUCCESS"

    # Handle CLAUDE.md file in global .claude directory
    local global_claude_md="${global_claude_dir}/CLAUDE.md"
    write_color "Installing CLAUDE.md to global .claude directory..." "$COLOR_INFO"
    if copy_file_to_destination "$source_claude_md" "$global_claude_md" "CLAUDE.md" "$backup_folder"; then
        # Track CLAUDE.md in manifest
        add_manifest_entry "$manifest_file" "$global_claude_md" "File"
    fi

    # Backup critical config files in .codex directory before installation
    backup_critical_config_files "$local_codex_dir" "$backup_folder" "AGENTS.md"

    # Merge .codex directory to local location (incremental overlay - preserves user files)
    write_color "Installing .codex directory to local location (incremental merge)..." "$COLOR_INFO"
    if merge_directory_contents "$source_codex_dir" "$local_codex_dir" ".codex directory" "$backup_folder"; then
        # Track .codex directory in manifest
        add_manifest_entry "$manifest_file" "$local_codex_dir" "Directory"

        # Track files from SOURCE directory
        while IFS= read -r -d '' source_file; do
            local relative_path="${source_file#$source_codex_dir}"
            local target_path="${local_codex_dir}${relative_path}"
            add_manifest_entry "$manifest_file" "$target_path" "File"
        done < <(find "$source_codex_dir" -type f -print0)
    fi

    # Backup critical config files in .gemini directory before installation
    backup_critical_config_files "$local_gemini_dir" "$backup_folder" "GEMINI.md" "CLAUDE.md"

    # Merge .gemini directory to local location (incremental overlay - preserves user files)
    write_color "Installing .gemini directory to local location (incremental merge)..." "$COLOR_INFO"
    if merge_directory_contents "$source_gemini_dir" "$local_gemini_dir" ".gemini directory" "$backup_folder"; then
        # Track .gemini directory in manifest
        add_manifest_entry "$manifest_file" "$local_gemini_dir" "Directory"

        # Track files from SOURCE directory
        while IFS= read -r -d '' source_file; do
            local relative_path="${source_file#$source_gemini_dir}"
            local target_path="${local_gemini_dir}${relative_path}"
            add_manifest_entry "$manifest_file" "$target_path" "File"
        done < <(find "$source_gemini_dir" -type f -print0)
    fi



    # Remove empty backup folder
    if [ -n "$backup_folder" ] && [ -d "$backup_folder" ]; then
        if [ -z "$(ls -A "$backup_folder" 2>/dev/null)" ]; then
            rm -rf "$backup_folder"
            write_color "Removed empty backup folder" "$COLOR_INFO"
        fi
    fi

    # Create version.json in local .claude directory
    write_color "Creating version.json in local directory..." "$COLOR_INFO"
    create_version_json "$local_claude_dir" "Path"

    # Also create version.json in global .claude directory
    write_color "Creating version.json in global directory..." "$COLOR_INFO"
    create_version_json "$global_claude_dir" "Global"

    # Save installation manifest
    save_install_manifest "$manifest_file"

    return 0
}

function get_installation_mode() {
    if [ -n "$INSTALL_MODE" ]; then
        write_color "Installation mode: $INSTALL_MODE" "$COLOR_INFO" >&2
        echo "$INSTALL_MODE"
        return
    fi

    local modes=(
        "Global - Install to user profile (~/.claude/)"
        "Path - Install to custom directory (partial local + global)"
    )

    local selection=$(get_user_choice "Choose installation mode:" "${modes[@]}")

    if [[ "$selection" == Global* ]]; then
        echo "Global"
    elif [[ "$selection" == Path* ]]; then
        echo "Path"
    else
        echo "Global"
    fi
}

function get_installation_path() {
    local mode="$1"

    if [ "$mode" = "Global" ]; then
        echo "$HOME"
        return
    fi

    if [ -n "$TARGET_PATH" ]; then
        if [ -d "$TARGET_PATH" ]; then
            echo "$TARGET_PATH"
            return
        fi
        write_color "WARNING: Specified target path does not exist: $TARGET_PATH" "$COLOR_WARNING"
    fi

    # Interactive path selection
    while true; do
        echo ""
        write_color "Enter the target directory path for installation:" "$COLOR_PROMPT"
        write_color "(This will install agents, commands, output-styles locally, other files globally)" "$COLOR_INFO"
        read -p "Path: " path

        if [ -z "$path" ]; then
            write_color "Path cannot be empty" "$COLOR_WARNING"
            continue
        fi

        # Expand ~ and environment variables
        path=$(eval echo "$path")

        if [ -d "$path" ]; then
            echo "$path"
            return
        fi

        write_color "Path does not exist: $path" "$COLOR_WARNING"
        if confirm_action "Create this directory?" true; then
            if mkdir -p "$path"; then
                write_color "✓ Directory created successfully" "$COLOR_SUCCESS"
                echo "$path"
                return
            else
                write_color "ERROR: Failed to create directory" "$COLOR_ERROR"
            fi
        fi
    done
}

# ============================================================================
# INSTALLATION MANIFEST MANAGEMENT
# ============================================================================

function new_install_manifest() {
    local installation_mode="$1"
    local installation_path="$2"

    # Create manifest directory if it doesn't exist
    mkdir -p "$MANIFEST_DIR"

    # Generate unique manifest ID based on timestamp and mode
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local manifest_id="install-${installation_mode}-${timestamp}"

    # Create manifest file path
    local manifest_file="${MANIFEST_DIR}/${manifest_id}.json"

    # Get current UTC timestamp
    local installation_date_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create manifest JSON
    cat > "$manifest_file" << EOF
{
  "manifest_id": "$manifest_id",
  "version": "1.0",
  "installation_mode": "$installation_mode",
  "installation_path": "$installation_path",
  "installation_date": "$installation_date_utc",
  "installer_version": "$VERSION",
  "files": [],
  "directories": []
}
EOF

    echo "$manifest_file"
}

function add_manifest_entry() {
    local manifest_file="$1"
    local entry_path="$2"
    local entry_type="$3"

    if [ ! -f "$manifest_file" ]; then
        write_color "WARNING: Manifest file not found: $manifest_file" "$COLOR_WARNING"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Escape path for JSON
    local escaped_path=$(echo "$entry_path" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

    # Create entry JSON
    local entry_json=$(cat << EOF
{
  "path": "$escaped_path",
  "type": "$entry_type",
  "timestamp": "$timestamp"
}
EOF
)

    # Read manifest, add entry, write back
    local temp_file="${manifest_file}.tmp"

    if [ "$entry_type" = "File" ]; then
        jq --argjson entry "$entry_json" '.files += [$entry]' "$manifest_file" > "$temp_file"
    else
        jq --argjson entry "$entry_json" '.directories += [$entry]' "$manifest_file" > "$temp_file"
    fi

    mv "$temp_file" "$manifest_file"
}

function save_install_manifest() {
    local manifest_file="$1"

    if [ -f "$manifest_file" ]; then
        write_color "Installation manifest saved: $manifest_file" "$COLOR_SUCCESS"
        return 0
    else
        write_color "WARNING: Failed to save installation manifest" "$COLOR_WARNING"
        return 1
    fi
}

function migrate_legacy_manifest() {
    local legacy_manifest="${HOME}/.claude-install-manifest.json"

    if [ ! -f "$legacy_manifest" ]; then
        return 0
    fi

    write_color "Found legacy manifest file, migrating to new system..." "$COLOR_INFO"

    # Create manifest directory if it doesn't exist
    mkdir -p "$MANIFEST_DIR"

    # Read legacy manifest
    local mode=$(jq -r '.installation_mode // "Global"' "$legacy_manifest")
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local manifest_id="install-${mode}-${timestamp}-migrated"

    # Create new manifest file
    local new_manifest="${MANIFEST_DIR}/${manifest_id}.json"

    # Copy with new manifest_id field
    jq --arg id "$manifest_id" '. + {manifest_id: $id}' "$legacy_manifest" > "$new_manifest"

    # Rename old manifest (don't delete, keep as backup)
    mv "$legacy_manifest" "${legacy_manifest}.migrated"

    write_color "Legacy manifest migrated successfully" "$COLOR_SUCCESS"
    write_color "Old manifest backed up to: ${legacy_manifest}.migrated" "$COLOR_INFO"
}

function get_all_install_manifests() {
    # Migrate legacy manifest if exists
    migrate_legacy_manifest

    if [ ! -d "$MANIFEST_DIR" ]; then
        echo "[]"
        return
    fi

    # Check if any manifest files exist
    local manifest_count=$(find "$MANIFEST_DIR" -name "install-*.json" -type f 2>/dev/null | wc -l)

    if [ "$manifest_count" -eq 0 ]; then
        echo "[]"
        return
    fi

    # Collect all manifests into JSON array
    local manifests="["
    local first=true

    while IFS= read -r -d '' file; do
        if [ "$first" = true ]; then
            first=false
        else
            manifests+=","
        fi

        # Add manifest_file field
        local manifest_content=$(jq --arg file "$file" '. + {manifest_file: $file}' "$file")

        # Count files and directories safely
        local files_count=$(echo "$manifest_content" | jq '.files | length')
        local dirs_count=$(echo "$manifest_content" | jq '.directories | length')

        # Add counts to manifest
        manifest_content=$(echo "$manifest_content" | jq --argjson fc "$files_count" --argjson dc "$dirs_count" '. + {files_count: $fc, directories_count: $dc}')

        manifests+="$manifest_content"
    done < <(find "$MANIFEST_DIR" -name "install-*.json" -type f -print0 | sort -z)

    manifests+="]"

    echo "$manifests"
}

# ============================================================================
# UNINSTALLATION FUNCTIONS
# ============================================================================

function uninstall_claude_workflow() {
    write_color "Claude Code Workflow System Uninstaller" "$COLOR_INFO"
    write_color "========================================" "$COLOR_INFO"
    echo ""

    # Load all manifests
    local manifests_json=$(get_all_install_manifests)
    local manifests_count=$(echo "$manifests_json" | jq 'length')

    if [ "$manifests_count" -eq 0 ]; then
        write_color "ERROR: No installation manifests found in: $MANIFEST_DIR" "$COLOR_ERROR"
        write_color "Cannot proceed with uninstallation without manifest." "$COLOR_ERROR"
        echo ""
        write_color "Manual uninstallation instructions:" "$COLOR_INFO"
        echo "For Global installation, remove these directories:"
        echo "  - ~/.claude/agents"
        echo "  - ~/.claude/commands"
        echo "  - ~/.claude/output-styles"
        echo "  - ~/.claude/workflows"
        echo "  - ~/.claude/scripts"
        echo "  - ~/.claude/prompt-templates"
        echo "  - ~/.claude/python_script"
        echo "  - ~/.claude/skills"
        echo "  - ~/.claude/version.json"
        echo "  - ~/.claude/CLAUDE.md"
        echo "  - ~/.codex"
        echo "  - ~/.gemini"
        return 1
    fi

    # Display available installations
    write_color "Found $manifests_count installation(s):" "$COLOR_INFO"
    echo ""

    # If only one manifest, use it directly
    local selected_index=0
    local selected_manifest=""

    if [ "$manifests_count" -eq 1 ]; then
        selected_manifest=$(echo "$manifests_json" | jq '.[0]')
        write_color "Only one installation found, will uninstall:" "$COLOR_INFO"
    else
        # Multiple manifests - let user choose
        local options=()

        for i in $(seq 0 $((manifests_count - 1))); do
            local m=$(echo "$manifests_json" | jq ".[$i]")

            # Safely extract date string
            local date_str=$(echo "$m" | jq -r '.installation_date // "unknown date"' | cut -c1-10)
            local mode=$(echo "$m" | jq -r '.installation_mode // "Unknown"')
            local files_count=$(echo "$m" | jq -r '.files_count // 0')
            local dirs_count=$(echo "$m" | jq -r '.directories_count // 0')
            local path_info=$(echo "$m" | jq -r '.installation_path // ""')

            if [ -n "$path_info" ]; then
                path_info=" ($path_info)"
            fi

            options+=("$((i + 1)). [$mode] $date_str - $files_count files, $dirs_count dirs$path_info")
        done

        options+=("Cancel - Don't uninstall anything")

        echo ""
        local selection=$(get_user_choice "Select installation to uninstall:" "${options[@]}")

        if [[ "$selection" == Cancel* ]]; then
            write_color "Uninstallation cancelled." "$COLOR_WARNING"
            return 1
        fi

        # Parse selection to get index
        selected_index=$((${selection%%.*} - 1))
        selected_manifest=$(echo "$manifests_json" | jq ".[$selected_index]")
    fi

    # Display selected installation info
    echo ""
    write_color "Installation Information:" "$COLOR_INFO"
    echo "  Manifest ID: $(echo "$selected_manifest" | jq -r '.manifest_id')"
    echo "  Mode: $(echo "$selected_manifest" | jq -r '.installation_mode')"
    echo "  Path: $(echo "$selected_manifest" | jq -r '.installation_path')"
    echo "  Date: $(echo "$selected_manifest" | jq -r '.installation_date')"
    echo "  Installer Version: $(echo "$selected_manifest" | jq -r '.installer_version')"
    echo "  Files tracked: $(echo "$selected_manifest" | jq -r '.files_count')"
    echo "  Directories tracked: $(echo "$selected_manifest" | jq -r '.directories_count')"
    echo ""

    # Confirm uninstallation
    if ! confirm_action "Do you want to uninstall this installation?" false; then
        write_color "Uninstallation cancelled." "$COLOR_WARNING"
        return 1
    fi

    local removed_files=0
    local removed_dirs=0
    local failed_items=()

    # Remove files first
    write_color "Removing installed files..." "$COLOR_INFO"

    local files_array=$(echo "$selected_manifest" | jq -c '.files[]')

    while IFS= read -r file_entry; do
        local file_path=$(echo "$file_entry" | jq -r '.path')

        if [ -f "$file_path" ]; then
            if rm -f "$file_path" 2>/dev/null; then
                write_color "  Removed file: $file_path" "$COLOR_SUCCESS"
                ((removed_files++))
            else
                write_color "  WARNING: Failed to remove file: $file_path" "$COLOR_WARNING"
                failed_items+=("$file_path")
            fi
        else
            write_color "  File not found (already removed): $file_path" "$COLOR_INFO"
        fi
    done <<< "$files_array"

    # Remove directories (in reverse order by path length)
    write_color "Removing installed directories..." "$COLOR_INFO"

    local dirs_array=$(echo "$selected_manifest" | jq -c '.directories[] | {path: .path, length: (.path | length)}' | sort -t: -k2 -rn | jq -c '.path')

    while IFS= read -r dir_path_json; do
        local dir_path=$(echo "$dir_path_json" | jq -r '.')

        if [ -d "$dir_path" ]; then
            # Check if directory is empty
            if [ -z "$(ls -A "$dir_path" 2>/dev/null)" ]; then
                if rmdir "$dir_path" 2>/dev/null; then
                    write_color "  Removed directory: $dir_path" "$COLOR_SUCCESS"
                    ((removed_dirs++))
                else
                    write_color "  WARNING: Failed to remove directory: $dir_path" "$COLOR_WARNING"
                    failed_items+=("$dir_path")
                fi
            else
                write_color "  Directory not empty (preserved): $dir_path" "$COLOR_WARNING"
            fi
        else
            write_color "  Directory not found (already removed): $dir_path" "$COLOR_INFO"
        fi
    done <<< "$dirs_array"

    # Remove manifest file
    local manifest_file=$(echo "$selected_manifest" | jq -r '.manifest_file')

    if [ -f "$manifest_file" ]; then
        if rm -f "$manifest_file" 2>/dev/null; then
            write_color "Removed installation manifest: $(basename "$manifest_file")" "$COLOR_SUCCESS"
        else
            write_color "WARNING: Failed to remove manifest file" "$COLOR_WARNING"
        fi
    fi

    # Show summary
    echo ""
    write_color "========================================" "$COLOR_INFO"
    write_color "Uninstallation Summary:" "$COLOR_INFO"
    echo "  Files removed: $removed_files"
    echo "  Directories removed: $removed_dirs"

    if [ ${#failed_items[@]} -gt 0 ]; then
        echo ""
        write_color "Failed to remove the following items:" "$COLOR_WARNING"
        for item in "${failed_items[@]}"; do
            echo "  - $item"
        done
    fi

    echo ""
    if [ ${#failed_items[@]} -eq 0 ]; then
        write_color "✓ Claude Code Workflow has been successfully uninstalled!" "$COLOR_SUCCESS"
    else
        write_color "Uninstallation completed with warnings." "$COLOR_WARNING"
        write_color "Please manually remove the failed items listed above." "$COLOR_INFO"
    fi

    return 0
}

function create_version_json() {
    local target_claude_dir="$1"
    local installation_mode="$2"

    # Determine version from source parameter (passed from install-remote.sh)
    local version_number="${SOURCE_VERSION:-unknown}"
    local source_branch="${SOURCE_BRANCH:-unknown}"
    local commit_sha="${SOURCE_COMMIT:-unknown}"

    # Get current UTC timestamp
    local installation_date_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create version.json content
    local version_json_path="${target_claude_dir}/version.json"

    cat > "$version_json_path" << EOF
{
  "version": "$version_number",
  "commit_sha": "$commit_sha",
  "installation_mode": "$installation_mode",
  "installation_path": "$target_claude_dir",
  "installation_date_utc": "$installation_date_utc",
  "source_branch": "$source_branch",
  "installer_version": "$VERSION"
}
EOF

    if [ -f "$version_json_path" ]; then
        write_color "Created version.json: $version_number ($commit_sha) - $installation_mode" "$COLOR_SUCCESS"
        return 0
    else
        write_color "WARNING: Failed to create version.json" "$COLOR_WARNING"
        return 1
    fi
}

function show_summary() {
    local mode="$1"
    local path="$2"
    local success="$3"

    echo ""
    if [ "$success" = true ]; then
        write_color "✓ Installation completed successfully!" "$COLOR_SUCCESS"
    else
        write_color "Installation completed with warnings" "$COLOR_WARNING"
    fi

    write_color "Installation Details:" "$COLOR_INFO"
    echo "  Mode: $mode"

    if [ "$mode" = "Path" ]; then
        echo "  Local Path: $path"
        echo "  Global Path: $HOME"
        echo "  Local Components: agents, commands, output-styles, .codex, .gemini"
        echo "  Global Components: workflows, scripts, python_script, etc."
    else
        echo "  Path: $path"
        echo "  Global Components: .claude, .codex, .gemini"
    fi

    if [ "$NO_BACKUP" = true ]; then
        echo "  Backup: Disabled (no backup created)"
    elif [ "$BACKUP_ALL" = true ]; then
        echo "  Backup: Enabled (automatic backup of all existing files)"
    else
        echo "  Backup: Enabled (default behavior)"
    fi

    echo ""
    write_color "Next steps:" "$COLOR_INFO"
    echo "1. Review CLAUDE.md - Customize guidelines for your project"
    echo "2. Review .codex/Agent.md - Codex agent execution protocol"
    echo "3. Review .gemini/CLAUDE.md - Gemini agent execution protocol"
    echo "4. Configure settings - Edit .claude/settings.local.json as needed"
    echo "5. Install TOON dependencies - Run 'npm install' for workflow utilities"
    echo "6. Test TOON wrapper - Try './scripts/toon-wrapper.sh --help'"
    echo "7. Start using Claude Code with Agent workflow coordination!"
    echo "8. Use /workflow commands for task execution"
    echo "10. Use /update-memory commands for memory system management"

    echo ""
    write_color "TOON Format Info:" "$COLOR_INFO"
    echo "  The system uses TOON (Token-Oriented Object Notation) for 30-60% token savings"
    echo "  Legacy JSON files are automatically supported via autoDecode()"
    echo "  See CLAUDE.md for TOON format details and usage examples"
    echo ""
    write_color "Documentation: https://github.com/ding113/Claude-Code-Workflow" "$COLOR_INFO"
    write_color "Features: Unified workflow system with comprehensive file output generation" "$COLOR_INFO"
}

function parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -InstallMode)
                INSTALL_MODE="$2"
                shift 2
                ;;
            -TargetPath)
                TARGET_PATH="$2"
                shift 2
                ;;
            -Force)
                FORCE=true
                shift
                ;;
            -NonInteractive)
                NON_INTERACTIVE=true
                shift
                ;;
            -BackupAll)
                BACKUP_ALL=true
                NO_BACKUP=false
                shift
                ;;
            -NoBackup)
                NO_BACKUP=true
                BACKUP_ALL=false
                shift
                ;;
            -Uninstall)
                UNINSTALL=true
                shift
                ;;
            -SourceVersion)
                SOURCE_VERSION="$2"
                shift 2
                ;;
            -SourceBranch)
                SOURCE_BRANCH="$2"
                shift 2
                ;;
            -SourceCommit)
                SOURCE_COMMIT="$2"
                shift 2
                ;;
            --help|-h)
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
$SCRIPT_NAME v$VERSION

Usage: $0 [OPTIONS]

Options:
    -InstallMode <mode>   Installation mode: Global or Path
    -TargetPath <path>    Target path for Path installation mode
    -Force                Skip confirmation prompts
    -NonInteractive       Run in non-interactive mode with default options
    -BackupAll            Automatically backup all existing files (default)
    -NoBackup             Disable automatic backup functionality
    -Uninstall            Uninstall Claude Code Workflow System based on installation manifest
    -SourceVersion <ver>  Source version (passed from install-remote.sh)
    -SourceBranch <name>  Source branch (passed from install-remote.sh)
    -SourceCommit <sha>   Source commit SHA (passed from install-remote.sh)
    --help, -h            Show this help message

Examples:
    # Interactive installation
    $0

    # Global installation without prompts
    $0 -InstallMode Global -Force

    # Path installation with custom directory
    $0 -InstallMode Path -TargetPath /opt/claude-code-workflow

    # Installation without backup
    $0 -NoBackup

    # Uninstall Claude Code Workflow System
    $0 -Uninstall

    # Uninstall without confirmation prompts
    $0 -Uninstall -Force

    # With version info (typically called by install-remote.sh)
    $0 -InstallMode Global -Force -SourceVersion "3.4.2" -SourceBranch "main" -SourceCommit "abc1234"

EOF
}

function main() {
    # Show banner first
    show_banner

    # Check for uninstall mode from parameter or ask user interactively
    local operation_mode="Install"

    if [ "$UNINSTALL" = true ]; then
        operation_mode="Uninstall"
    elif [ "$NON_INTERACTIVE" != true ] && [ -z "$INSTALL_MODE" ]; then
        # Interactive mode selection
        echo ""
        local operations=(
            "Install - Install Claude Code Workflow System"
            "Uninstall - Remove Claude Code Workflow System"
        )
        local selection=$(get_user_choice "Choose operation:" "${operations[@]}")

        if [[ "$selection" == Uninstall* ]]; then
            operation_mode="Uninstall"
        fi
    fi

    # Handle uninstall mode
    if [ "$operation_mode" = "Uninstall" ]; then
        if uninstall_claude_workflow; then
            local result=0
        else
            local result=1
        fi

        if [ "$NON_INTERACTIVE" != true ]; then
            echo ""
            write_color "Press Enter to exit..." "$COLOR_PROMPT"
            read -r
        fi

        return $result
    fi

    # Continue with installation
    show_header

    # Test prerequisites
    write_color "Checking system requirements..." "$COLOR_INFO"
    if ! test_prerequisites; then
        write_color "Prerequisites check failed!" "$COLOR_ERROR"
        return 1
    fi

    local mode=$(get_installation_mode)
    local install_path=""
    local success=false

    if [ "$mode" = "Global" ]; then
        install_path="$HOME"
        if install_global; then
            success=true
        fi
    elif [ "$mode" = "Path" ]; then
        install_path=$(get_installation_path "$mode")
        if install_path "$install_path"; then
            success=true
        fi
    fi

    show_summary "$mode" "$install_path" "$success"

    # Wait for user confirmation in interactive mode
    if [ "$NON_INTERACTIVE" != true ]; then
        echo ""
        write_color "Installation completed. Press Enter to exit..." "$COLOR_PROMPT"
        read -r
    fi

    if [ "$success" = true ]; then
        return 0
    else
        return 1
    fi
}

# Initialize backup behavior - backup is enabled by default unless NoBackup is specified
if [ "$NO_BACKUP" = false ]; then
    BACKUP_ALL=true
fi

# Parse command line arguments
parse_arguments "$@"

# Run main function
main
exit $?

#Requires -Version 5.1

<#
.SYNOPSIS
    Claude Code Workflow System Interactive Installer

.DESCRIPTION
    Installation script for Claude Code Workflow System with Agent coordination and distributed memory system.
    Installs globally to user profile directory (~/.claude) by default.

.PARAMETER InstallMode
    Installation mode: "Global" (default and only supported mode)

.PARAMETER TargetPath
    Target path for Custom installation mode

.PARAMETER Force
    Skip confirmation prompts

.PARAMETER NonInteractive
    Run in non-interactive mode with default options

.PARAMETER BackupAll
    Automatically backup all existing files without confirmation prompts (enabled by default)

.PARAMETER NoBackup
    Disable automatic backup functionality

.PARAMETER Uninstall
    Uninstall Claude Code Workflow System based on installation manifest

.EXAMPLE
    .\Install-Claude.ps1
    Interactive installation with mode selection

.EXAMPLE
    .\Install-Claude.ps1 -InstallMode Global -Force
    Global installation without prompts

.EXAMPLE
    .\Install-Claude.ps1 -Force -NonInteractive
    Global installation without prompts

.EXAMPLE
    .\Install-Claude.ps1 -BackupAll
    Global installation with automatic backup of all existing files

.EXAMPLE
    .\Install-Claude.ps1 -NoBackup
    Installation without any backup (overwrite existing files)

.EXAMPLE
    .\Install-Claude.ps1 -Uninstall
    Uninstall Claude Code Workflow System

.EXAMPLE
    .\Install-Claude.ps1 -Uninstall -Force
    Uninstall without confirmation prompts
#>

param(
    [ValidateSet("Global", "Path")]
    [string]$InstallMode = "",

    [string]$TargetPath = "",

    [switch]$Force,

    [switch]$NonInteractive,

    [switch]$BackupAll,

    [switch]$NoBackup,

    [switch]$Uninstall,

    [string]$SourceVersion = "",

    [string]$SourceBranch = "",

    [string]$SourceCommit = ""
)

# Set encoding for proper Unicode support
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} else {
    # For Windows PowerShell 5.1
    chcp 65001 | Out-Null
}

# Script metadata
$ScriptName = "Claude Code Workflow System Installer"
$ScriptVersion = "2.2.0"  # Installer script version

# Default version (will be overridden by -SourceVersion from install-remote.ps1)
$DefaultVersion = "unknown"

# Initialize backup behavior - backup is enabled by default unless NoBackup is specified
if (-not $BackupAll -and -not $NoBackup) {
    $BackupAll = $true
    Write-Verbose "Auto-backup enabled by default. Use -NoBackup to disable."
}

# Colors for output
$ColorSuccess = "Green"
$ColorInfo = "Cyan"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorPrompt = "Magenta"

# Global manifest directory location
$script:ManifestDir = Join-Path ([Environment]::GetFolderPath("UserProfile")) ".claude-manifests"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Banner {
    Write-Host ""
    # CLAUDE - Cyan color
    Write-Host '  ______   __                            __                   ' -ForegroundColor Cyan
    Write-Host ' /      \ |  \                          |  \                 ' -ForegroundColor Cyan
    Write-Host '|  $$$$$$\| $$  ______   __    __   ____| $$  ______        ' -ForegroundColor Cyan
    Write-Host '| $$   \$$| $$ |      \ |  \  |  \ /      $$ /      \       ' -ForegroundColor Cyan
    Write-Host '| $$      | $$  \$$$$$$\| $$  | $$|  $$$$$$$|  $$$$$$\      ' -ForegroundColor Cyan
    Write-Host '| $$   __ | $$ /      $$| $$  | $$| $$  | $$| $$    $$      ' -ForegroundColor Cyan
    Write-Host '| $$__/  \| $$|  $$$$$$$| $$__/ $$| $$__| $$| $$$$$$$$      ' -ForegroundColor Cyan
    Write-Host ' \$$    $$| $$ \$$    $$ \$$    $$ \$$    $$ \$$     \       ' -ForegroundColor Cyan
    Write-Host '  \$$$$$$  \$$  \$$$$$$$  \$$$$$$   \$$$$$$$  \$$$$$$$        ' -ForegroundColor Cyan
    Write-Host ""

    # CODE - Green color
    Write-Host ' ______                   __                  ' -ForegroundColor Green
    Write-Host '/      \                 |  \                ' -ForegroundColor Green
    Write-Host '|  $$$$$$\  ______    ____| $$  ______        ' -ForegroundColor Green
    Write-Host '| $$   \$$ /      \  /      $$ /      \       ' -ForegroundColor Green
    Write-Host '| $$      |  $$$$$$\|  $$$$$$$|  $$$$$$\      ' -ForegroundColor Green
    Write-Host '| $$   __ | $$  | $$| $$  | $$| $$    $$      ' -ForegroundColor Green
    Write-Host '| $$__/  \| $$__/ $$| $$__| $$| $$$$$$$$      ' -ForegroundColor Green
    Write-Host ' \$$    $$ \$$    $$ \$$    $$ \$$     \      ' -ForegroundColor Green
    Write-Host '  \$$$$$$   \$$$$$$   \$$$$$$$  \$$$$$$$       ' -ForegroundColor Green
    Write-Host ""

    # WORKFLOW - Yellow color
    Write-Host '__       __                      __         ______   __                         ' -ForegroundColor Yellow
    Write-Host '|  \  _  |  \                    |  \       /      \ |  \                        ' -ForegroundColor Yellow
    Write-Host '| $$ / \ | $$  ______    ______  | $$   __ |  $$$$$$\| $$  ______   __   __   __ ' -ForegroundColor Yellow
    Write-Host '| $$/  $\| $$ /      \  /      \ | $$  /  \| $$_  \$$| $$ /      \ |  \ |  \ |  \' -ForegroundColor Yellow
    Write-Host '| $$  $$$\ $$|  $$$$$$\|  $$$$$$\| $$_/  $$| $$ \    | $$|  $$$$$$\| $$ | $$ | $$' -ForegroundColor Yellow
    Write-Host '| $$ $$\$$\$$| $$  | $$| $$   \$$| $$   $$ | $$$$    | $$| $$  | $$| $$ | $$ | $$' -ForegroundColor Yellow
    Write-Host '| $$$$  \$$$$| $$__/ $$| $$      | $$$$$$\ | $$      | $$| $$__/ $$| $$_/ $$_/ $$' -ForegroundColor Yellow
    Write-Host '| $$$    \$$$ \$$    $$| $$      | $$  \$$\| $$      | $$ \$$    $$ \$$   $$   $$' -ForegroundColor Yellow
    Write-Host ' \$$      \$$  \$$$$$$  \$$       \$$   \$$ \$$       \$$  \$$$$$$   \$$$$$\$$$$' -ForegroundColor Yellow
    Write-Host ""
}

function Show-Header {
    param(
        [string]$InstallVersion = $DefaultVersion
    )

    Show-Banner
    Write-ColorOutput "    $ScriptName v$ScriptVersion" $ColorInfo
    if ($InstallVersion -ne "unknown") {
        Write-ColorOutput "    Installing Claude Code Workflow v$InstallVersion" $ColorInfo
    }
    Write-ColorOutput "    Unified workflow system with comprehensive coordination" $ColorInfo
    Write-ColorOutput "========================================================================" $ColorInfo
    if ($NoBackup) {
        Write-ColorOutput "WARNING: Backup disabled - existing files will be overwritten!" $ColorWarning
    } else {
        Write-ColorOutput "Auto-backup enabled - existing files will be backed up" $ColorSuccess
    }
    Write-Host ""
}

function Test-Prerequisites {
    # Test PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-ColorOutput "ERROR: PowerShell 5.1 or higher is required" $ColorError
        Write-ColorOutput "Current version: $($PSVersionTable.PSVersion)" $ColorError
        return $false
    }

    # Test source files exist
    $sourceDir = $PSScriptRoot
    $claudeDir = Join-Path $sourceDir ".claude"
    $claudeMd = Join-Path $sourceDir "CLAUDE.md"
    $codexDir = Join-Path $sourceDir ".codex"
    $geminiDir = Join-Path $sourceDir ".gemini"
    $qwenDir = Join-Path $sourceDir ".qwen"

    if (-not (Test-Path $claudeDir)) {
        Write-ColorOutput "ERROR: .claude directory not found in $sourceDir" $ColorError
        return $false
    }

    if (-not (Test-Path $claudeMd)) {
        Write-ColorOutput "ERROR: CLAUDE.md file not found in $sourceDir" $ColorError
        return $false
    }

    if (-not (Test-Path $codexDir)) {
        Write-ColorOutput "ERROR: .codex directory not found in $sourceDir" $ColorError
        return $false
    }

    if (-not (Test-Path $geminiDir)) {
        Write-ColorOutput "ERROR: .gemini directory not found in $sourceDir" $ColorError
        return $false
    }

    if (-not (Test-Path $qwenDir)) {
        Write-ColorOutput "ERROR: .qwen directory not found in $sourceDir" $ColorError
        return $false
    }

    Write-ColorOutput "Prerequisites check passed" $ColorSuccess
    return $true
}

function Get-UserChoiceWithArrows {
    param(
        [string]$Prompt,
        [string[]]$Options,
        [int]$DefaultIndex = 0
    )

    if ($NonInteractive) {
        Write-ColorOutput "Non-interactive mode: Using default '$($Options[$DefaultIndex])'" $ColorInfo
        return $Options[$DefaultIndex]
    }

    # Test if we can use console features (interactive terminal)
    $canUseConsole = $true
    try {
        $null = [Console]::CursorVisible
        $null = $Host.UI.RawUI.ReadKey
    }
    catch {
        $canUseConsole = $false
    }

    # Fallback to simple numbered menu if console not available
    if (-not $canUseConsole) {
        Write-ColorOutput "Arrow navigation not available in this environment. Using numbered menu." $ColorWarning
        return Get-UserChoice -Prompt $Prompt -Options $Options -Default $Options[$DefaultIndex]
    }

    $selectedIndex = $DefaultIndex
    $cursorVisible = $true

    try {
        $cursorVisible = [Console]::CursorVisible
        [Console]::CursorVisible = $false
    }
    catch {
        # Silently continue if cursor control fails
    }

    try {
        Write-Host ""
        Write-ColorOutput $Prompt $ColorPrompt
        Write-Host ""

        while ($true) {
            # Display options
            for ($i = 0; $i -lt $Options.Count; $i++) {
                $prefix = if ($i -eq $selectedIndex) { "  > " } else { "    " }
                $color = if ($i -eq $selectedIndex) { $ColorSuccess } else { "White" }

                # Clear line and write option
                Write-Host "`r$prefix$($Options[$i])".PadRight(80) -ForegroundColor $color
            }

            Write-Host ""
            Write-Host "  Use " -NoNewline -ForegroundColor DarkGray
            Write-Host "UP/DOWN" -NoNewline -ForegroundColor Yellow
            Write-Host " arrows to navigate, " -NoNewline -ForegroundColor DarkGray
            Write-Host "ENTER" -NoNewline -ForegroundColor Yellow
            Write-Host " to select, or type " -NoNewline -ForegroundColor DarkGray
            Write-Host "1-$($Options.Count)" -NoNewline -ForegroundColor Yellow
            Write-Host "" -ForegroundColor DarkGray

            # Read key
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            # Handle arrow keys
            if ($key.VirtualKeyCode -eq 38) {
                # Up arrow
                $selectedIndex = if ($selectedIndex -gt 0) { $selectedIndex - 1 } else { $Options.Count - 1 }
            }
            elseif ($key.VirtualKeyCode -eq 40) {
                # Down arrow
                $selectedIndex = if ($selectedIndex -lt ($Options.Count - 1)) { $selectedIndex + 1 } else { 0 }
            }
            elseif ($key.VirtualKeyCode -eq 13) {
                # Enter key
                Write-Host ""
                return $Options[$selectedIndex]
            }
            elseif ($key.Character -match '^\d$') {
                # Number key
                $num = [int]::Parse($key.Character)
                if ($num -ge 1 -and $num -le $Options.Count) {
                    Write-Host ""
                    return $Options[$num - 1]
                }
            }

            # Move cursor back up to redraw menu
            $linesToMove = $Options.Count + 2
            try {
                for ($i = 0; $i -lt $linesToMove; $i++) {
                    [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
                }
            }
            catch {
                # If cursor positioning fails, just continue
                break
            }
        }
    }
    finally {
        try {
            [Console]::CursorVisible = $cursorVisible
        }
        catch {
            # Silently continue if cursor control fails
        }
    }
}

function Get-UserChoice {
    param(
        [string]$Prompt,
        [string[]]$Options,
        [string]$Default = $null
    )

    if ($NonInteractive -and $Default) {
        Write-ColorOutput "Non-interactive mode: Using default '$Default'" $ColorInfo
        return $Default
    }

    Write-ColorOutput $Prompt $ColorPrompt
    for ($i = 0; $i -lt $Options.Count; $i++) {
        if ($Default -and $Options[$i] -eq $Default) {
            $marker = " (default)"
        } else {
            $marker = ""
        }
        Write-Host "  $($i + 1). $($Options[$i])$marker"
    }

    do {
        $input = Read-Host "Please select (1-$($Options.Count))"
        if ([string]::IsNullOrWhiteSpace($input) -and $Default) {
            return $Default
        }

        $index = $null
        if ([int]::TryParse($input, [ref]$index) -and $index -ge 1 -and $index -le $Options.Count) {
            return $Options[$index - 1]
        }

        Write-ColorOutput "Invalid selection. Please enter a number between 1 and $($Options.Count)" $ColorWarning
    } while ($true)
}

function Confirm-Action {
    param(
        [string]$Message,
        [switch]$DefaultYes
    )

    if ($Force) {
        Write-ColorOutput "Force mode: Proceeding with '$Message'" $ColorInfo
        return $true
    }

    if ($NonInteractive) {
        if ($DefaultYes) {
            $result = $true
        } else {
            $result = $false
        }
        if ($result) {
            $resultText = 'Yes'
        } else {
            $resultText = 'No'
        }
        Write-ColorOutput "Non-interactive mode: $Message - $resultText" $ColorInfo
        return $result
    }

    if ($DefaultYes) {
        $defaultChar = "Y"
        $prompt = "(Y/n)"
    } else {
        $defaultChar = "N"
        $prompt = "(y/N)"
    }

    do {
        $response = Read-Host "$Message $prompt"
        if ([string]::IsNullOrWhiteSpace($response)) {
            return $DefaultYes
        }

        switch ($response.ToLower()) {
            { $_ -in @('y', 'yes') } { return $true }
            { $_ -in @('n', 'no') } { return $false }
            default {
                Write-ColorOutput "Please answer 'y' or 'n'" $ColorWarning
            }
        }
    } while ($true)
}

function Get-BackupDirectory {
    param(
        [string]$TargetDirectory
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDirName = "claude-backup-$timestamp"
    $backupPath = Join-Path $TargetDirectory $backupDirName

    # Ensure backup directory exists
    if (-not (Test-Path $backupPath)) {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    }

    return $backupPath
}

function Backup-FileToFolder {
    param(
        [string]$FilePath,
        [string]$BackupFolder
    )

    if (-not (Test-Path $FilePath)) {
        return $false
    }

    try {
        $fileName = Split-Path $FilePath -Leaf
        $relativePath = ""

        # Try to determine relative path structure for better organization
        $fileDir = Split-Path $FilePath -Parent
        if ($fileDir -match '\.claude') {
            # Extract path relative to .claude directory
            $claudeIndex = $fileDir.LastIndexOf('.claude')
            if ($claudeIndex -ge 0) {
                $relativePath = $fileDir.Substring($claudeIndex + 7) # +7 for ".claude\"
                if ($relativePath.StartsWith('\')) {
                    $relativePath = $relativePath.Substring(1)
                }
            }
        }

        # Create subdirectory structure in backup if needed
        $backupSubDir = $BackupFolder
        if (-not [string]::IsNullOrEmpty($relativePath)) {
            $backupSubDir = Join-Path $BackupFolder $relativePath
            if (-not (Test-Path $backupSubDir)) {
                New-Item -ItemType Directory -Path $backupSubDir -Force | Out-Null
            }
        }

        $backupFilePath = Join-Path $backupSubDir $fileName
        Copy-Item -Path $FilePath -Destination $backupFilePath -Force

        Write-ColorOutput "Backed up: $fileName" $ColorInfo
        return $true
    } catch {
        Write-ColorOutput "WARNING: Failed to backup file $FilePath`: $($_.Exception.Message)" $ColorWarning
        return $false
    }
}

function Backup-DirectoryToFolder {
    param(
        [string]$DirectoryPath,
        [string]$BackupFolder
    )

    if (-not (Test-Path $DirectoryPath)) {
        return $false
    }

    try {
        $dirName = Split-Path $DirectoryPath -Leaf
        $backupDirPath = Join-Path $BackupFolder $dirName

        Copy-Item -Path $DirectoryPath -Destination $backupDirPath -Recurse -Force
        Write-ColorOutput "Backed up directory: $dirName" $ColorInfo
        return $true
    } catch {
        Write-ColorOutput "WARNING: Failed to backup directory $DirectoryPath`: $($_.Exception.Message)" $ColorWarning
        return $false
    }
}

function Copy-DirectoryRecursive {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        throw "Source directory does not exist: $Source"
    }

    # Create destination directory if it doesn't exist
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    try {
        # Copy all items recursively
        Copy-Item -Path "$Source\*" -Destination $Destination -Recurse -Force
        Write-ColorOutput "Directory copied: $Source -> $Destination" $ColorSuccess
    } catch {
        throw "Failed to copy directory: $($_.Exception.Message)"
    }
}

function Copy-FileToDestination {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description = "file",
        [string]$BackupFolder = $null
    )

    if (Test-Path $Destination) {
        # Use BackupAll mode for automatic backup without confirmation (default behavior)
        if ($BackupAll -and -not $NoBackup) {
            if ($BackupFolder -and (Backup-FileToFolder -FilePath $Destination -BackupFolder $BackupFolder)) {
                Write-ColorOutput "Auto-backed up: $Description" $ColorSuccess
            }
            Copy-Item -Path $Source -Destination $Destination -Force
            Write-ColorOutput "$Description updated (with backup)" $ColorSuccess
            return $true
        } elseif ($NoBackup) {
            # No backup mode - ask for confirmation
            if (Confirm-Action "$Description already exists. Replace it? (NO BACKUP)" -DefaultYes:$false) {
                Copy-Item -Path $Source -Destination $Destination -Force
                Write-ColorOutput "$Description updated (no backup)" $ColorWarning
                return $true
            } else {
                Write-ColorOutput "Skipping $Description installation" $ColorWarning
                return $false
            }
        } elseif (Confirm-Action "$Description already exists. Replace it?" -DefaultYes:$false) {
            if ($BackupFolder -and (Backup-FileToFolder -FilePath $Destination -BackupFolder $BackupFolder)) {
                Write-ColorOutput "Existing $Description backed up" $ColorSuccess
            }
            Copy-Item -Path $Source -Destination $Destination -Force
            Write-ColorOutput "$Description updated" $ColorSuccess
            return $true
        } else {
            Write-ColorOutput "Skipping $Description installation" $ColorWarning
            return $false
        }
    } else {
        # Ensure destination directory exists
        $destinationDir = Split-Path $Destination -Parent
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-ColorOutput "$Description installed" $ColorSuccess
        return $true
    }
}

function Backup-AndReplaceDirectory {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description = "directory",
        [string]$BackupFolder = $null
    )

    if (-not (Test-Path $Source)) {
        Write-ColorOutput "WARNING: Source $Description not found: $Source" $ColorWarning
        return $false
    }

    # Backup destination if it exists
    if (Test-Path $Destination) {
        Write-ColorOutput "Found existing $Description at: $Destination" $ColorInfo

        # Backup entire directory if backup is enabled
        if (-not $NoBackup -and $BackupFolder) {
            Write-ColorOutput "Backing up entire $Description..." $ColorInfo
            if (Backup-DirectoryToFolder -DirectoryPath $Destination -BackupFolder $BackupFolder) {
                Write-ColorOutput "Backed up $Description to: $BackupFolder" $ColorSuccess
            }
        } elseif ($NoBackup) {
            if (-not (Confirm-Action "Replace existing $Description without backup?" -DefaultYes:$false)) {
                Write-ColorOutput "Skipping $Description installation" $ColorWarning
                return $false
            }
        }

        # Get all items from source to determine what to clear in destination
        Write-ColorOutput "Clearing conflicting items in destination $Description..." $ColorInfo
        $sourceItems = Get-ChildItem -Path $Source -Force

        foreach ($sourceItem in $sourceItems) {
            $destItemPath = Join-Path $Destination $sourceItem.Name
            if (Test-Path $destItemPath) {
                Write-ColorOutput "Removing existing: $($sourceItem.Name)" $ColorInfo
                Remove-Item -Path $destItemPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Write-ColorOutput "Cleared conflicting items in destination" $ColorSuccess
    } else {
        # Create destination directory if it doesn't exist
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        Write-ColorOutput "Created destination directory: $Destination" $ColorInfo
    }

    # Copy all items from source to destination
    Write-ColorOutput "Copying $Description from $Source to $Destination..." $ColorInfo
    $sourceItems = Get-ChildItem -Path $Source -Force
    foreach ($item in $sourceItems) {
        $destPath = Join-Path $Destination $item.Name
        Copy-Item -Path $item.FullName -Destination $destPath -Recurse -Force
    }
    Write-ColorOutput "$Description installed successfully" $ColorSuccess

    return $true
}

function Backup-CriticalConfigFiles {
    param(
        [string]$TargetDirectory,
        [string]$BackupFolder,
        [string[]]$FileNames
    )

    if (-not $BackupFolder -or $NoBackup) {
        return
    }

    if (-not (Test-Path $TargetDirectory)) {
        return
    }

    $backedUpCount = 0
    foreach ($fileName in $FileNames) {
        $filePath = Join-Path $TargetDirectory $fileName
        if (Test-Path $filePath) {
            if (Backup-FileToFolder -FilePath $filePath -BackupFolder $BackupFolder) {
                Write-ColorOutput "Critical config backed up: $fileName" $ColorSuccess
                $backedUpCount++
            }
        }
    }

    if ($backedUpCount -gt 0) {
        Write-ColorOutput "Backed up $backedUpCount critical configuration file(s)" $ColorInfo
    }
}

function Merge-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description = "directory contents",
        [string]$BackupFolder = $null
    )

    if (-not (Test-Path $Source)) {
        Write-ColorOutput "WARNING: Source $Description not found: $Source" $ColorWarning
        return $false
    }

    # Create destination directory if it doesn't exist
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        Write-ColorOutput "Created destination directory: $Destination" $ColorInfo
    }

    # Get all items in source directory
    $sourceItems = Get-ChildItem -Path $Source -Recurse -File
    $mergedCount = 0
    $skippedCount = 0

    foreach ($item in $sourceItems) {
        # Calculate relative path from source
        $relativePath = $item.FullName.Substring($Source.Length + 1)
        $destinationPath = Join-Path $Destination $relativePath

        # Ensure destination directory exists
        $destinationDir = Split-Path $destinationPath -Parent
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        # Handle file merging
        if (Test-Path $destinationPath) {
            $fileName = Split-Path $relativePath -Leaf
            # Use BackupAll mode for automatic backup without confirmation (default behavior)
            if ($BackupAll -and -not $NoBackup) {
                if ($BackupFolder -and (Backup-FileToFolder -FilePath $destinationPath -BackupFolder $BackupFolder)) {
                    Write-ColorOutput "Auto-backed up: $fileName" $ColorInfo
                }
                Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                $mergedCount++
            } elseif ($NoBackup) {
                # No backup mode - ask for confirmation
                if (Confirm-Action "File '$relativePath' already exists. Replace it? (NO BACKUP)" -DefaultYes:$false) {
                    Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                    $mergedCount++
                } else {
                    Write-ColorOutput "Skipped $fileName (no backup)" $ColorWarning
                    $skippedCount++
                }
            } elseif (Confirm-Action "File '$relativePath' already exists. Replace it?" -DefaultYes:$false) {
                if ($BackupFolder -and (Backup-FileToFolder -FilePath $destinationPath -BackupFolder $BackupFolder)) {
                    Write-ColorOutput "Backed up existing $fileName" $ColorInfo
                }
                Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                $mergedCount++
            } else {
                Write-ColorOutput "Skipped $fileName" $ColorWarning
                $skippedCount++
            }
        } else {
            Copy-Item -Path $item.FullName -Destination $destinationPath -Force
            $mergedCount++
        }
    }

    Write-ColorOutput "Merged $mergedCount files, skipped $skippedCount files" $ColorSuccess
    return $true
}

# ============================================================================
# INSTALLATION MANIFEST MANAGEMENT
# ============================================================================

function New-InstallManifest {
    <#
    .SYNOPSIS
        Create a new installation manifest to track installed files
    #>
    param(
        [string]$InstallationMode,
        [string]$InstallationPath
    )

    # Create manifest directory if it doesn't exist
    if (-not (Test-Path $script:ManifestDir)) {
        New-Item -ItemType Directory -Path $script:ManifestDir -Force | Out-Null
    }

    # Generate unique manifest ID based on timestamp and mode
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $manifestId = "install-$InstallationMode-$timestamp"

    $manifest = @{
        manifest_id = $manifestId
        version = "1.0"
        installation_mode = $InstallationMode
        installation_path = $InstallationPath
        installation_date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        installer_version = $ScriptVersion
        files = @()
        directories = @()
    }

    return $manifest
}

function Add-ManifestEntry {
    <#
    .SYNOPSIS
        Add a file or directory entry to the manifest
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Manifest,

        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [ValidateSet("File", "Directory")]
        [string]$Type
    )

    $entry = @{
        path = $Path
        type = $Type
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }

    if ($Type -eq "File") {
        $Manifest.files += $entry
    } else {
        $Manifest.directories += $entry
    }
}

function Save-InstallManifest {
    <#
    .SYNOPSIS
        Save the installation manifest to disk
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Manifest
    )

    try {
        # Use manifest ID to create unique file name
        $manifestFileName = "$($Manifest.manifest_id).json"
        $manifestPath = Join-Path $script:ManifestDir $manifestFileName

        $Manifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $manifestPath -Encoding utf8 -Force
        Write-ColorOutput "Installation manifest saved: $manifestPath" $ColorSuccess
        return $true
    } catch {
        Write-ColorOutput "WARNING: Failed to save installation manifest: $($_.Exception.Message)" $ColorWarning
        return $false
    }
}

function Migrate-LegacyManifest {
    <#
    .SYNOPSIS
        Migrate old single manifest file to new multi-manifest system
    #>

    $legacyManifestPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) ".claude-install-manifest.json"

    if (-not (Test-Path $legacyManifestPath)) {
        return
    }

    try {
        Write-ColorOutput "Found legacy manifest file, migrating to new system..." $ColorInfo

        # Create manifest directory if it doesn't exist
        if (-not (Test-Path $script:ManifestDir)) {
            New-Item -ItemType Directory -Path $script:ManifestDir -Force | Out-Null
        }

        # Read legacy manifest
        $legacyJson = Get-Content -Path $legacyManifestPath -Raw -Encoding utf8
        $legacy = $legacyJson | ConvertFrom-Json

        # Generate new manifest ID
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $mode = if ($legacy.installation_mode) { $legacy.installation_mode } else { "Global" }
        $manifestId = "install-$mode-$timestamp-migrated"

        # Create new manifest with all fields
        $newManifest = @{
            manifest_id = $manifestId
            version = if ($legacy.version) { $legacy.version } else { "1.0" }
            installation_mode = $mode
            installation_path = if ($legacy.installation_path) { $legacy.installation_path } else { [Environment]::GetFolderPath("UserProfile") }
            installation_date = if ($legacy.installation_date) { $legacy.installation_date } else { (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") }
            installer_version = if ($legacy.installer_version) { $legacy.installer_version } else { "unknown" }
            files = if ($legacy.files) { @($legacy.files) } else { @() }
            directories = if ($legacy.directories) { @($legacy.directories) } else { @() }
        }

        # Save to new location
        $newManifestPath = Join-Path $script:ManifestDir "$manifestId.json"
        $newManifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $newManifestPath -Encoding utf8 -Force

        # Rename old manifest (don't delete, keep as backup)
        $backupPath = "$legacyManifestPath.migrated"
        Move-Item -Path $legacyManifestPath -Destination $backupPath -Force

        Write-ColorOutput "Legacy manifest migrated successfully" $ColorSuccess
        Write-ColorOutput "Old manifest backed up to: $backupPath" $ColorInfo
    } catch {
        Write-ColorOutput "WARNING: Failed to migrate legacy manifest: $($_.Exception.Message)" $ColorWarning
    }
}

function Get-AllInstallManifests {
    <#
    .SYNOPSIS
        Get all installation manifests
    #>

    # Migrate legacy manifest if exists
    Migrate-LegacyManifest

    if (-not (Test-Path $script:ManifestDir)) {
        return @()
    }

    try {
        $manifestFiles = Get-ChildItem -Path $script:ManifestDir -Filter "install-*.json" -File | Sort-Object LastWriteTime -Descending
        $manifests = [System.Collections.ArrayList]::new()

        foreach ($file in $manifestFiles) {
            try {
                $manifestJson = Get-Content -Path $file.FullName -Raw -Encoding utf8
                $manifest = $manifestJson | ConvertFrom-Json

                # Convert to hashtable for easier manipulation
                # Handle both old and new manifest formats

                # Safely get array counts
                $filesCount = 0
                $dirsCount = 0

                if ($manifest.files) {
                    if ($manifest.files -is [System.Array]) {
                        $filesCount = $manifest.files.Count
                    } else {
                        $filesCount = 1
                    }
                }

                if ($manifest.directories) {
                    if ($manifest.directories -is [System.Array]) {
                        $dirsCount = $manifest.directories.Count
                    } else {
                        $dirsCount = 1
                    }
                }

                $manifestHash = @{
                    manifest_id = if ($manifest.manifest_id) { $manifest.manifest_id } else { $file.BaseName }
                    manifest_file = $file.FullName
                    version = if ($manifest.version) { $manifest.version } else { "1.0" }
                    installation_mode = if ($manifest.installation_mode) { $manifest.installation_mode } else { "Unknown" }
                    installation_path = if ($manifest.installation_path) { $manifest.installation_path } else { "" }
                    installation_date = if ($manifest.installation_date) { $manifest.installation_date } else { $file.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ") }
                    installer_version = if ($manifest.installer_version) { $manifest.installer_version } else { "unknown" }
                    files = if ($manifest.files) { @($manifest.files) } else { @() }
                    directories = if ($manifest.directories) { @($manifest.directories) } else { @() }
                    files_count = $filesCount
                    directories_count = $dirsCount
                }

                $null = $manifests.Add($manifestHash)
            } catch {
                Write-ColorOutput "WARNING: Failed to load manifest $($file.Name): $($_.Exception.Message)" $ColorWarning
            }
        }

        return ,$manifests.ToArray()
    } catch {
        Write-ColorOutput "ERROR: Failed to list installation manifests: $($_.Exception.Message)" $ColorError
        return @()
    }
}

# ============================================================================
# UNINSTALLATION FUNCTIONS
# ============================================================================

function Uninstall-ClaudeWorkflow {
    <#
    .SYNOPSIS
        Uninstall Claude Code Workflow based on installation manifest
    #>

    Write-ColorOutput "Claude Code Workflow System Uninstaller" $ColorInfo
    Write-ColorOutput "========================================" $ColorInfo
    Write-Host ""

    # Load all manifests
    $manifests = Get-AllInstallManifests

    if (-not $manifests -or $manifests.Count -eq 0) {
        Write-ColorOutput "ERROR: No installation manifests found in: $script:ManifestDir" $ColorError
        Write-ColorOutput "Cannot proceed with uninstallation without manifest." $ColorError
        Write-Host ""
        Write-ColorOutput "Manual uninstallation instructions:" $ColorInfo
        Write-Host "For Global installation, remove these directories:"
        Write-Host "  - ~/.claude/agents"
        Write-Host "  - ~/.claude/commands"
        Write-Host "  - ~/.claude/output-styles"
        Write-Host "  - ~/.claude/workflows"
        Write-Host "  - ~/.claude/scripts"
        Write-Host "  - ~/.claude/prompt-templates"
        Write-Host "  - ~/.claude/python_script"
        Write-Host "  - ~/.claude/skills"
        Write-Host "  - ~/.claude/version.json"
        Write-Host "  - ~/.claude/CLAUDE.md"
        Write-Host "  - ~/.codex"
        Write-Host "  - ~/.gemini"
        Write-Host "  - ~/.qwen"
        return $false
    }

    # Display available installations
    Write-ColorOutput "Found $($manifests.Count) installation(s):" $ColorInfo
    Write-Host ""

    # If only one manifest, use it directly
    $selectedManifest = $null
    if ($manifests.Count -eq 1) {
        $selectedManifest = $manifests[0]
        Write-ColorOutput "Only one installation found, will uninstall:" $ColorInfo
    } else {
        # Multiple manifests - let user choose
        $options = @()
        for ($i = 0; $i -lt $manifests.Count; $i++) {
            $m = $manifests[$i]

            # Safely extract date string
            $dateStr = "unknown date"
            if ($m.installation_date) {
                try {
                    if ($m.installation_date.Length -ge 10) {
                        $dateStr = $m.installation_date.Substring(0, 10)
                    } else {
                        $dateStr = $m.installation_date
                    }
                } catch {
                    $dateStr = "unknown date"
                }
            }

            # Build option string with safe counts
            $filesCount = if ($m.files_count) { $m.files_count } else { 0 }
            $dirsCount = if ($m.directories_count) { $m.directories_count } else { 0 }
            $pathInfo = if ($m.installation_path) { " ($($m.installation_path))" } else { "" }
            $option = "$($i + 1). [$($m.installation_mode)] $dateStr - $filesCount files, $dirsCount dirs$pathInfo"
            $options += $option
        }
        $options += "Cancel - Don't uninstall anything"

        Write-Host ""
        $selection = Get-UserChoiceWithArrows -Prompt "Select installation to uninstall:" -Options $options -DefaultIndex 0

        if ($selection -like "Cancel*") {
            Write-ColorOutput "Uninstallation cancelled." $ColorWarning
            return $false
        }

        # Parse selection to get index
        $selectedIndex = [int]($selection.Split('.')[0]) - 1
        $selectedManifest = $manifests[$selectedIndex]
    }

    # Display selected installation info
    Write-Host ""
    Write-ColorOutput "Installation Information:" $ColorInfo
    Write-Host "  Manifest ID: $($selectedManifest.manifest_id)"
    Write-Host "  Mode: $($selectedManifest.installation_mode)"
    Write-Host "  Path: $($selectedManifest.installation_path)"
    Write-Host "  Date: $($selectedManifest.installation_date)"
    Write-Host "  Installer Version: $($selectedManifest.installer_version)"

    # Use pre-calculated counts
    $filesCount = if ($selectedManifest.files_count) { $selectedManifest.files_count } else { 0 }
    $dirsCount = if ($selectedManifest.directories_count) { $selectedManifest.directories_count } else { 0 }
    Write-Host "  Files tracked: $filesCount"
    Write-Host "  Directories tracked: $dirsCount"
    Write-Host ""

    # Confirm uninstallation
    if (-not (Confirm-Action "Do you want to uninstall this installation?" -DefaultYes:$false)) {
        Write-ColorOutput "Uninstallation cancelled." $ColorWarning
        return $false
    }

    # Use the selected manifest for uninstallation
    $manifest = $selectedManifest

    $removedFiles = 0
    $removedDirs = 0
    $failedItems = @()

    # Remove files first
    Write-ColorOutput "Removing installed files..." $ColorInfo
    foreach ($fileEntry in $manifest.files) {
        $filePath = $fileEntry.path

        if (Test-Path $filePath) {
            try {
                Remove-Item -Path $filePath -Force -ErrorAction Stop
                Write-ColorOutput "  Removed file: $filePath" $ColorSuccess
                $removedFiles++
            } catch {
                Write-ColorOutput "  WARNING: Failed to remove file: $filePath" $ColorWarning
                $failedItems += $filePath
            }
        } else {
            Write-ColorOutput "  File not found (already removed): $filePath" $ColorInfo
        }
    }

    # Remove directories (in reverse order to handle nested directories)
    Write-ColorOutput "Removing installed directories..." $ColorInfo
    $sortedDirs = $manifest.directories | Sort-Object { $_.path.Length } -Descending

    foreach ($dirEntry in $sortedDirs) {
        $dirPath = $dirEntry.path

        if (Test-Path $dirPath) {
            try {
                # Check if directory is empty or only contains files we installed
                $dirContents = Get-ChildItem -Path $dirPath -Recurse -Force -ErrorAction SilentlyContinue

                if (-not $dirContents -or ($dirContents | Measure-Object).Count -eq 0) {
                    Remove-Item -Path $dirPath -Recurse -Force -ErrorAction Stop
                    Write-ColorOutput "  Removed directory: $dirPath" $ColorSuccess
                    $removedDirs++
                } else {
                    Write-ColorOutput "  Directory not empty (preserved): $dirPath" $ColorWarning
                }
            } catch {
                Write-ColorOutput "  WARNING: Failed to remove directory: $dirPath" $ColorWarning
                $failedItems += $dirPath
            }
        } else {
            Write-ColorOutput "  Directory not found (already removed): $dirPath" $ColorInfo
        }
    }

    # Remove manifest file
    if (Test-Path $manifest.manifest_file) {
        try {
            Remove-Item -Path $manifest.manifest_file -Force
            Write-ColorOutput "Removed installation manifest: $($manifest.manifest_id)" $ColorSuccess
        } catch {
            Write-ColorOutput "WARNING: Failed to remove manifest file" $ColorWarning
        }
    }

    # Show summary
    Write-Host ""
    Write-ColorOutput "========================================" $ColorInfo
    Write-ColorOutput "Uninstallation Summary:" $ColorInfo
    Write-Host "  Files removed: $removedFiles"
    Write-Host "  Directories removed: $removedDirs"

    if ($failedItems.Count -gt 0) {
        Write-Host ""
        Write-ColorOutput "Failed to remove the following items:" $ColorWarning
        foreach ($item in $failedItems) {
            Write-Host "  - $item"
        }
    }

    Write-Host ""
    if ($failedItems.Count -eq 0) {
        Write-ColorOutput "Claude Code Workflow has been successfully uninstalled!" $ColorSuccess
    } else {
        Write-ColorOutput "Uninstallation completed with warnings." $ColorWarning
        Write-ColorOutput "Please manually remove the failed items listed above." $ColorInfo
    }

    return $true
}

function Create-VersionJson {
    param(
        [string]$TargetClaudeDir,
        [string]$InstallationMode
    )

    # Determine version from source parameter (passed from install-remote.ps1)
    $versionNumber = if ($SourceVersion) { $SourceVersion } else { $DefaultVersion }
    $sourceBranch = if ($SourceBranch) { $SourceBranch } else { "unknown" }
    $commitSha = if ($SourceCommit) { $SourceCommit } else { "unknown" }

    # Create version.json content
    $versionInfo = @{
        version = $versionNumber
        commit_sha = $commitSha
        installation_mode = $InstallationMode
        installation_path = $TargetClaudeDir
        installation_date_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        source_branch = $sourceBranch
        installer_version = $ScriptVersion
    }

    $versionJsonPath = Join-Path $TargetClaudeDir "version.json"

    try {
        $versionInfo | ConvertTo-Json | Out-File -FilePath $versionJsonPath -Encoding utf8 -Force
        Write-ColorOutput "Created version.json: $versionNumber ($commitSha) - $InstallationMode" $ColorSuccess
        return $true
    } catch {
        Write-ColorOutput "WARNING: Failed to create version.json: $($_.Exception.Message)" $ColorWarning
        return $false
    }
}

function Install-Global {
    Write-ColorOutput "Installing Claude Code Workflow System globally..." $ColorInfo

    # Determine user profile directory
    $userProfile = [Environment]::GetFolderPath("UserProfile")
    $globalClaudeDir = Join-Path $userProfile ".claude"
    $globalClaudeMd = Join-Path $globalClaudeDir "CLAUDE.md"
    $globalCodexDir = Join-Path $userProfile ".codex"
    $globalGeminiDir = Join-Path $userProfile ".gemini"
    $globalQwenDir = Join-Path $userProfile ".qwen"

    Write-ColorOutput "Global installation path: $userProfile" $ColorInfo

    # Initialize manifest
    $manifest = New-InstallManifest -InstallationMode "Global" -InstallationPath $userProfile

    # Source paths
    $sourceDir = $PSScriptRoot
    $sourceClaudeDir = Join-Path $sourceDir ".claude"
    $sourceClaudeMd = Join-Path $sourceDir "CLAUDE.md"
    $sourceCodexDir = Join-Path $sourceDir ".codex"
    $sourceGeminiDir = Join-Path $sourceDir ".gemini"
    $sourceQwenDir = Join-Path $sourceDir ".qwen"

    # Create backup folder if needed (default behavior unless NoBackup is specified)
    $backupFolder = $null
    if (-not $NoBackup) {
        if ((Test-Path $globalClaudeDir) -or (Test-Path $globalCodexDir) -or (Test-Path $globalGeminiDir) -or (Test-Path $globalQwenDir)) {
            $existingFiles = @()
            if (Test-Path $globalClaudeDir) {
                $existingFiles += Get-ChildItem $globalClaudeDir -Recurse -File -ErrorAction SilentlyContinue
            }
            if (Test-Path $globalCodexDir) {
                $existingFiles += Get-ChildItem $globalCodexDir -Recurse -File -ErrorAction SilentlyContinue
            }
            if (Test-Path $globalGeminiDir) {
                $existingFiles += Get-ChildItem $globalGeminiDir -Recurse -File -ErrorAction SilentlyContinue
            }
            if (Test-Path $globalQwenDir) {
                $existingFiles += Get-ChildItem $globalQwenDir -Recurse -File -ErrorAction SilentlyContinue
            }
            if (($existingFiles -and ($existingFiles | Measure-Object).Count -gt 0)) {
                $backupFolder = Get-BackupDirectory -TargetDirectory $userProfile
                Write-ColorOutput "Backup folder created: $backupFolder" $ColorInfo
            }
        } elseif (Test-Path $globalClaudeMd) {
            # Create backup folder even if .claude directory doesn't exist but CLAUDE.md does
            $backupFolder = Get-BackupDirectory -TargetDirectory $userProfile
            Write-ColorOutput "Backup folder created: $backupFolder" $ColorInfo
        }
    }

    # Merge .claude directory (incremental overlay - preserves user files)
    Write-ColorOutput "Installing .claude directory (incremental merge)..." $ColorInfo
    $claudeInstalled = Merge-DirectoryContents -Source $sourceClaudeDir -Destination $globalClaudeDir -Description ".claude directory" -BackupFolder $backupFolder

    # Track .claude directory in manifest
    if ($claudeInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $globalClaudeDir -Type "Directory"

        # Track files from SOURCE directory, not destination
        Get-ChildItem -Path $sourceClaudeDir -Recurse -File | ForEach-Object {
            # Calculate target path where this file will be installed
            $relativePath = $_.FullName.Substring($sourceClaudeDir.Length)
            $targetPath = $globalClaudeDir + $relativePath
            Add-ManifestEntry -Manifest $manifest -Path $targetPath -Type "File"
        }
    }

    # Handle CLAUDE.md file in .claude directory
    Write-ColorOutput "Installing CLAUDE.md to global .claude directory..." $ColorInfo
    $claudeMdInstalled = Copy-FileToDestination -Source $sourceClaudeMd -Destination $globalClaudeMd -Description "CLAUDE.md" -BackupFolder $backupFolder

    # Track CLAUDE.md in manifest
    if ($claudeMdInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $globalClaudeMd -Type "File"
    }

    # Backup critical config files in .codex directory before installation
    Backup-CriticalConfigFiles -TargetDirectory $globalCodexDir -BackupFolder $backupFolder -FileNames @("AGENTS.md")

    # Merge .codex directory (incremental overlay - preserves user files)
    Write-ColorOutput "Installing .codex directory (incremental merge)..." $ColorInfo
    $codexInstalled = Merge-DirectoryContents -Source $sourceCodexDir -Destination $globalCodexDir -Description ".codex directory" -BackupFolder $backupFolder

    # Track .codex directory in manifest
    if ($codexInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $globalCodexDir -Type "Directory"
        # Track files from SOURCE directory
        Get-ChildItem -Path $sourceCodexDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceCodexDir.Length)
            $targetPath = $globalCodexDir + $relativePath
            Add-ManifestEntry -Manifest $manifest -Path $targetPath -Type "File"
        }
    }

    # Backup critical config files in .gemini directory before installation
    Backup-CriticalConfigFiles -TargetDirectory $globalGeminiDir -BackupFolder $backupFolder -FileNames @("GEMINI.md", "CLAUDE.md")

    # Merge .gemini directory (incremental overlay - preserves user files)
    Write-ColorOutput "Installing .gemini directory (incremental merge)..." $ColorInfo
    $geminiInstalled = Merge-DirectoryContents -Source $sourceGeminiDir -Destination $globalGeminiDir -Description ".gemini directory" -BackupFolder $backupFolder

    # Track .gemini directory in manifest
    if ($geminiInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $globalGeminiDir -Type "Directory"
        # Track files from SOURCE directory
        Get-ChildItem -Path $sourceGeminiDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceGeminiDir.Length)
            $targetPath = $globalGeminiDir + $relativePath
            Add-ManifestEntry -Manifest $manifest -Path $targetPath -Type "File"
        }
    }

    # Backup critical config files in .qwen directory before installation
    Backup-CriticalConfigFiles -TargetDirectory $globalQwenDir -BackupFolder $backupFolder -FileNames @("QWEN.md")

    # Merge .qwen directory (incremental overlay - preserves user files)
    Write-ColorOutput "Installing .qwen directory (incremental merge)..." $ColorInfo
    $qwenInstalled = Merge-DirectoryContents -Source $sourceQwenDir -Destination $globalQwenDir -Description ".qwen directory" -BackupFolder $backupFolder

    # Track .qwen directory in manifest
    if ($qwenInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $globalQwenDir -Type "Directory"
        # Track files from SOURCE directory
        Get-ChildItem -Path $sourceQwenDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceQwenDir.Length)
            $targetPath = $globalQwenDir + $relativePath
            Add-ManifestEntry -Manifest $manifest -Path $targetPath -Type "File"
        }
    }

    # Create version.json in global .claude directory
    Write-ColorOutput "Creating version.json..." $ColorInfo
    Create-VersionJson -TargetClaudeDir $globalClaudeDir -InstallationMode "Global"

    if ($backupFolder -and (Test-Path $backupFolder)) {
        $backupFiles = Get-ChildItem $backupFolder -Recurse -File -ErrorAction SilentlyContinue
        if (-not $backupFiles -or ($backupFiles | Measure-Object).Count -eq 0) {
            # Remove empty backup folder
            Remove-Item -Path $backupFolder -Force
            Write-ColorOutput "Removed empty backup folder" $ColorInfo
        }
    }

    # Save installation manifest
    Save-InstallManifest -Manifest $manifest

    return $true
}

function Install-Path {
    param(
        [string]$TargetDirectory
    )

    Write-ColorOutput "Installing Claude Code Workflow System in hybrid mode..." $ColorInfo
    Write-ColorOutput "Local path: $TargetDirectory" $ColorInfo

    # Determine user profile directory for global files
    $userProfile = [Environment]::GetFolderPath("UserProfile")
    $globalClaudeDir = Join-Path $userProfile ".claude"

    Write-ColorOutput "Global path: $userProfile" $ColorInfo

    # Initialize manifest
    $manifest = New-InstallManifest -InstallationMode "Path" -InstallationPath $TargetDirectory

    # Source paths
    $sourceDir = $PSScriptRoot
    $sourceClaudeDir = Join-Path $sourceDir ".claude"
    $sourceClaudeMd = Join-Path $sourceDir "CLAUDE.md"
    $sourceCodexDir = Join-Path $sourceDir ".codex"
    $sourceGeminiDir = Join-Path $sourceDir ".gemini"
    $sourceQwenDir = Join-Path $sourceDir ".qwen"

    # Local paths - for agents, commands, output-styles, .codex, .gemini, .qwen
    $localClaudeDir = Join-Path $TargetDirectory ".claude"
    $localCodexDir = Join-Path $TargetDirectory ".codex"
    $localGeminiDir = Join-Path $TargetDirectory ".gemini"
    $localQwenDir = Join-Path $TargetDirectory ".qwen"

    # Create backup folder if needed
    $backupFolder = $null
    if (-not $NoBackup) {
        if ((Test-Path $localClaudeDir) -or (Test-Path $localCodexDir) -or (Test-Path $localGeminiDir) -or (Test-Path $localQwenDir) -or (Test-Path $globalClaudeDir)) {
            $backupFolder = Get-BackupDirectory -TargetDirectory $TargetDirectory
            Write-ColorOutput "Backup folder created: $backupFolder" $ColorInfo
        }
    }

    # Create local .claude directory
    if (-not (Test-Path $localClaudeDir)) {
        New-Item -ItemType Directory -Path $localClaudeDir -Force | Out-Null
        Write-ColorOutput "Created local .claude directory" $ColorSuccess
    }

    # Local folders to install (agents, commands, output-styles)
    $localFolders = @("agents", "commands", "output-styles")

    Write-ColorOutput "Installing local components (agents, commands, output-styles)..." $ColorInfo
    foreach ($folder in $localFolders) {
        $sourceFolderPath = Join-Path $sourceClaudeDir $folder
        $destFolderPath = Join-Path $localClaudeDir $folder

        if (Test-Path $sourceFolderPath) {
            # Use incremental merge for local folders (preserves user customizations)
            Write-ColorOutput "Installing local folder: $folder (incremental merge)..." $ColorInfo
            $folderInstalled = Merge-DirectoryContents -Source $sourceFolderPath -Destination $destFolderPath -Description "$folder folder" -BackupFolder $backupFolder
            Write-ColorOutput "Installed local folder: $folder" $ColorSuccess

            # Track local folder in manifest
            if ($folderInstalled) {
                Add-ManifestEntry -Manifest $manifest -Path $destFolderPath -Type "Directory"
                # Track files from SOURCE directory
                Get-ChildItem -Path $sourceFolderPath -Recurse -File | ForEach-Object {
                    $relativePath = $_.FullName.Substring($sourceFolderPath.Length)
                    $targetPath = $destFolderPath + $relativePath
                    Add-ManifestEntry -Manifest $manifest -Path $targetPath -Type "File"
                }
            }
        } else {
            Write-ColorOutput "WARNING: Source folder not found: $folder" $ColorWarning
        }
    }

    # Global components - exclude local folders
    Write-ColorOutput "Installing global components to $globalClaudeDir..." $ColorInfo

    # Get all items from source, excluding local folders
    $sourceItems = Get-ChildItem -Path $sourceClaudeDir -Recurse -File | Where-Object {
        $relativePath = $_.FullName.Substring($sourceClaudeDir.Length + 1)
        $topFolder = $relativePath.Split([System.IO.Path]::DirectorySeparatorChar)[0]
        $topFolder -notin $localFolders
    }

    $mergedCount = 0
    foreach ($item in $sourceItems) {
        $relativePath = $item.FullName.Substring($sourceClaudeDir.Length + 1)
        $destinationPath = Join-Path $globalClaudeDir $relativePath

        # Ensure destination directory exists
        $destinationDir = Split-Path $destinationPath -Parent
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        # Handle file merging
        if (Test-Path $destinationPath) {
            if ($BackupAll -and -not $NoBackup) {
                if ($backupFolder) {
                    Backup-FileToFolder -FilePath $destinationPath -BackupFolder $backupFolder
                }
                Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                $mergedCount++
            } elseif ($NoBackup) {
                if (Confirm-Action "File '$relativePath' already exists in global location. Replace it? (NO BACKUP)" -DefaultYes:$false) {
                    Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                    $mergedCount++
                }
            } elseif (Confirm-Action "File '$relativePath' already exists in global location. Replace it?" -DefaultYes:$false) {
                if ($backupFolder) {
                    Backup-FileToFolder -FilePath $destinationPath -BackupFolder $backupFolder
                }
                Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                $mergedCount++
            }
        } else {
            Copy-Item -Path $item.FullName -Destination $destinationPath -Force
            $mergedCount++
        }
    }

    Write-ColorOutput "Merged $mergedCount files to global location" $ColorSuccess

    # Track global files in manifest
    $globalClaudeFiles = Get-ChildItem -Path $globalClaudeDir -Recurse -File | Where-Object {
        $relativePath = $_.FullName.Substring($globalClaudeDir.Length + 1)
        $topFolder = $relativePath.Split([System.IO.Path]::DirectorySeparatorChar)[0]
        $topFolder -notin $localFolders
    }
    foreach ($file in $globalClaudeFiles) {
        Add-ManifestEntry -Manifest $manifest -Path $file.FullName -Type "File"
    }

    # Handle CLAUDE.md file in global .claude directory
    $globalClaudeMd = Join-Path $globalClaudeDir "CLAUDE.md"
    Write-ColorOutput "Installing CLAUDE.md to global .claude directory..." $ColorInfo
    $claudeMdInstalled = Copy-FileToDestination -Source $sourceClaudeMd -Destination $globalClaudeMd -Description "CLAUDE.md" -BackupFolder $backupFolder

    # Track CLAUDE.md in manifest
    if ($claudeMdInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $globalClaudeMd -Type "File"
    }

    # Backup critical config files in .codex directory before installation
    Backup-CriticalConfigFiles -TargetDirectory $localCodexDir -BackupFolder $backupFolder -FileNames @("AGENTS.md")

    # Merge .codex directory to local location (incremental overlay - preserves user files)
    Write-ColorOutput "Installing .codex directory to local location (incremental merge)..." $ColorInfo
    $codexInstalled = Merge-DirectoryContents -Source $sourceCodexDir -Destination $localCodexDir -Description ".codex directory" -BackupFolder $backupFolder

    # Track .codex directory in manifest
    if ($codexInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $localCodexDir -Type "Directory"
        # Track files from SOURCE directory
        Get-ChildItem -Path $sourceCodexDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceCodexDir.Length)
            $targetPath = $localCodexDir + $relativePath
            Add-ManifestEntry -Manifest $manifest -Path $targetPath -Type "File"
        }
    }

    # Backup critical config files in .gemini directory before installation
    Backup-CriticalConfigFiles -TargetDirectory $localGeminiDir -BackupFolder $backupFolder -FileNames @("GEMINI.md", "CLAUDE.md")

    # Merge .gemini directory to local location (incremental overlay - preserves user files)
    Write-ColorOutput "Installing .gemini directory to local location (incremental merge)..." $ColorInfo
    $geminiInstalled = Merge-DirectoryContents -Source $sourceGeminiDir -Destination $localGeminiDir -Description ".gemini directory" -BackupFolder $backupFolder

    # Track .gemini directory in manifest
    if ($geminiInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $localGeminiDir -Type "Directory"
        # Track files from SOURCE directory
        Get-ChildItem -Path $sourceGeminiDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceGeminiDir.Length)
            $targetPath = $localGeminiDir + $relativePath
            Add-ManifestEntry -Manifest $manifest -Path $targetPath -Type "File"
        }
    }

    # Backup critical config files in .qwen directory before installation
    Backup-CriticalConfigFiles -TargetDirectory $localQwenDir -BackupFolder $backupFolder -FileNames @("QWEN.md")

    # Merge .qwen directory to local location (incremental overlay - preserves user files)
    Write-ColorOutput "Installing .qwen directory to local location (incremental merge)..." $ColorInfo
    $qwenInstalled = Merge-DirectoryContents -Source $sourceQwenDir -Destination $localQwenDir -Description ".qwen directory" -BackupFolder $backupFolder

    # Track .qwen directory in manifest
    if ($qwenInstalled) {
        Add-ManifestEntry -Manifest $manifest -Path $localQwenDir -Type "Directory"
        # Track files from SOURCE directory
        Get-ChildItem -Path $sourceQwenDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceQwenDir.Length)
            $targetPath = $localQwenDir + $relativePath
            Add-ManifestEntry -Manifest $manifest -Path $targetPath -Type "File"
        }
    }

    # Create version.json in local .claude directory
    Write-ColorOutput "Creating version.json in local directory..." $ColorInfo
    Create-VersionJson -TargetClaudeDir $localClaudeDir -InstallationMode "Path"

    # Also create version.json in global .claude directory
    Write-ColorOutput "Creating version.json in global directory..." $ColorInfo
    Create-VersionJson -TargetClaudeDir $globalClaudeDir -InstallationMode "Global"

    if ($backupFolder -and (Test-Path $backupFolder)) {
        $backupFiles = Get-ChildItem $backupFolder -Recurse -File -ErrorAction SilentlyContinue
        if (-not $backupFiles -or ($backupFiles | Measure-Object).Count -eq 0) {
            Remove-Item -Path $backupFolder -Force
            Write-ColorOutput "Removed empty backup folder" $ColorInfo
        }
    }

    # Save installation manifest
    Save-InstallManifest -Manifest $manifest

    return $true
}


function Get-InstallationMode {
    if ($InstallMode) {
        Write-ColorOutput "Installation mode: $InstallMode" $ColorInfo
        return $InstallMode
    }

    $modes = @(
        "Global - Install to user profile (~/.claude/)",
        "Path - Install to custom directory (partial local + global)"
    )

    Write-Host ""
    $selection = Get-UserChoiceWithArrows -Prompt "Choose installation mode:" -Options $modes -DefaultIndex 0

    if ($selection -like "Global*") {
        return "Global"
    } elseif ($selection -like "Path*") {
        return "Path"
    }

    return "Global"
}

function Get-InstallationPath {
    param(
        [string]$Mode
    )

    if ($Mode -eq "Global") {
        return [Environment]::GetFolderPath("UserProfile")
    }

    if ($TargetPath) {
        if (Test-Path $TargetPath) {
            return $TargetPath
        }
        Write-ColorOutput "WARNING: Specified target path does not exist: $TargetPath" $ColorWarning
    }

    # Interactive path selection
    do {
        Write-Host ""
        Write-ColorOutput "Enter the target directory path for installation:" $ColorPrompt
        Write-ColorOutput "(This will install agents, commands, output-styles locally, other files globally)" $ColorInfo
        $path = Read-Host "Path"

        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-ColorOutput "Path cannot be empty" $ColorWarning
            continue
        }

        # Expand environment variables and relative paths
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($path)
        $expandedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($expandedPath)

        if (Test-Path $expandedPath) {
            return $expandedPath
        }

        Write-ColorOutput "Path does not exist: $expandedPath" $ColorWarning
        if (Confirm-Action "Create this directory?" -DefaultYes) {
            try {
                New-Item -ItemType Directory -Path $expandedPath -Force | Out-Null
                Write-ColorOutput "Directory created successfully" $ColorSuccess
                return $expandedPath
            } catch {
                Write-ColorOutput "Failed to create directory: $($_.Exception.Message)" $ColorError
            }
        }
    } while ($true)
}


function Show-Summary {
    param(
        [string]$Mode,
        [string]$Path,
        [bool]$Success
    )

    Write-Host ""
    if ($Success) {
        Write-ColorOutput "Installation completed successfully!" $ColorSuccess
    } else {
        Write-ColorOutput "Installation completed with warnings" $ColorWarning
    }

    Write-ColorOutput "Installation Details:" $ColorInfo
    Write-Host "  Mode: $Mode"

    if ($Mode -eq "Path") {
        Write-Host "  Local Path: $Path"
        Write-Host "  Global Path: $([Environment]::GetFolderPath('UserProfile'))"
        Write-Host "  Local Components: agents, commands, output-styles, .codex, .gemini, .qwen"
        Write-Host "  Global Components: workflows, scripts, python_script, etc."
    } else {
        Write-Host "  Path: $Path"
        Write-Host "  Global Components: .claude, .codex, .gemini, .qwen"
    }

    if ($NoBackup) {
        Write-Host "  Backup: Disabled (no backup created)"
    } elseif ($BackupAll) {
        Write-Host "  Backup: Enabled (automatic backup of all existing files)"
    } else {
        Write-Host "  Backup: Enabled (default behavior)"
    }

    Write-Host ""
    Write-ColorOutput "Next steps:" $ColorInfo
    Write-Host "1. Review CLAUDE.md - Customize guidelines for your project"
    Write-Host "2. Review .codex/Agent.md - Codex agent execution protocol"
    Write-Host "3. Review .gemini/CLAUDE.md - Gemini agent execution protocol"
    Write-Host "4. Review .qwen/QWEN.md - Gemini agent execution protocol"
    Write-Host "5. Configure settings - Edit .claude/settings.local.json as needed"
    Write-Host "6. Install TOON dependencies - Run 'npm install' for workflow utilities"
    Write-Host "7. Test TOON wrapper - Try './scripts/toon-wrapper.sh --help'"
    Write-Host "8. Start using Claude Code with Agent workflow coordination!"
    Write-Host "9. Use /workflow commands for task execution"
    Write-Host "10. Use /update-memory commands for memory system management"

    Write-Host ""
    Write-ColorOutput "TOON Format Info:" $ColorInfo
    Write-Host "  The system uses TOON (Token-Oriented Object Notation) for 30-60% token savings"
    Write-Host "  Legacy JSON files are automatically supported via autoDecode()"
    Write-Host "  See CLAUDE.md for TOON format details and usage examples"
    Write-Host ""
    Write-ColorOutput "Documentation: https://github.com/catlog22/Claude-CCW" $ColorInfo
    Write-ColorOutput "Features: Unified workflow system with comprehensive file output generation" $ColorInfo
}

function Main {
    # Use SourceVersion parameter if provided, otherwise use default
    $installVersion = if ($SourceVersion) { $SourceVersion } else { $DefaultVersion }

    # Show banner first
    Show-Banner

    # Check for uninstall mode from parameter or ask user interactively
    $operationMode = "Install"

    if ($Uninstall) {
        $operationMode = "Uninstall"
    } elseif (-not $NonInteractive -and -not $InstallMode) {
        # Interactive mode selection
        Write-Host ""
        $operations = @(
            "Install - Install Claude Code Workflow System",
            "Uninstall - Remove Claude Code Workflow System"
        )
        $selection = Get-UserChoiceWithArrows -Prompt "Choose operation:" -Options $operations -DefaultIndex 0

        if ($selection -like "Uninstall*") {
            $operationMode = "Uninstall"
        }
    }

    # Handle uninstall mode
    if ($operationMode -eq "Uninstall") {
        $result = Uninstall-ClaudeWorkflow

        if (-not $NonInteractive) {
            Write-Host ""
            Write-ColorOutput "Press any key to exit..." $ColorPrompt
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }

        return $(if ($result) { 0 } else { 1 })
    }

    # Continue with installation
    Show-Header -InstallVersion $installVersion

    # Test prerequisites
    Write-ColorOutput "Checking system requirements..." $ColorInfo
    if (-not (Test-Prerequisites)) {
        Write-ColorOutput "Prerequisites check failed!" $ColorError
        return 1
    }

    try {
        # Get installation mode
        $mode = Get-InstallationMode
        $installPath = ""
        $success = $false

        if ($mode -eq "Global") {
            $installPath = [Environment]::GetFolderPath("UserProfile")
            $result = Install-Global
            $success = $result -eq $true
        }
        elseif ($mode -eq "Path") {
            $installPath = Get-InstallationPath -Mode $mode
            $result = Install-Path -TargetDirectory $installPath
            $success = $result -eq $true
        }

        Show-Summary -Mode $mode -Path $installPath -Success ([bool]$success)

        # Wait for user confirmation before exit in interactive mode
        if (-not $NonInteractive) {
            Write-Host ""
            Write-ColorOutput "Installation completed. Press any key to exit..." $ColorPrompt
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }

        if ($success) {
            return 0
        } else {
            return 1
        }

    } catch {
        Write-ColorOutput "CRITICAL ERROR: $($_.Exception.Message)" $ColorError
        Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" $ColorError

        # Wait for user confirmation before exit in interactive mode
        if (-not $NonInteractive) {
            Write-Host ""
            Write-ColorOutput "An error occurred. Press any key to exit..." $ColorPrompt
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }

        return 1
    }
}

# Run main function
exit (Main)

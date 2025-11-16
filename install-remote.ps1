#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Claude Code Workflow (CCW) - Remote Installation Script

.DESCRIPTION
    One-liner remote installation for Claude Code Workflow system.
    Downloads and installs CCW from GitHub with flexible version selection.

.PARAMETER Version
    Installation version type:
    - "stable" (default): Latest stable release tag
    - "latest": Latest main branch (development version)
    - "branch": Install from specific branch

.PARAMETER Tag
    Specific release tag to install (e.g., "v3.2.0")
    Only used when Version is "stable"

.PARAMETER Branch
    Branch name to install from (default: "main")
    Only used when Version is "branch"

.PARAMETER Global
    Install to global user directory (~/.claude)

.PARAMETER Directory
    Install to custom directory

.PARAMETER Force
    Skip confirmation prompts

.PARAMETER NoBackup
    Skip backup of existing installation

.PARAMETER NonInteractive
    Run in non-interactive mode

.PARAMETER BackupAll
    Backup all files including git-ignored files

.EXAMPLE
    # Install latest stable release (recommended)
    .\install-remote.ps1

.EXAMPLE
    # Install specific stable version
    .\install-remote.ps1 -Version stable -Tag "v3.2.0"

.EXAMPLE
    # Install latest development version
    .\install-remote.ps1 -Version latest

.EXAMPLE
    # Install from specific branch
    .\install-remote.ps1 -Version branch -Branch "feature/new-feature"

.EXAMPLE
    # Install to global directory without prompts
    .\install-remote.ps1 -Global -Force

.LINK
    https://github.com/ding113/Claude-Code-Workflow
#>

[CmdletBinding()]
param(
    [ValidateSet("stable", "latest", "branch")]
    [string]$Version = "stable",

    [string]$Tag = "",

    [string]$Branch = "main",

    [switch]$Global,

    [string]$Directory = "",

    [switch]$Force,

    [switch]$NoBackup,

    [switch]$NonInteractive,

    [switch]$BackupAll
)

# Set encoding for proper Unicode support
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} else {
    # Windows PowerShell 5.1
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
}

# Script metadata
$ScriptName = "Claude Code Workflow (CCW) Remote Installer"
$InstallerVersion = "2.2.0"

# Colors for output
$ColorSuccess = "Green"
$ColorInfo = "Cyan"
$ColorWarning = "Yellow"
$ColorError = "Red"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Header {
    Write-ColorOutput "==== $ScriptName v$InstallerVersion ====" $ColorInfo
    Write-ColorOutput "========================================================" $ColorInfo
    Write-Host ""
}

function Test-Prerequisites {
    # Test PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-ColorOutput "ERROR: PowerShell 5.1 or higher is required" $ColorError
        Write-ColorOutput "Current version: $($PSVersionTable.PSVersion)" $ColorError
        return $false
    }

    # Check for optional but recommended commands
    $gitAvailable = $false
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ Git available" $ColorSuccess
            $gitAvailable = $true
        }
    } catch {
        # Git not found
    }

    if (-not $gitAvailable) {
        Write-ColorOutput "WARNING: 'git' not found - version detection may be limited" $ColorWarning
        Write-ColorOutput "Hint: Install Git for Windows for better version tracking" $ColorInfo
        Write-ColorOutput "      Download from: https://git-scm.com/download/win" $ColorInfo
        Write-Host ""
    }

    # Test internet connectivity
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 10 -UseBasicParsing
        Write-ColorOutput "✓ Network connection OK" $ColorSuccess
    } catch {
        Write-ColorOutput "ERROR: Cannot connect to GitHub" $ColorError
        Write-ColorOutput "Please check your network connection and try again." $ColorError
        Write-Host ""
        Write-ColorOutput "Common causes:" $ColorInfo
        Write-Host "  • Internet connection is down or unstable"
        Write-Host "  • Firewall or proxy is blocking GitHub access"
        Write-Host "  • DNS resolution issues"
        Write-Host "  • GitHub is temporarily unavailable"
        Write-Host ""
        Write-ColorOutput "Troubleshooting steps:" $ColorInfo
        Write-Host "  1. Check your internet connection"
        Write-Host "  2. Try accessing https://github.com in your browser"
        Write-Host "  3. If using a proxy, configure it properly"
        Write-Host "  4. Check firewall settings"
        Write-Host "  5. Wait a few minutes and try again"
        Write-Host ""
        Write-ColorOutput "Error details: $($_.Exception.Message)" $ColorError
        return $false
    }

    return $true
}

function Get-TempDirectory {
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "claude-code-workflow-install"
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    return $tempDir
}

function Get-LatestRelease {
    try {
        $apiUrl = "https://api.github.com/repos/ding113/Claude-Code-Workflow/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -TimeoutSec 10
        return $response.tag_name
    } catch {
        Write-ColorOutput "WARNING: Failed to fetch latest release" $ColorWarning
        Write-ColorOutput "Reason: $($_.Exception.Message)" $ColorWarning
        Write-ColorOutput "Falling back to 'main' branch" $ColorInfo
        return $null
    }
}

function Download-Repository {
    param(
        [string]$TempDir,
        [string]$Version = "stable",
        [string]$Branch = "main",
        [string]$Tag = ""
    )

    $repoUrl = "https://github.com/ding113/Claude-Code-Workflow"

    # Determine download URL based on version type
    if ($Version -eq "stable") {
        # Download latest stable release
        if ([string]::IsNullOrEmpty($Tag)) {
            $latestTag = Get-LatestRelease
            if ($latestTag) {
                $Tag = $latestTag
            } else {
                # Fallback to main branch if API fails
                $zipUrl = "$repoUrl/archive/refs/heads/main.zip"
                $downloadType = "main branch (fallback)"
            }
        }

        if (-not [string]::IsNullOrEmpty($Tag)) {
            $zipUrl = "$repoUrl/archive/refs/tags/$Tag.zip"
            $downloadType = "stable release $Tag"
        }
    } elseif ($Version -eq "latest") {
        # Download latest main branch
        $zipUrl = "$repoUrl/archive/refs/heads/main.zip"
        $downloadType = "latest main branch"
    } else {
        # Download specific branch
        $zipUrl = "$repoUrl/archive/refs/heads/$Branch.zip"
        $downloadType = "branch $Branch"
    }

    $zipPath = Join-Path $TempDir "repo.zip"

    Write-ColorOutput "Downloading from GitHub..." $ColorInfo
    Write-ColorOutput "Source: $repoUrl" $ColorInfo
    Write-ColorOutput "Type: $downloadType" $ColorInfo

    try {
        # Download with progress
        $progressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 300

        $ProgressPreference = $progressPreference

        if (Test-Path $zipPath) {
            $fileSize = (Get-Item $zipPath).Length
            if ($fileSize -eq 0) {
                throw "Downloaded file is empty (0 bytes)"
            }
            Write-ColorOutput "Download complete ($([math]::Round($fileSize/1024/1024, 2)) MB)" $ColorSuccess
            return $zipPath
        } else {
            throw "Downloaded file does not exist"
        }
    } catch {
        Write-Host ""
        Write-ColorOutput "ERROR: Download failed" $ColorError
        Write-Host ""
        Write-ColorOutput "Common causes:" $ColorInfo
        Write-Host "  • Network connection interrupted during download"
        Write-Host "  • GitHub API rate limit exceeded"
        Write-Host "  • Invalid version tag or branch name"
        Write-Host "  • Temporary GitHub service issues"
        Write-Host ""
        Write-ColorOutput "Troubleshooting steps:" $ColorInfo
        Write-Host "  1. Check your internet connection stability"
        Write-Host "  2. Wait a few minutes and try again (rate limit resets)"
        Write-Host "  3. Verify the version tag or branch name is correct"
        Write-Host "  4. Try a different version (stable/latest)"
        Write-Host "  5. Check GitHub status at https://www.githubstatus.com"
        Write-Host ""
        Write-ColorOutput "Download URL: $zipUrl" $ColorInfo
        Write-ColorOutput "Error details: $($_.Exception.Message)" $ColorError
        Write-Host ""
        return $null
    }
}

function Extract-Repository {
    param(
        [string]$ZipPath,
        [string]$TempDir
    )
    
    Write-ColorOutput "Extracting files..." $ColorInfo
    
    try {
        # Verify zip file exists and is not empty
        if (-not (Test-Path $ZipPath)) {
            throw "ZIP file not found: $ZipPath"
        }

        $zipSize = (Get-Item $ZipPath).Length
        if ($zipSize -eq 0) {
            throw "ZIP file is empty (0 bytes)"
        }

        # Use .NET to extract zip
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TempDir)

        # Find the extracted directory (usually repo-name-branch)
        $extractedDirs = Get-ChildItem -Path $TempDir -Directory
        $repoDir = $extractedDirs | Where-Object { $_.Name -like "Claude-Code-Workflow-*" } | Select-Object -First 1

        if ($repoDir) {
            Write-ColorOutput "Extraction complete: $($repoDir.FullName)" $ColorSuccess
            return $repoDir.FullName
        } else {
            throw "Could not find extracted repository directory"
        }
    } catch {
        Write-Host ""
        Write-ColorOutput "ERROR: Extraction failed" $ColorError
        Write-Host ""
        Write-ColorOutput "Common causes:" $ColorInfo
        Write-Host "  • Downloaded file is corrupted or incomplete"
        Write-Host "  • ZIP file format is invalid"
        Write-Host "  • Insufficient disk space"
        Write-Host "  • Permission issues on temporary directory"
        Write-Host ""
        Write-ColorOutput "Troubleshooting steps:" $ColorInfo
        Write-Host "  1. Try downloading again (network may have interrupted)"
        Write-Host "  2. Check available disk space"
        Write-Host "  3. Verify temporary directory permissions"
        Write-Host "  4. Try running as administrator"
        Write-Host ""
        Write-ColorOutput "ZIP file: $ZipPath" $ColorInfo
        if (Test-Path $ZipPath) {
            Write-ColorOutput "ZIP size: $([math]::Round($zipSize/1024/1024, 2)) MB" $ColorInfo
        }
        Write-ColorOutput "Error details: $($_.Exception.Message)" $ColorError
        Write-Host ""
        return $null
    }
}

function Invoke-LocalInstaller {
    param(
        [string]$RepoDir,
        [string]$VersionInfo = "",
        [string]$BranchInfo = "",
        [string]$CommitSha = ""
    )

    $installerPath = Join-Path $RepoDir "Install-Claude.ps1"

    if (-not (Test-Path $installerPath)) {
        Write-ColorOutput "ERROR: Install-Claude.ps1 not found" $ColorError
        return $false
    }

    Write-ColorOutput "Running local installer..." $ColorInfo
    Write-Host ""

    # Build parameters for local installer
    $params = @{}
    if ($Global) { $params["InstallMode"] = "Global" }
    if ($Directory) {
        $params["InstallMode"] = "Custom"
        $params["TargetPath"] = $Directory
    }
    if ($Force) { $params["Force"] = $Force }
    if ($NoBackup) { $params["NoBackup"] = $NoBackup }
    if ($NonInteractive) { $params["NonInteractive"] = $NonInteractive }
    if ($BackupAll) { $params["BackupAll"] = $BackupAll }

    # Pass version, branch, and commit information
    if ($VersionInfo) { $params["SourceVersion"] = $VersionInfo }
    if ($BranchInfo) { $params["SourceBranch"] = $BranchInfo }
    if ($CommitSha) { $params["SourceCommit"] = $CommitSha }

    try {
        # Change to repo directory and run installer
        Push-Location $RepoDir

        if ($params.Count -gt 0) {
            $paramList = ($params.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join " "
            Write-ColorOutput "Executing: & `"$installerPath`" $paramList" $ColorInfo
            & $installerPath @params
        } else {
            Write-ColorOutput "Executing: & `"$installerPath`"" $ColorInfo
            & $installerPath
        }

        Pop-Location
        return $true
    } catch {
        Pop-Location
        Write-ColorOutput "Installation script failed: $($_.Exception.Message)" $ColorError
        return $false
    }
}

function Cleanup-TempFiles {
    param(
        [string]$TempDir
    )
    
    if (Test-Path $TempDir) {
        try {
            Remove-Item -Path $TempDir -Recurse -Force
            Write-ColorOutput "Temporary files cleaned up" $ColorInfo
        } catch {
            Write-ColorOutput "WARNING: Failed to clean temporary files: $($_.Exception.Message)" $ColorWarning
        }
    }
}

function Wait-ForUserConfirmation {
    param(
        [string]$Message = "Press any key to continue...",
        [switch]$ExitAfter
    )
    
    if (-not $NonInteractive) {
        Write-Host ""
        Write-ColorOutput $Message $ColorInfo
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Write-Host ""
    }
    
    if ($ExitAfter) {
        exit 0
    }
}

function Show-VersionMenu {
    param(
        [string]$LatestStableVersion = "Detecting...",
        [string]$LatestStableDate = "",
        [string]$LatestCommitId = "",
        [string]$LatestCommitDate = ""
    )

    Write-Host ""
    Write-ColorOutput "====================================================" $ColorInfo
    Write-ColorOutput "            Version Selection Menu" $ColorInfo
    Write-ColorOutput "====================================================" $ColorInfo
    Write-Host ""

    # Option 1: Latest Stable
    Write-ColorOutput "1) Latest Stable Release (Recommended)" $ColorSuccess
    if ($LatestStableVersion -ne "Detecting..." -and $LatestStableVersion -ne "Unknown") {
        Write-Host "   |-- Version: $LatestStableVersion"
        if ($LatestStableDate) {
            Write-Host "   |-- Released: $LatestStableDate"
        }
        Write-Host "   \-- Production-ready"
    } else {
        Write-Host "   |-- Version: Auto-detected from GitHub"
        Write-Host "   \-- Production-ready"
    }
    Write-Host ""

    # Option 2: Latest Development
    Write-ColorOutput "2) Latest Development Version" $ColorWarning
    Write-Host "   |-- Branch: main"
    if ($LatestCommitId -and $LatestCommitDate) {
        Write-Host "   |-- Commit: $LatestCommitId"
        Write-Host "   |-- Updated: $LatestCommitDate"
    }
    Write-Host "   |-- Cutting-edge features"
    Write-Host "   \-- May contain experimental changes"
    Write-Host ""

    # Option 3: Specific Version
    Write-ColorOutput "3) Specific Release Version" $ColorInfo
    Write-Host "   |-- Install a specific tagged release"
    Write-Host "   \-- Recent: v3.2.0, v3.1.0, v3.0.1"
    Write-Host ""

    Write-ColorOutput "====================================================" $ColorInfo
    Write-Host ""
}

function Get-UserVersionChoice {
    if ($NonInteractive -or $Force) {
        # Non-interactive mode: use default stable version
        return @{
            Type = "stable"
            Tag = $Tag
            Branch = $Branch
        }
    }

    # Detect latest stable version and commit info
    Write-ColorOutput "Detecting latest release and commits..." $ColorInfo
    $latestVersion = "Unknown"
    $latestStableDate = ""
    $latestCommitId = ""
    $latestCommitDate = ""

    try {
        # Get latest release info
        $apiUrl = "https://api.github.com/repos/ding113/Claude-Code-Workflow/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -TimeoutSec 5
        $latestVersion = $response.tag_name

        # Parse and format release date to local time
        if ($response.published_at) {
            $publishDate = [DateTime]::Parse($response.published_at).ToLocalTime()
            $latestStableDate = $publishDate.ToString("yyyy-MM-dd HH:mm")
        }

        Write-ColorOutput "Latest stable: $latestVersion ($latestStableDate)" $ColorSuccess
    } catch {
        Write-ColorOutput "Could not detect latest release" $ColorWarning
    }

    try {
        # Get latest commit info from main branch
        $commitUrl = "https://api.github.com/repos/ding113/Claude-Code-Workflow/commits/main"
        $commitResponse = Invoke-RestMethod -Uri $commitUrl -UseBasicParsing -TimeoutSec 5
        $latestCommitId = $commitResponse.sha.Substring(0, 7)

        # Parse and format commit date to local time
        if ($commitResponse.commit.committer.date) {
            $commitDate = [DateTime]::Parse($commitResponse.commit.committer.date).ToLocalTime()
            $latestCommitDate = $commitDate.ToString("yyyy-MM-dd HH:mm")
        }

        Write-ColorOutput "Latest commit: $latestCommitId ($latestCommitDate)" $ColorSuccess
    } catch {
        Write-ColorOutput "Could not detect latest commit" $ColorWarning
    }

    Show-VersionMenu -LatestStableVersion $latestVersion -LatestStableDate $latestStableDate -LatestCommitId $latestCommitId -LatestCommitDate $latestCommitDate

    $choice = Read-Host "Select version to install (1-3, default: 1)"

    switch ($choice) {
        "2" {
            Write-Host ""
            Write-ColorOutput "✓ Selected: Latest Development Version (main branch)" $ColorSuccess
            return @{
                Type = "latest"
                Tag = ""
                Branch = "main"
            }
        }
        "3" {
            Write-Host ""
            Write-ColorOutput "Available recent releases:" $ColorInfo
            Write-Host "  v3.2.0, v3.1.0, v3.0.1, v3.0.0"
            Write-Host ""
            $tagInput = Read-Host "Enter version tag (e.g., v3.2.0)"

            if ([string]::IsNullOrWhiteSpace($tagInput)) {
                Write-ColorOutput "No tag specified, using latest stable" $ColorWarning
                return @{
                    Type = "stable"
                    Tag = ""
                    Branch = "main"
                }
            }

            Write-ColorOutput "✓ Selected: Specific Version $tagInput" $ColorSuccess
            return @{
                Type = "stable"
                Tag = $tagInput
                Branch = "main"
            }
        }
        default {
            Write-Host ""
            if ($latestVersion -ne "Unknown") {
                Write-ColorOutput "✓ Selected: Latest Stable Release ($latestVersion)" $ColorSuccess
            } else {
                Write-ColorOutput "✓ Selected: Latest Stable Release (auto-detect)" $ColorSuccess
            }
            return @{
                Type = "stable"
                Tag = ""
                Branch = "main"
            }
        }
    }
}

function Main {
    Show-Header

    Write-ColorOutput "This will download and install Claude Code Workflow System from GitHub." $ColorInfo
    Write-Host ""

    # Test prerequisites
    Write-ColorOutput "Checking system requirements..." $ColorInfo
    if (-not (Test-Prerequisites)) {
        Wait-ForUserConfirmation "System check failed! Press any key to exit..." -ExitAfter
    }

    # Get version choice from user (interactive menu)
    $versionChoice = Get-UserVersionChoice
    $script:Version = $versionChoice.Type
    $script:Tag = $versionChoice.Tag
    $script:Branch = $versionChoice.Branch

    # Determine version information for display
    $versionInfo = switch ($Version) {
        "stable" {
            if ($Tag) { "Stable release: $Tag" }
            else { "Latest stable release (auto-detected)" }
        }
        "latest" { "Latest main branch (development)" }
        "branch" { "Custom branch: $Branch" }
    }

    # Confirm installation
    if (-not $NonInteractive -and -not $Force) {
        Write-Host ""
        Write-ColorOutput "INSTALLATION DETAILS:" $ColorInfo
        Write-Host "- Repository: https://github.com/ding113/Claude-Code-Workflow"
        Write-Host "- Version: $versionInfo"
        Write-Host "- Features: Intelligent workflow orchestration with multi-agent coordination"
        Write-Host ""
        Write-ColorOutput "SECURITY NOTE:" $ColorWarning
        Write-Host "- This script will download and execute code from GitHub"
        Write-Host "- Please ensure you trust this source"
        Write-Host ""

        $choice = Read-Host "Continue with installation? (y/N)"
        if ($choice -notmatch '^[Yy]') {
            Write-ColorOutput "Installation cancelled" $ColorWarning
            Wait-ForUserConfirmation -ExitAfter
        }
    }
    
    # Create temp directory
    $tempDir = Get-TempDirectory
    Write-ColorOutput "Temporary directory: $tempDir" $ColorInfo

    try {
        # Download repository
        $zipPath = Download-Repository -TempDir $tempDir -Version $Version -Branch $Branch -Tag $Tag
        if (-not $zipPath) {
            throw "Download failed"
        }

        # Extract repository
        $repoDir = Extract-Repository $zipPath $tempDir
        if (-not $repoDir) {
            throw "Extraction failed"
        }

        # Get commit SHA from the downloaded repository first
        $commitSha = ""
        Write-ColorOutput "Detecting version information..." $ColorInfo

        # Try to get from git repository if git is available
        $gitAvailable = $false
        try {
            $null = git --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                $gitAvailable = $true
            }
        } catch {
            # Git not available
        }

        if ($gitAvailable) {
            try {
                Push-Location $repoDir
                $commitSha = (git rev-parse --short HEAD 2>$null)
                Pop-Location

                if ($commitSha) {
                    Write-ColorOutput "✓ Version detected from git: $commitSha" $ColorSuccess
                }
            } catch {
                Pop-Location
                # Continue to fallback
            }
        }

        # Fallback: try to get from GitHub API
        if (-not $commitSha) {
            try {
                Write-ColorOutput "Fetching version from GitHub API..." $ColorInfo
                $commitUrl = "https://api.github.com/repos/ding113/Claude-Code-Workflow/commits/$Branch"
                $commitResponse = Invoke-RestMethod -Uri $commitUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop

                if ($commitResponse.sha) {
                    $commitSha = $commitResponse.sha.Substring(0, 7)
                    Write-ColorOutput "✓ Version detected from API: $commitSha" $ColorSuccess
                }
            } catch {
                Write-ColorOutput "WARNING: Could not detect version, using 'unknown'" $ColorWarning
                $commitSha = "unknown"
            }
        }

        if (-not $commitSha) {
            $commitSha = "unknown"
        }

        # Determine version and branch information to pass
        $versionToPass = ""

        if ($Tag) {
            # Specific tag version
            $versionToPass = $Tag -replace '^v', ''  # Remove 'v' prefix
        } elseif ($Version -eq "stable") {
            # Auto-detected latest stable
            $latestTag = Get-LatestRelease
            if ($latestTag) {
                $versionToPass = $latestTag -replace '^v', ''
            } else {
                # Fallback: use commit SHA as version
                $versionToPass = "dev-$commitSha"
            }
        } else {
            # Latest development or branch - use commit SHA as version
            $versionToPass = "dev-$commitSha"
        }

        $branchToPass = if ($Version -eq "branch") { $Branch } elseif ($Version -eq "latest") { "main" } elseif ($Tag) { $Tag } else { "main" }

        Write-ColorOutput "Version info: $versionToPass (branch: $branchToPass, commit: $commitSha)" $ColorInfo

        # Run local installer with version information
        $success = Invoke-LocalInstaller -RepoDir $repoDir -VersionInfo $versionToPass -BranchInfo $branchToPass -CommitSha $commitSha
        if (-not $success) {
            throw "Installation script failed"
        }

        Write-Host ""
        Write-ColorOutput "Remote installation completed successfully!" $ColorSuccess
        
    } catch {
        Write-Host ""
        Write-ColorOutput "Remote installation failed: $($_.Exception.Message)" $ColorError
        Wait-ForUserConfirmation "Installation failed! Press any key to exit..." -ExitAfter
    } finally {
        # Cleanup
        Cleanup-TempFiles $tempDir
    }
    
    Write-Host ""
    Write-ColorOutput "Next steps:" $ColorInfo
    Write-Host "1. Review CLAUDE.md for project-specific guidelines"
    Write-Host "2. Try /workflow commands for Agent coordination"
    Write-Host "3. Use /update-memory to manage distributed documentation"
    
    Wait-ForUserConfirmation "Remote installation done! Press any key to exit..." -ExitAfter
}

# Run main function
try {
    Main
} catch {
    Write-ColorOutput "CRITICAL ERROR: $($_.Exception.Message)" $ColorError
    Write-Host ""
    Wait-ForUserConfirmation "A critical error occurred! Press any key to exit..." -ExitAfter
}
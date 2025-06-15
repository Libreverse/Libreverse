# PowerShell script to install Perl on Windows
# This script installs Strawberry Perl, which includes Perl interpreter and common modules

param(
    [string]$Version = "5.38.2.2",
    [string]$Architecture = "64bit",
    [switch]$Force,
    [switch]$Quiet
)

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Function to download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        return $true
    }
    catch {
        Write-ColorOutput "Error downloading file: $_" "Red"
        return $false
    }
}

# Main installation function
function Install-Perl {
    Write-ColorOutput "=== Perl Installation Script ===" "Cyan"
    Write-ColorOutput "Version: $Version" "Yellow"
    Write-ColorOutput "Architecture: $Architecture" "Yellow"
    
    # Check if Perl is already installed
    $existingPerl = Get-Command perl -ErrorAction SilentlyContinue
    if ($existingPerl -and -not $Force) {
        Write-ColorOutput "Perl is already installed at: $($existingPerl.Source)" "Green"
        Write-ColorOutput "Use -Force parameter to reinstall" "Yellow"
        return
    }
    
    # Determine download URL based on architecture
    $baseUrl = "https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download"
    switch ($Architecture.ToLower()) {
        "64bit" { $filename = "strawberry-perl-$Version-64bit.msi" }
        "32bit" { $filename = "strawberry-perl-$Version-32bit.msi" }
        default {
            Write-ColorOutput "Unsupported architecture: $Architecture" "Red"
            throw "Unsupported architecture: $Architecture. Only '64bit' and '32bit' are supported."
        }
    }
    
    $downloadUrl = "$baseUrl/SP_$($Version.Replace('.', '_'))/$filename"
    $tempPath = "$env:TEMP\$filename"
    
    Write-ColorOutput "Downloading Strawberry Perl from: $downloadUrl" "Yellow"
    
    # Download the installer
    if (-not (Download-File -Url $downloadUrl -OutputPath $tempPath)) {
        Write-ColorOutput "Failed to download Perl installer" "Red"
        return
    }
    
    Write-ColorOutput "Download completed: $tempPath" "Green"
    
    # Install Perl
    Write-ColorOutput "Installing Perl..." "Yellow"
    
    $installArgs = @(
        "/i", $tempPath,
        "/quiet",
        "/norestart"
    )
    
    if (-not $Quiet) {
        $installArgs = $installArgs | Where-Object { $_ -ne "/quiet" }
    }
    
    try {
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru
        
        if ($process.ExitCode -in 0, 3010) {
            Write-ColorOutput "Perl installation completed successfully!" "Green"
        } else {
            Write-ColorOutput "Installation failed with exit code: $($process.ExitCode)" "Red"
            return
        }
    }
    catch {
        Write-ColorOutput "Error during installation: $_" "Red"
        return
    }
    
    # Clean up downloaded file
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force
        Write-ColorOutput "Cleaned up temporary files" "Green"
    }
    
    # Update PATH environment variable for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Verify installation
    Write-ColorOutput "Verifying installation..." "Yellow"
    
    # Wait a moment for the installation to complete
    Start-Sleep -Seconds 3
    
    $perlPath = Get-Command perl -ErrorAction SilentlyContinue
    if ($perlPath) {
        $perlVersion = & perl --version 2>$null | Select-String "This is perl" | ForEach-Object { $_.ToString() }
        Write-ColorOutput "✓ Perl installed successfully!" "Green"
        Write-ColorOutput "  Location: $($perlPath.Source)" "White"
        Write-ColorOutput "  Version: $perlVersion" "White"
        
        # Test CPAN
        Write-ColorOutput "Testing CPAN availability..." "Yellow"
        $cpanTest = & perl -MCPAN -e "print 'CPAN is available'" 2>$null
        if ($cpanTest -eq "CPAN is available") {
            Write-ColorOutput "✓ CPAN is available" "Green"
        }
        
    } else {
        Write-ColorOutput "⚠ Perl installation completed but perl command not found in PATH" "Red"
        Write-ColorOutput "You may need to restart your terminal or computer" "Yellow"
    }
}

# Check prerequisites
if (-not (Test-Administrator)) {
    Write-ColorOutput "⚠ Warning: Not running as Administrator. Installation may fail." "Yellow"
    Write-ColorOutput "Consider running this script as Administrator for best results." "Yellow"
}

# Check internet connectivity
try {
    $null = Test-NetConnection -ComputerName "github.com" -Port 443 -InformationLevel Quiet -ErrorAction Stop
}
catch {
    Write-ColorOutput "Error: No internet connection detected" "Red"
    Write-ColorOutput "Internet access is required to download Perl installer" "Yellow"
    exit 1
}

# Start installation
Install-Perl

Write-ColorOutput "`n=== Installation Complete ===" "Cyan"
Write-ColorOutput "You may need to restart your terminal to use perl command" "Yellow"
Write-ColorOutput "To verify installation, run: perl --version" "White"

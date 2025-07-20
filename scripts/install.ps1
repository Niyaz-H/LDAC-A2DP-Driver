# LDAC A2DP Driver Installation Script
# Copyright (c) 2024 LDAC Driver Team
# Licensed under MIT License

param(
    [switch]$Uninstall = $false,
    [switch]$Force = $false,
    [switch]$TestMode = $false
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Paths
$RootDir = Split-Path -Parent $PSScriptRoot
$DriverDir = Join-Path $RootDir "build\Release\driver"
$ServiceDir = Join-Path $RootDir "build\Release\service"
$GUIDir = Join-Path $RootDir "build\Release\gui"

# Registry paths
$DriverRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LDACA2DP"
$ServiceRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LDACA2DPService"

function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Create-SystemRestorePoint {
    Write-Header "Creating System Restore Point"
    
    try {
        Checkpoint-Computer -Description "LDAC Driver Installation" -RestorePointType "MODIFY_SETTINGS"
        Write-Host "System restore point created successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to create system restore point: $_"
    }
}

function Install-Driver {
    Write-Header "Installing LDAC Driver"
    
    $DriverPath = Join-Path $DriverDir "LDACA2DP.inf"
    
    if (!(Test-Path $DriverPath)) {
        Write-Error "Driver file not found: $DriverPath"
        return $false
    }
    
    try {
        # Install driver using pnputil
        $result = pnputil /add-driver $DriverPath /install
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Driver installation failed"
            return $false
        }
        
        Write-Host "Driver installed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Driver installation error: $_"
        return $false
    }
}

function Install-Service {
    Write-Header "Installing Windows Service"
    
    $ServicePath = Join-Path $ServiceDir "LDACService.exe"
    
    if (!(Test-Path $ServicePath)) {
        Write-Error "Service executable not found: $ServicePath"
        return $false
    }
    
    try {
        # Install service
        New-Service -Name "LDACA2DPService" `
                   -DisplayName "LDAC A2DP Audio Service" `
                   -Description "Provides LDAC codec support for Bluetooth A2DP devices" `
                   -BinaryPathName $ServicePath `
                   -StartupType Automatic
        
        # Start service
        Start-Service -Name "LDACA2DPService"
        
        Write-Host "Service installed and started successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Service installation error: $_"
        return $false
    }
}

function Install-GUI {
    Write-Header "Installing Configuration GUI"
    
    $GUIPath = Join-Path $GUIDir "LDACConfigApp.exe"
    
    if (!(Test-Path $GUIPath)) {
        Write-Error "GUI executable not found: $GUIPath"
        return $false
    }
    
    try {
        # Create start menu shortcut
        $StartMenuPath = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\LDAC Driver"
        New-Item -ItemType Directory -Path $StartMenuPath -Force | Out-Null
        
        $ShortcutPath = Join-Path $StartMenuPath "LDAC Configuration.lnk"
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $GUIPath
        $Shortcut.WorkingDirectory = $GUIDir
        $Shortcut.Save()
        
        Write-Host "GUI installed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "GUI installation error: $_"
        return $false
    }
}

function Configure-Registry {
    Write-Header "Configuring Registry Settings"
    
    try {
        # Create registry keys
        New-Item -Path $DriverRegPath -Force | Out-Null
        New-Item -Path "$DriverRegPath\Parameters" -Force | Out-Null
        
        # Set default values
        Set-ItemProperty -Path "$DriverRegPath\Parameters" -Name "PreferredBitrate" -Value 990000
        Set-ItemProperty -Path "$DriverRegPath\Parameters" -Name "EnableAdaptive" -Value 1
        Set-ItemProperty -Path "$DriverRegPath\Parameters" -Name "FallbackChain" -Value "LDAC,aptXHD,aptX,AAC,SBC"
        
        # Create user configuration directory
        $UserConfigPath = Join-Path $env:APPDATA "LDACDriver"
        New-Item -ItemType Directory -Path $UserConfigPath -Force | Out-Null
        
        Write-Host "Registry configured successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Registry configuration error: $_"
        return $false
    }
}

function Test-Installation {
    Write-Header "Testing Installation"
    
    try {
        # Check driver
        $Driver = Get-WmiObject Win32_SystemDriver | Where-Object { $_.Name -eq "LDACA2DP" }
        if (!$Driver) {
            Write-Error "Driver not found"
            return $false
        }
        
        # Check service
        $Service = Get-Service -Name "LDACA2DPService" -ErrorAction SilentlyContinue
        if (!$Service) {
            Write-Error "Service not found"
            return $false
        }
        
        # Check service status
        if ($Service.Status -ne "Running") {
            Write-Warning "Service is not running"
        }
        
        Write-Host "Installation test passed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Installation test error: $_"
        return $false
    }
}

function Uninstall-Driver {
    Write-Header "Uninstalling LDAC Driver"
    
    try {
        # Stop and remove service
        $Service = Get-Service -Name "LDACA2DPService" -ErrorAction SilentlyContinue
        if ($Service) {
            if ($Service.Status -eq "Running") {
                Stop-Service -Name "LDACA2DPService" -Force
            }
            sc.exe delete "LDACA2DPService"
        }
        
        # Remove driver
        pnputil /delete-driver LDACA2DP.inf /uninstall /force
        
        # Remove registry keys
        Remove-Item -Path $DriverRegPath -Recurse -Force -ErrorAction SilentlyContinue
        
        # Remove shortcuts
        $StartMenuPath = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\LDAC Driver"
        Remove-Item -Path $StartMenuPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "Driver uninstalled successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Uninstallation error: $_"
        return $false
    }
}

function Enable-TestMode {
    Write-Header "Enabling Test Mode"
    
    try {
        bcdedit /set testsigning on
        Write-Host "Test mode enabled - restart required" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Error "Failed to enable test mode: $_"
        return $false
    }
}

function Disable-TestMode {
    Write-Header "Disabling Test Mode"
    
    try {
        bcdedit /set testsigning off
        Write-Host "Test mode disabled - restart required" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Error "Failed to disable test mode: $_"
        return $false
    }
}

# Main execution
Write-Host "LDAC A2DP Driver Installation Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check administrator rights
if (!(Test-Administrator)) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

if ($Uninstall) {
    Write-Host "Starting uninstallation..." -ForegroundColor Yellow
    
    if (!$Force) {
        $confirm = Read-Host "Are you sure you want to uninstall the LDAC driver? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "Uninstallation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    
    Uninstall-Driver
    exit 0
}

if ($TestMode) {
    Enable-TestMode
    exit 0
}

Write-Host "Starting installation..." -ForegroundColor Green

# Create restore point
Create-SystemRestorePoint

# Install components
$success = $true

$success = $success -and (Install-Driver)
$success
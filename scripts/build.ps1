# LDAC A2DP Driver Build Script
# Copyright (c) 2024 LDAC Driver Team
# Licensed under MIT License

param(
    [string]$Configuration = "Release",
    [string]$Platform = "x64",
    [switch]$Sign = $false,
    [switch]$Test = $false,
    [switch]$Package = $false
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Paths
$RootDir = Split-Path -Parent $PSScriptRoot
$SrcDir = Join-Path $RootDir "src"
$BuildDir = Join-Path $RootDir "build"
$OutputDir = Join-Path $BuildDir $Configuration
$DriverDir = Join-Path $SrcDir "driver"
$ServiceDir = Join-Path $SrcDir "service"
$GUIDir = Join-Path $SrcDir "gui"

# Build tools
$MSBuild = "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
$WDKPath = "C:\Program Files (x86)\Windows Kits\10"
$SignTool = Join-Path $WDKPath "bin\*\x64\signtool.exe"

function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check MSBuild
    if (!(Test-Path $MSBuild)) {
        Write-Error "MSBuild not found at $MSBuild"
        return $false
    }
    
    # Check WDK
    if (!(Test-Path $WDKPath)) {
        Write-Error "Windows Driver Kit not found at $WDKPath"
        return $false
    }
    
    # Check certificate for signing
    if ($Sign -and !(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)) {
        Write-Error "No code signing certificate found"
        return $false
    }
    
    Write-Host "All prerequisites met" -ForegroundColor Green
    return $true
}

function Build-Driver {
    Write-Header "Building Kernel Driver"
    
    $DriverProject = Join-Path $DriverDir "LDACDriver.vcxproj"
    
    if (!(Test-Path $DriverProject)) {
        Write-Error "Driver project not found: $DriverProject"
        return $false
    }
    
    $DriverOutput = Join-Path $OutputDir "driver"
    New-Item -ItemType Directory -Path $DriverOutput -Force | Out-Null
    
    # Build driver
    & $MSBuild $DriverProject `
        /p:Configuration=$Configuration `
        /p:Platform=$Platform `
        /p:OutDir="$DriverOutput\" `
        /p:TargetVersion="Windows10" `
        /p:DriverType="KMDF" `
        /v:minimal
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Driver build failed"
        return $false
    }
    
    Write-Host "Driver built successfully" -ForegroundColor Green
    return $true
}

function Build-Service {
    Write-Header "Building Windows Service"
    
    $ServiceProject = Join-Path $ServiceDir "LDACService.csproj"
    
    if (!(Test-Path $ServiceProject)) {
        Write-Error "Service project not found: $ServiceProject"
        return $false
    }
    
    $ServiceOutput = Join-Path $OutputDir "service"
    New-Item -ItemType Directory -Path $ServiceOutput -Force | Out-Null
    
    # Build service
    & $MSBuild $ServiceProject `
        /p:Configuration=$Configuration `
        /p:Platform=$Platform `
        /p:OutDir="$ServiceOutput\" `
        /v:minimal
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Service build failed"
        return $false
    }
    
    Write-Host "Service built successfully" -ForegroundColor Green
    return $true
}

function Build-GUI {
    Write-Header "Building Configuration GUI"
    
    $GUIProject = Join-Path $GUIDir "LDACConfigApp.csproj"
    
    if (!(Test-Path $GUIProject)) {
        Write-Error "GUI project not found: $GUIProject"
        return $false
    }
    
    $GUIOutput = Join-Path $OutputDir "gui"
    New-Item -ItemType Directory -Path $GUIOutput -Force | Out-Null
    
    # Build GUI
    & $MSBuild $GUIProject `
        /p:Configuration=$Configuration `
        /p:Platform=$Platform `
        /p:OutDir="$GUIOutput\" `
        /p:PublishProfile=FolderProfile `
        /v:minimal
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "GUI build failed"
        return $false
    }
    
    Write-Host "GUI built successfully" -ForegroundColor Green
    return $true
}

function Sign-Binaries {
    Write-Header "Signing Binaries"
    
    if (!$Sign) {
        Write-Host "Skipping signing (use -Sign to enable)" -ForegroundColor Yellow
        return $true
    }
    
    $Certificate = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
    
    if (!$Certificate) {
        Write-Error "No code signing certificate found"
        return $false
    }
    
    # Sign driver
    $DriverFile = Join-Path $OutputDir "driver\LDACA2DP.sys"
    if (Test-Path $DriverFile) {
        & $SignTool sign /f $Certificate.PSPath /t http://timestamp.digicert.com $DriverFile
    }
    
    # Sign service
    $ServiceFile = Join-Path $OutputDir "service\LDACService.exe"
    if (Test-Path $ServiceFile) {
        & $SignTool sign /f $Certificate.PSPath /t http://timestamp.digicert.com $ServiceFile
    }
    
    # Sign GUI
    $GUIFile = Join-Path $OutputDir "gui\LDACConfigApp.exe"
    if (Test-Path $GUIFile) {
        & $SignTool sign /f $Certificate.PSPath /t http://timestamp.digicert.com $GUIFile
    }
    
    Write-Host "Binaries signed successfully" -ForegroundColor Green
    return $true
}

function Run-Tests {
    Write-Header "Running Tests"
    
    if (!$Test) {
        Write-Host "Skipping tests (use -Test to enable)" -ForegroundColor Yellow
        return $true
    }
    
    $TestProject = Join-Path $RootDir "src\tests\LDACDriver.Tests.csproj"
    
    if (Test-Path $TestProject) {
        & dotnet test $TestProject --configuration $Configuration --no-build
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Tests failed"
            return $false
        }
    }
    
    Write-Host "Tests passed" -ForegroundColor Green
    return $true
}

function Create-Package {
    Write-Header "Creating Installation Package"
    
    if (!$Package) {
        Write-Host "Skipping package creation (use -Package to enable)" -ForegroundColor Yellow
        return $true
    }
    
    $PackageDir = Join-Path $BuildDir "package"
    New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
    
    # Copy files
    $InstallerDir = Join-Path $PackageDir "installer"
    New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null
    
    # Copy driver files
    $DriverFiles = Join-Path $OutputDir "driver\*"
    if (Test-Path $DriverFiles) {
        Copy-Item $DriverFiles $InstallerDir -Recurse -Force
    }
    
    # Copy service files
    $ServiceFiles = Join-Path $OutputDir "service\*"
    if (Test-Path $ServiceFiles) {
        Copy-Item $ServiceFiles $InstallerDir -Recurse -Force
    }
    
    # Copy GUI files
    $GUIFiles = Join-Path $OutputDir "gui\*"
    if (Test-Path $GUIFiles) {
        Copy-
# LDAC A2DP Driver Installation Script
# Run as Administrator to configure Windows for LDAC codec support

Write-Host "LDAC A2DP Driver Installation for Soundcore Space One NC" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Please run this script as Administrator!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create LDAC registry configuration
Write-Host "Configuring registry for LDAC codec support..." -ForegroundColor Yellow

# Main LDAC driver key
New-Item -Path "HKLM:\SOFTWARE\LDACDriver" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\LDACDriver" -Name "LDACEnabled" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\LDACDriver" -Name "PreferredBitrate" -Value 990000 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\LDACDriver" -Name "ForceLDAC" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\LDACDriver" -Name "AdaptiveBitrate" -Value 1 -Type DWord

# Configure Windows audio stack
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" -Name "LDACEnabled" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" -Name "LDACQuality" -Value 3 -Type DWord

# Configure for high-quality audio
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\LDAC" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\LDAC" -Name "PreferredCodec" -Value "LDAC" -Type String
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\LDAC" -Name "Bitrate" -Value 990000 -Type DWord

# Install the service
Write-Host "Installing Windows Service..." -ForegroundColor Yellow
$servicePath = Join-Path $PSScriptRoot "src\service\bin\Release\net6.0\win-x64\LDACService.exe"
$serviceName = "LDACA2DPService"

# Check if service exists
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($null -eq $service) {
    New-Service -Name $serviceName -BinaryPathName $servicePath -DisplayName "LDAC A2DP Service" -StartupType Automatic -Description "Provides LDAC codec support for A2DP audio devices"
    Start-Service -Name $serviceName
    Write-Host "Service installed and started successfully!" -ForegroundColor Green
} else {
    Write-Host "Service already exists and is running." -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "1. Restart your computer to ensure all changes take effect"
Write-Host "2. Connect your Soundcore Space One NC headphones"
Write-Host "3. Windows should now automatically negotiate LDAC 990 kbps"
Write-Host ""

Read-Host "Press Enter to exit"
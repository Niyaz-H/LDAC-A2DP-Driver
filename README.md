# Windows LDAC A2DP Driver

This project provides a working solution to enable the LDAC codec for Bluetooth headphones on Windows, specifically demonstrated for the Soundcore Space One NC but adaptable for other devices.

## ❗ Prerequisites

Before you begin, ensure you have the following installed:

1.  **Visual Studio:** Required for building the driver and GUI. Make sure to install the "Desktop development with C++" and ".NET desktop development" workloads.
2.  **Windows Driver Kit (WDK):** Required for building the kernel-mode driver.
3.  **Git:** For version control and cloning the repository.
4.  **.NET 6.0 SDK:** Required for building the WPF GUI application.

## ⚙️ Installation and Configuration Guide

Follow these steps carefully to build, install, and configure the LDAC driver.

### Step 1: Build the Solution

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Niyaz-H/LDAC-A2DP-Driver.git
    cd LDAC-A2DP-Driver
    ```
2.  **Open the solution file (`LDACDriver.sln`)** in Visual Studio.
3.  **Build the entire solution in "Release" mode.** This will compile:
    *   The kernel driver (`LDACDriver.sys`)
    *   The background service (`LDACService.exe`)
    *   The configuration GUI (`LDACConfigApp.exe`)

Alternatively, you can run the provided build script from a PowerShell terminal:
```powershell
.\scripts\build.ps1
```

### Step 2: Install the Driver and Service

The installation process involves setting up the kernel driver and the background service that manages it.

1.  **Run the installation script as Administrator:**
    *   Open PowerShell as Administrator.
    *   Navigate to the project directory.
    *   Execute the installation script:
        ```powershell
        .\scripts\install.ps1
        ```
2.  **This script will:**
    *   Copy the driver files (`.sys`, `.inf`) to the correct system directory.
    *   Install the driver service.
    *   Install and start the `LDACService` background service.

### Step 3: Configure LDAC via Registry

The core of this solution is the registry configuration, which forces Windows to use the LDAC codec at the highest quality.

1.  **Run the registry script as Administrator:**
    *   Right-click `enable-ldac-990.bat` and select "Run as administrator".
2.  **This script adds the following keys to the registry:**
    ```
    HKEY_LOCAL_MACHINE\SOFTWARE\LDACDriver
    ├── LDACEnabled: 1 (DWORD)
    ├── PreferredBitrate: 990000 (DWORD)
    ├── ForceLDAC: 1 (DWORD)
    └── AdaptiveBitrate: 1 (DWORD)
    ```

### Step 4: Verify the Installation

1.  **Check the Registry:**
    *   Open Registry Editor (`regedit`).
    *   Navigate to `HKEY_LOCAL_MACHINE\SOFTWARE\LDACDriver`.
    *   Verify that the values from Step 3 are present.
2.  **Use the GUI:**
    *   Run the configuration application: `src\gui\bin\Release\net6.0-windows\win-x64\LDACConfigApp.exe`.
    *   The GUI should reflect the current registry settings.
3.  **Restart your PC and reconnect your headphones** to ensure the changes take effect.

## 🎧 Using with Other Headphones

This solution can be adapted for other LDAC-enabled headphones. The key is to identify your device's hardware ID and potentially adjust the driver's INF file if needed.

1.  **Find your Device's Hardware ID:**
    *   Open Device Manager.
    *   Find your Bluetooth headphones under "Sound, video and game controllers".
    *   Go to `Properties > Details > Hardware Ids`.
2.  **Update the INF file (`src/driver/LDACDriver.inf`):**
    *   Replace the existing hardware ID with your device's ID before building and installing the driver.
3.  The registry configuration in `enable-ldac-990.bat` is generic and should work for any device once the driver is correctly associated with it.

---

This completes the setup. Your LDAC-enabled headphones should now be using the high-bitrate codec on Windows.
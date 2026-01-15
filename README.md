# GlassPorts

**AOSP ported to Google Glass Explorer Edition (Rev 1)**

GlassPorts brings modern Android (versions 4.4 - 9.0) to the Google Glass wearable device with a minimal, optimized system that includes only a launcher and settings menu.

## Features

- **Multi-version Support**: Build scripts for Android 4.4 (KitKat) through Android 9.0 (Pie)
- **Cross-platform Build**: Works on both Windows (via WSL2/Cygwin) and Linux
- **One-click Builds**: Automated build scripts for each major AOSP revision
- **Minimal System**: Only essential components - launcher and settings
- **WiFi Access Point Mode**: Turn your Glass into a WiFi hotspot
- **Sideloading Enabled**: ADB enabled by default for easy app installation
- **Custom Launcher**: Gesture-based launcher optimized for Glass display
- **Custom Settings**: Settings app with WiFi AP toggle and essential controls

## Hardware Specifications

Google Glass Explorer Edition (Rev 1):
- **SoC**: Texas Instruments OMAP4430 (dual-core ARM Cortex-A9 @ 1.0 GHz)
- **GPU**: PowerVR SGX540
- **RAM**: 1GB LPDDR2
- **Storage**: 16GB eMMC
- **Display**: LCoS 640x360 prism display
- **WiFi**: 802.11 b/g (TI WL1271)
- **Bluetooth**: 4.0 + BLE
- **Camera**: 5MP stills / 720p video
- **Battery**: 570 mAh

## Project Structure

```
GlassPorts/
├── build/                      # Build scripts and manifests
│   ├── envsetup.sh            # Linux build environment
│   ├── envsetup.bat           # Windows build environment
│   └── manifests/             # AOSP local manifests
├── device/google/glass/        # Device configuration
│   ├── Android*.mk            # Product definitions
│   ├── BoardConfig.mk         # Board configuration
│   ├── device.mk              # Device settings
│   ├── init/                  # Init scripts
│   ├── overlay/               # Framework overlays
│   └── sepolicy/              # SELinux policies
├── kernel/omap/               # Kernel source
│   └── arch/arm/configs/      # Kernel defconfig
├── packages/                   # Custom apps
│   ├── apps/GlassLauncher/    # Minimal launcher
│   ├── apps/GlassSettings/    # Settings with WiFi AP
│   └── services/GlassWifiApService/  # WiFi AP service
└── vendor/google/glass/        # Proprietary blobs
    ├── extract-files.sh       # Blob extractor
    └── proprietary/           # Binary blobs (not included)
```

## Prerequisites

### Linux
```bash
# Ubuntu/Debian
sudo apt-get install git-core gnupg flex bison build-essential zip curl \
    zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 libncurses5 \
    lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev \
    libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig \
    python3 openjdk-11-jdk repo
```

### Windows
1. Install [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) with Ubuntu
2. Or install [Cygwin](https://cygwin.com/) with development packages
3. Install Git for Windows

## Quick Start

### Linux

```bash
# 1. Clone the repository
git clone https://github.com/sp00nznet/GlassPorts.git
cd GlassPorts

# 2. Source the build environment
source build/envsetup.sh

# 3. Check dependencies
check_dependencies

# 4. Select AOSP version
select_aosp_version  # Choose 1-9 for Android version

# 5. Initialize and sync AOSP
init_aosp
sync_aosp 8  # Use 8 parallel jobs (adjust for your CPU)

# 6. Setup device tree
setup_device

# 7. Build the ROM
build_rom

# 8. Package for flashing
package_rom
```

### Windows

```cmd
# 1. Clone the repository
git clone https://github.com/sp00nznet/GlassPorts.git
cd GlassPorts

# 2. Run the build script
build\envsetup.bat

# 3. Follow the on-screen menu
# Select options 1-8 for the build process
# Or select 9 for a full automated build
```

## Available AOSP Versions

| Option | Android Version | API Level | Status |
|--------|----------------|-----------|--------|
| 1 | Android 9.0 (Pie) | 28 | Supported |
| 2 | Android 8.1 (Oreo MR1) | 27 | Supported |
| 3 | Android 8.0 (Oreo) | 26 | Supported |
| 4 | Android 7.1 (Nougat) | 25 | Supported |
| 5 | Android 7.0 (Nougat) | 24 | Supported |
| 6 | Android 6.0 (Marshmallow) | 23 | Supported |
| 7 | Android 5.1 (Lollipop) | 22 | Supported |
| 8 | Android 5.0 (Lollipop) | 21 | Supported |
| 9 | Android 4.4 (KitKat) | 19 | Supported (Original Glass base) |

## Proprietary Files

Due to licensing restrictions, proprietary binary blobs are not included. You must extract them from an original Google Glass device:

```bash
# Connect your Glass via USB with ADB enabled
cd vendor/google/glass
./extract-files.sh -d
```

See `vendor/google/glass/proprietary/README.md` for the complete file list.

## Flashing

1. Enable USB debugging on your Glass (if not already enabled)
2. Boot into fastboot mode: `adb reboot bootloader`
3. Flash the images:
```bash
cd out/
fastboot flash boot boot.img
fastboot flash system system.img
fastboot flash recovery recovery.img
fastboot flash userdata userdata.img
fastboot reboot
```

Or use the packaged ZIP with custom recovery:
```bash
adb sideload GlassPorts_android-9.0.0_*.zip
```

## WiFi Access Point Mode

GlassPorts includes a WiFi hotspot feature that allows Glass to share its connection:

1. Open **Settings** from the launcher (swipe right)
2. Select **WiFi Hotspot**
3. Toggle the switch to enable
4. Configure SSID and password as needed

Default credentials:
- **SSID**: GlassPorts
- **Password**: glassports

## Sideloading Apps

Sideloading is enabled by default. Simply connect via USB and use:

```bash
adb install your_app.apk
```

Developer options are also enabled by default for easy debugging.

## Build Products

| Product | Description |
|---------|-------------|
| `aosp_glass-userdebug` | Full build with debugging |
| `aosp_glass-eng` | Engineering build |
| `aosp_glass_mini-userdebug` | Minimal build |

## Included Apps

### GlassLauncher
- Minimal home screen with time/date display
- Gesture-based navigation
- Swipe right for Settings
- Swipe left/tap for App list
- Camera button launches camera

### GlassSettings
- WiFi connectivity
- **WiFi Hotspot** with toggle
- Bluetooth settings
- Display brightness
- Developer options (ADB)
- About device

## Known Limitations

- No telephony support (Glass has no cellular radio)
- No NFC support
- Single-touch only (Glass touchpad)
- Limited display resolution (640x360)
- Battery life may vary depending on usage

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is released under the Apache 2.0 license, the same license as AOSP.

Proprietary binary blobs are subject to their respective licenses from Google, Texas Instruments, and Imagination Technologies.

## Acknowledgments

- Google for the original Glass hardware
- Texas Instruments for OMAP4 SoC
- The Android Open Source Project
- The custom ROM community

## Disclaimer

This project is not affiliated with or endorsed by Google. Use at your own risk. Modifying your device may void its warranty and could potentially brick your device.

---

**GlassPorts** - Bringing modern Android to Google Glass

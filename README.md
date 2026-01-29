# GlassPorts

**AOSP ported to Google Glass Explorer Edition (Rev 1)**

GlassPorts aims to bring modern Android to the original Google Glass wearable device with a minimal system including only a launcher and settings menu.

> **Note**: This project is experimental. No builds have been tested on real hardware yet.

## Features

- Multi-version support: Android 4.4 (KitKat) through Android 9.0 (Pie)
- Cross-platform build system (Linux native, Windows via WSL2)
- One-click automated build scripts
- Minimal system with custom launcher and settings
- WiFi Access Point mode
- ADB/sideloading enabled by default

## Hardware

Google Glass Explorer Edition (Rev 1):
- **SoC**: TI OMAP4430 (dual-core Cortex-A9 @ 1.0 GHz)
- **RAM**: 1GB LPDDR2
- **Storage**: 16GB eMMC
- **Display**: 640x360 LCoS prism

## Quick Start

```bash
# Clone and enter directory
git clone https://github.com/sp00nznet/GlassPorts.git
cd GlassPorts

# Run automated build (Linux)
./build-glassports.sh --version 9

# Or step-by-step
source build/envsetup.sh
select_aosp_version
init_aosp
sync_aosp 8
setup_device
build_rom
package_rom
```

See [docs/BUILDING.md](docs/BUILDING.md) for detailed build instructions.

## AOSP Versions

| Android Version | API | Branch | Status |
|-----------------|-----|--------|--------|
| 9.0 Pie | 28 | android-9.0.0_r61 | Untested |
| 8.1 Oreo MR1 | 27 | android-8.1.0_r81 | Untested |
| 8.0 Oreo | 26 | android-8.0.0_r51 | Untested |
| 7.1 Nougat | 25 | android-7.1.2_r39 | Untested |
| 7.0 Nougat | 24 | android-7.0.0_r36 | Untested |
| 6.0 Marshmallow | 23 | android-6.0.1_r81 | Untested |
| 5.1 Lollipop | 22 | android-5.1.1_r38 | Untested |
| 5.0 Lollipop | 21 | android-5.0.2_r3 | Untested |
| 4.4 KitKat | 19 | android-4.4.4_r2 | Untested (Original Glass base) |

## Proprietary Files

Binary blobs must be extracted from an original Glass device:

```bash
cd vendor/google/glass
./extract-files.sh -d
```

## Flashing

```bash
adb reboot bootloader
fastboot flash boot boot.img
fastboot flash system system.img
fastboot reboot
```

## Project Structure

```
GlassPorts/
├── build/                  # Build scripts and manifests
├── device/google/glass/    # Device configuration
├── kernel/omap/            # Kernel source
├── packages/               # Custom apps (Launcher, Settings)
└── vendor/google/glass/    # Proprietary blobs (not included)
```

## License

Apache 2.0 (same as AOSP). Proprietary blobs are subject to their respective licenses.

## Disclaimer

Not affiliated with Google. Use at your own risk. Modifying your device may void its warranty.

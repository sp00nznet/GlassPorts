# GlassPorts Build Guide

This guide provides detailed instructions for building GlassPorts from source.

## System Requirements

### Hardware
- **CPU**: 4+ cores recommended (8+ for faster builds)
- **RAM**: 16GB minimum, 32GB recommended
- **Storage**: 250GB+ free space (AOSP source is large)
- **Internet**: Fast connection for downloading source

### Software (Linux)
- Ubuntu 18.04+ or equivalent
- Python 3.6+
- OpenJDK 8 or 11
- Git 2.0+
- GNU Make 4.0+

### Software (Windows)
- Windows 10/11 with WSL2
- Or Cygwin with development packages

## Detailed Build Instructions

### Step 1: Environment Setup

#### Linux

```bash
# Install required packages (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y \
    git-core gnupg flex bison build-essential zip curl \
    zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
    libncurses5 lib32ncurses5-dev x11proto-core-dev \
    libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
    xsltproc unzip fontconfig python3 python-is-python3

# Install Java
sudo apt-get install -y openjdk-11-jdk

# Install repo tool
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# Configure git
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

#### Windows (WSL2)

```powershell
# In PowerShell (Administrator)
wsl --install -d Ubuntu

# After restart, open Ubuntu terminal and follow Linux instructions
```

### Step 2: Get GlassPorts Source

```bash
git clone https://github.com/sp00nznet/GlassPorts.git
cd GlassPorts
```

### Step 3: Initialize Build Environment

```bash
source build/envsetup.sh
```

This loads the following commands:
- `check_dependencies` - Verify all tools are installed
- `select_aosp_version` - Choose Android version
- `init_aosp` - Initialize AOSP repository
- `sync_aosp` - Download AOSP source
- `setup_device` - Setup Glass device tree
- `build_rom` - Build the ROM
- `clean_build` - Clean build artifacts
- `package_rom` - Create flashable package

### Step 4: Check Dependencies

```bash
check_dependencies
```

This verifies:
- git, repo, curl, wget
- Python 3
- make, gcc, g++
- Java
- zip/unzip

### Step 5: Select AOSP Version

```bash
select_aosp_version
```

Choose from:
1. Android 9.0 (Pie) - Latest supported
2. Android 8.1 (Oreo MR1)
3. Android 8.0 (Oreo)
4. Android 7.1 (Nougat)
5. Android 7.0 (Nougat)
6. Android 6.0 (Marshmallow)
7. Android 5.1 (Lollipop)
8. Android 5.0 (Lollipop)
9. Android 4.4 (KitKat) - Original Glass OS base

### Step 6: Initialize AOSP

```bash
init_aosp
```

This:
- Creates `aosp/` directory
- Initializes repo with selected branch
- Adds GlassPorts local manifests

### Step 7: Sync AOSP Source

```bash
sync_aosp 8  # Adjust job count based on CPU/bandwidth
```

This downloads ~100GB of source code. First sync takes several hours.

**Tips for faster sync:**
- Use wired internet connection
- Increase job count for faster CPUs: `sync_aosp 16`
- Use `--depth=1` for shallow clone (already configured)

### Step 8: Extract Proprietary Files

Before building, you need proprietary binary blobs from an original Glass device:

```bash
# Connect Glass via USB
adb devices  # Verify connection

# Extract files
cd vendor/google/glass
./extract-files.sh -d
cd ../../..
```

### Step 9: Setup Device Tree

```bash
setup_device
```

This links GlassPorts device configuration into the AOSP tree.

### Step 10: Build

```bash
build_rom  # Uses all CPU cores by default
# Or specify job count:
build_rom 8
```

Build takes 1-4 hours depending on hardware.

**Build targets:**
- `aosp_glass-userdebug` - Default, recommended
- `aosp_glass-eng` - For development
- `aosp_glass_mini-userdebug` - Minimal build

### Step 11: Package

```bash
package_rom
```

Creates a flashable ZIP in `out/` directory.

## Troubleshooting

### Out of Memory

```bash
# Increase swap space
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Reduce parallel jobs
build_rom 4
```

### Jack Server Issues

```bash
# Kill Jack server
jack-admin kill-server

# Increase memory
export JACK_SERVER_VM_ARGUMENTS="-Xmx4g -Dfile.encoding=UTF-8"
```

### Missing Dependencies

```bash
# On build failure, check for missing packages
sudo apt-get install <missing-package>
```

### Repo Sync Failures

```bash
# If sync fails, retry with force sync
cd aosp
repo sync -c -j4 --force-sync
```

## Advanced Configuration

### Building Specific Components

```bash
# Build just the kernel
cd aosp
source build/envsetup.sh
lunch aosp_glass-userdebug
make bootimage -j8

# Build just system
make systemimage -j8

# Build specific app
make GlassLauncher -j8
```

### Customizing the Build

Edit `device/google/glass/device.mk` for:
- System properties
- Included packages
- Hardware features

Edit `device/google/glass/BoardConfig.mk` for:
- Partition sizes
- Kernel config
- Build options

### Creating a Custom Kernel

```bash
cd kernel/omap
make ARCH=arm glass_defconfig
make ARCH=arm menuconfig  # Customize
make ARCH=arm -j8
```

## Build Output

After successful build, find images in:
```
aosp/out/target/product/glass/
├── boot.img          # Kernel + ramdisk
├── system.img        # System partition
├── recovery.img      # Recovery
├── userdata.img      # Data partition
└── cache.img         # Cache partition
```

Packaged ROM in:
```
out/GlassPorts_<version>_<timestamp>.zip
```

## Continuous Integration

For automated builds, use the full build command:

```bash
source build/envsetup.sh && \
check_dependencies && \
export AOSP_BRANCH=android-9.0.0_r61 && \
init_aosp && \
sync_aosp 8 && \
setup_device && \
build_rom && \
package_rom
```

#!/bin/bash
#
# GlassPorts Build Environment Setup
# Cross-platform build system for porting AOSP to Google Glass Rev 1
#

set -e

# Ensure $HOME/bin is in PATH (for repo tool)
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    export PATH="$HOME/bin:$PATH"
fi

# Configuration
export GLASSPORTS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GLASSPORTS_BUILD="${GLASSPORTS_ROOT}/build"
export GLASSPORTS_OUT="${GLASSPORTS_ROOT}/out"
export GLASSPORTS_DEVICE="${GLASSPORTS_ROOT}/device/google/glass"
export GLASSPORTS_VENDOR="${GLASSPORTS_ROOT}/vendor/google/glass"
export GLASSPORTS_KERNEL="${GLASSPORTS_ROOT}/kernel/omap"

# AOSP must be on a case-sensitive filesystem
# If running on Windows/WSL, use the native Linux filesystem
if [[ "$GLASSPORTS_ROOT" == /mnt/* ]]; then
    # Running from Windows mount - use WSL native filesystem for AOSP
    export GLASSPORTS_AOSP="$HOME/GlassPorts-aosp"
    log_warning "Windows filesystem detected. AOSP will be stored in: $GLASSPORTS_AOSP" 2>/dev/null || true
else
    # Native Linux - can use local directory
    export GLASSPORTS_AOSP="${GLASSPORTS_ROOT}/aosp"
fi

# AOSP configuration
export AOSP_MIRROR="https://android.googlesource.com"
export AOSP_BRANCH=""
export TARGET_DEVICE="glass"
export TARGET_PRODUCT="aosp_glass"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log_info "Checking build dependencies..."

    local missing_deps=()

    # Required tools
    local required_tools=(
        "git"
        "repo"
        "curl"
        "wget"
        "python3"
        "make"
        "gcc"
        "g++"
        "zip"
        "unzip"
        "java"
    )

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("$tool")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies before continuing."
        return 1
    fi

    log_success "All dependencies satisfied."
    return 0
}

# Select AOSP version
select_aosp_version() {
    echo ""
    echo "Available AOSP versions for Google Glass:"
    echo "  1) Android 9.0 (Pie)       - API 28"
    echo "  2) Android 8.1 (Oreo MR1)  - API 27"
    echo "  3) Android 8.0 (Oreo)      - API 26"
    echo "  4) Android 7.1 (Nougat)    - API 25"
    echo "  5) Android 7.0 (Nougat)    - API 24"
    echo "  6) Android 6.0 (Marshmallow) - API 23"
    echo "  7) Android 5.1 (Lollipop)  - API 22"
    echo "  8) Android 5.0 (Lollipop)  - API 21"
    echo "  9) Android 4.4 (KitKat)    - API 19 (Original Glass OS base)"
    echo ""

    read -p "Select version [1-9]: " choice

    case $choice in
        1) export AOSP_BRANCH="android-9.0.0_r61" ;;
        2) export AOSP_BRANCH="android-8.1.0_r81" ;;
        3) export AOSP_BRANCH="android-8.0.0_r51" ;;
        4) export AOSP_BRANCH="android-7.1.2_r39" ;;
        5) export AOSP_BRANCH="android-7.0.0_r36" ;;
        6) export AOSP_BRANCH="android-6.0.1_r81" ;;
        7) export AOSP_BRANCH="android-5.1.1_r38" ;;
        8) export AOSP_BRANCH="android-5.0.2_r3" ;;
        9) export AOSP_BRANCH="android-4.4.4_r2" ;;
        *)
            log_error "Invalid selection"
            return 1
            ;;
    esac

    log_success "Selected AOSP branch: $AOSP_BRANCH"
    return 0
}

# Initialize AOSP source
init_aosp() {
    local aosp_dir="${GLASSPORTS_AOSP}"

    if [ -z "$AOSP_BRANCH" ]; then
        log_error "AOSP branch not selected. Run 'select_aosp_version' first."
        return 1
    fi

    log_info "Initializing AOSP source for branch: $AOSP_BRANCH"

    mkdir -p "$aosp_dir"
    cd "$aosp_dir"

    # Initialize repo
    repo init -u "$AOSP_MIRROR/platform/manifest" -b "$AOSP_BRANCH" --depth=1

    # Add local manifests for Glass device
    mkdir -p .repo/local_manifests
    cp "${GLASSPORTS_BUILD}/manifests/glass_manifest.xml" .repo/local_manifests/

    log_success "AOSP initialized successfully"
    return 0
}

# Sync AOSP source
sync_aosp() {
    local aosp_dir="${GLASSPORTS_AOSP}"
    local jobs="${1:-4}"

    if [ ! -d "$aosp_dir/.repo" ]; then
        log_error "AOSP not initialized. Run 'init_aosp' first."
        return 1
    fi

    log_info "Syncing AOSP source with $jobs parallel jobs..."

    cd "$aosp_dir"

    # Run repo sync with progress output to prevent CI timeout
    # Uses --force-sync to handle any interrupted syncs
    repo sync -c -j"$jobs" --no-tags --no-clone-bundle --force-sync 2>&1 | while IFS= read -r line; do
        echo "$line"
        # Print keepalive every 100 lines to ensure CI sees activity
        if (( ++_line_count % 100 == 0 )); then
            echo "[keepalive] $(date '+%H:%M:%S') - $_line_count lines, sync continuing..."
        fi
    done
    SYNC_STATUS=${PIPESTATUS[0]}

    if [ $SYNC_STATUS -ne 0 ]; then
        log_error "Repo sync failed with status $SYNC_STATUS"
        return 1
    fi

    log_success "AOSP sync complete"
    return 0
}

# Setup device tree
setup_device() {
    local aosp_dir="${GLASSPORTS_AOSP}"

    if [ ! -d "$aosp_dir" ]; then
        log_error "AOSP directory not found"
        return 1
    fi

    log_info "Setting up Google Glass device tree..."

    # Link device configuration
    mkdir -p "$aosp_dir/device/google"
    ln -sf "$GLASSPORTS_DEVICE" "$aosp_dir/device/google/glass"

    # Link vendor blobs
    mkdir -p "$aosp_dir/vendor/google"
    ln -sf "$GLASSPORTS_VENDOR" "$aosp_dir/vendor/google/glass"

    # Link kernel
    mkdir -p "$aosp_dir/kernel"
    ln -sf "$GLASSPORTS_KERNEL" "$aosp_dir/kernel/omap"

    # Link custom packages
    ln -sf "${GLASSPORTS_ROOT}/packages/apps/GlassLauncher" "$aosp_dir/packages/apps/GlassLauncher"
    ln -sf "${GLASSPORTS_ROOT}/packages/apps/GlassSettings" "$aosp_dir/packages/apps/GlassSettings"

    log_success "Device tree setup complete"
    return 0
}

# Build the ROM
build_rom() {
    local aosp_dir="${GLASSPORTS_AOSP}"
    local jobs="${1:-$(nproc)}"

    if [ ! -d "$aosp_dir" ]; then
        log_error "AOSP directory not found"
        return 1
    fi

    log_info "Building GlassPorts ROM..."

    cd "$aosp_dir"

    # Setup build environment
    source build/envsetup.sh

    # Select target
    lunch "$TARGET_PRODUCT-userdebug"

    # Build
    make -j"$jobs"

    log_success "ROM build complete!"
    log_info "Output images are in: $aosp_dir/out/target/product/glass/"
    return 0
}

# Clean build
clean_build() {
    local aosp_dir="${GLASSPORTS_AOSP}"

    if [ -d "$aosp_dir" ]; then
        log_info "Cleaning build artifacts..."
        cd "$aosp_dir"
        make clean
        log_success "Build cleaned"
    fi

    return 0
}

# Package ROM
package_rom() {
    local aosp_dir="${GLASSPORTS_AOSP}"
    local output_dir="${GLASSPORTS_OUT}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local version="${AOSP_BRANCH:-unknown}"
    local package_name="GlassPorts_${version}_${timestamp}.zip"

    log_info "Packaging ROM..."

    mkdir -p "$output_dir"

    # Create flashable zip
    cd "$aosp_dir/out/target/product/glass"

    if [ ! -f "boot.img" ] || [ ! -f "system.img" ]; then
        log_error "Build images not found. Run 'build_rom' first."
        return 1
    fi

    # Package with recovery script
    zip -r "$output_dir/$package_name" \
        boot.img \
        system.img \
        recovery.img \
        userdata.img \
        META-INF/

    log_success "ROM packaged: $output_dir/$package_name"
    return 0
}

# Install all dependencies automatically
install_deps() {
    log_info "Installing build dependencies..."

    local install_script="${GLASSPORTS_BUILD}/tools/install-deps.sh"

    if [ -f "$install_script" ]; then
        chmod +x "$install_script"
        bash "$install_script"
    else
        log_error "Dependency installer not found: $install_script"
        return 1
    fi

    log_success "Dependencies installed"
    return 0
}

# Download factory images and extract blobs
download_blobs() {
    local version="${1:-XE24}"

    log_info "Downloading factory images and extracting blobs..."

    local download_script="${GLASSPORTS_BUILD}/tools/download-factory-images.sh"

    if [ -f "$download_script" ]; then
        chmod +x "$download_script"
        bash "$download_script" "$version"
    else
        log_error "Factory image downloader not found: $download_script"
        return 1
    fi

    log_success "Blobs extracted"
    return 0
}

# Full automated build - everything in one command
full_build() {
    local android_version="${1:-9}"
    local jobs="${2:-$(nproc)}"

    log_info "Starting full automated build for Android $android_version..."

    # Map version to branch
    case $android_version in
        9)  export AOSP_BRANCH="android-9.0.0_r61" ;;
        8)  export AOSP_BRANCH="android-8.1.0_r81" ;;
        7)  export AOSP_BRANCH="android-7.1.2_r39" ;;
        6)  export AOSP_BRANCH="android-6.0.1_r81" ;;
        5)  export AOSP_BRANCH="android-5.1.1_r38" ;;
        4)  export AOSP_BRANCH="android-4.4.4_r2" ;;
        *)
            log_error "Invalid Android version: $android_version"
            return 1
            ;;
    esac

    log_info "Using AOSP branch: $AOSP_BRANCH"

    # Run all steps
    check_dependencies || return 1
    init_aosp || return 1
    sync_aosp "$jobs" || return 1
    setup_device || return 1
    build_rom "$jobs" || return 1
    package_rom || return 1

    log_success "Full build complete!"
    return 0
}

# Print help
glassports_help() {
    echo ""
    echo "GlassPorts Build System"
    echo "======================="
    echo ""
    echo "Available commands:"
    echo "  check_dependencies  - Check if all build dependencies are installed"
    echo "  install_deps        - AUTO-INSTALL all build dependencies"
    echo "  download_blobs [VER]- Download Glass factory images & extract blobs"
    echo "  select_aosp_version - Select AOSP version to build"
    echo "  init_aosp           - Initialize AOSP source repository"
    echo "  sync_aosp [jobs]    - Sync AOSP source (default: 4 jobs)"
    echo "  setup_device        - Setup Google Glass device tree"
    echo "  build_rom [jobs]    - Build the ROM (default: all cores)"
    echo "  clean_build         - Clean build artifacts"
    echo "  package_rom         - Package ROM for flashing"
    echo "  full_build [ver] [j]- FULL AUTOMATED BUILD (ver=4-9, j=jobs)"
    echo "  glassports_help     - Show this help message"
    echo ""
    echo "Quick start (manual):"
    echo "  1. source build/envsetup.sh"
    echo "  2. check_dependencies"
    echo "  3. select_aosp_version"
    echo "  4. init_aosp"
    echo "  5. sync_aosp"
    echo "  6. setup_device"
    echo "  7. build_rom"
    echo "  8. package_rom"
    echo ""
    echo "One-click build (automated):"
    echo "  source build/envsetup.sh && full_build 9"
    echo ""
    echo "Or use the build scripts:"
    echo "  Linux:   ./build-glassports.sh"
    echo "  Windows: build-glassports.bat (double-click)"
    echo ""
}

# Auto-run on source
log_info "GlassPorts build environment loaded."
log_info "Run 'glassports_help' for available commands."

#!/bin/bash
#
# ============================================================================
# GlassPorts One-Click Automated Build System for Linux
# ============================================================================
#
# This script automatically:
#   1. Installs all build dependencies
#   2. Downloads Google Glass factory images
#   3. Extracts proprietary binary blobs
#   4. Syncs AOSP source code
#   5. Builds the complete ROM
#
# Usage:
#   ./build-glassports.sh [OPTIONS]
#
# Options:
#   --version VERSION   Android version (4-9, default: 9)
#   --jobs N           Parallel build jobs (default: auto)
#   --skip-deps        Skip dependency installation
#   --skip-download    Skip factory image download
#   --skip-sync        Skip AOSP sync (use existing)
#   --clean            Clean build before starting
#   --help             Show this help
#
# ============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Default configuration
ANDROID_VERSION=9
PARALLEL_JOBS=$(nproc)
GLASS_IMAGE_VERSION="XE24"
SKIP_DEPS=false
SKIP_DOWNLOAD=false
SKIP_SYNC=false
CLEAN_BUILD=false

# Logging functions
log_header() {
    echo ""
    echo -e "${CYAN}========================================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================================================${NC}"
    echo ""
}

log_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show help
show_help() {
    cat << EOF
GlassPorts One-Click Automated Build System

Usage: $0 [OPTIONS]

Options:
  --version VERSION   Android version to build (4-9, default: 9)
                      4 = Android 4.4 KitKat (original Glass base)
                      5 = Android 5.1 Lollipop
                      6 = Android 6.0 Marshmallow
                      7 = Android 7.1 Nougat
                      8 = Android 8.1 Oreo
                      9 = Android 9.0 Pie (recommended)

  --jobs N            Number of parallel build jobs (default: auto-detect)
  --image VERSION     Glass factory image version (default: XE24)
  --skip-deps         Skip dependency installation
  --skip-download     Skip factory image download
  --skip-sync         Skip AOSP sync (use existing source)
  --clean             Clean build before starting
  --help              Show this help message

Examples:
  $0                          # Build Android 9 with defaults
  $0 --version 8              # Build Android 8.1 Oreo
  $0 --jobs 16                # Build with 16 parallel jobs
  $0 --skip-sync              # Rebuild without re-syncing
  $0 --clean --version 9      # Clean build of Android 9

Requirements:
  - 16GB+ RAM (32GB recommended)
  - 300GB+ free disk space
  - Fast internet connection
  - Ubuntu 18.04+ or compatible Linux distribution

EOF
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                ANDROID_VERSION="$2"
                shift 2
                ;;
            --jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            --image)
                GLASS_IMAGE_VERSION="$2"
                shift 2
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --skip-download)
                SKIP_DOWNLOAD=true
                shift
                ;;
            --skip-sync)
                SKIP_SYNC=true
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Map version to AOSP branch
get_aosp_branch() {
    case $ANDROID_VERSION in
        9)  echo "android-9.0.0_r61" ;;
        8)  echo "android-8.1.0_r81" ;;
        7)  echo "android-7.1.2_r39" ;;
        6)  echo "android-6.0.1_r81" ;;
        5)  echo "android-5.1.1_r38" ;;
        4)  echo "android-4.4.4_r2" ;;
        *)
            log_error "Invalid Android version: $ANDROID_VERSION"
            log_info "Valid versions: 4, 5, 6, 7, 8, 9"
            exit 1
            ;;
    esac
}

# Check system requirements
check_requirements() {
    log_step "0/7" "Checking system requirements..."

    # Check RAM
    local total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 8 ]; then
        log_error "Insufficient RAM: ${total_ram}GB (minimum 8GB, recommended 16GB+)"
        exit 1
    elif [ "$total_ram" -lt 16 ]; then
        log_warning "Low RAM: ${total_ram}GB (recommended 16GB+)"
        log_info "Build may be slow or fail. Consider adding swap space."
    else
        log_success "RAM: ${total_ram}GB"
    fi

    # Check disk space
    local free_space=$(df -BG "$SCRIPT_DIR" | awk 'NR==2 {print $4}' | tr -d 'G')
    if [ "$free_space" -lt 100 ]; then
        log_error "Insufficient disk space: ${free_space}GB (minimum 100GB, recommended 300GB+)"
        exit 1
    elif [ "$free_space" -lt 300 ]; then
        log_warning "Low disk space: ${free_space}GB (recommended 300GB+)"
    else
        log_success "Disk space: ${free_space}GB"
    fi

    # Check CPU cores
    local cpu_cores=$(nproc)
    log_success "CPU cores: $cpu_cores (using $PARALLEL_JOBS for build)"

    echo ""
}

# Install dependencies
install_dependencies() {
    if [ "$SKIP_DEPS" = true ]; then
        log_info "Skipping dependency installation (--skip-deps)"
        return 0
    fi

    log_step "1/7" "Installing build dependencies..."

    if [ -f "$SCRIPT_DIR/build/tools/install-deps.sh" ]; then
        chmod +x "$SCRIPT_DIR/build/tools/install-deps.sh"
        bash "$SCRIPT_DIR/build/tools/install-deps.sh"
    else
        log_error "Dependency installer not found"
        exit 1
    fi

    log_success "Dependencies installed"
    echo ""
}

# Download factory images
download_factory_images() {
    if [ "$SKIP_DOWNLOAD" = true ]; then
        log_info "Skipping factory image download (--skip-download)"
        return 0
    fi

    log_step "2/7" "Downloading Google Glass factory images..."

    if [ -f "$SCRIPT_DIR/build/tools/download-factory-images.sh" ]; then
        chmod +x "$SCRIPT_DIR/build/tools/download-factory-images.sh"
        bash "$SCRIPT_DIR/build/tools/download-factory-images.sh" "$GLASS_IMAGE_VERSION" || {
            log_warning "Factory image download may have had issues"
            log_info "Continuing - some proprietary features may not work"
        }
    else
        log_warning "Factory image downloader not found"
        log_info "Proprietary blobs will need to be added manually"
    fi

    log_success "Factory images processed"
    echo ""
}

# Initialize and sync AOSP
sync_aosp_source() {
    log_step "3/7" "Setting up AOSP source..."

    # Source the environment
    source "$SCRIPT_DIR/build/envsetup.sh"

    # Set AOSP branch
    export AOSP_BRANCH=$(get_aosp_branch)
    log_info "AOSP branch: $AOSP_BRANCH"

    if [ "$SKIP_SYNC" = true ]; then
        log_info "Skipping AOSP sync (--skip-sync)"

        # Still need to setup device tree
        log_info "Setting up device tree..."
        setup_device

        return 0
    fi

    # Initialize AOSP
    log_info "Initializing AOSP repository..."
    init_aosp

    # Sync AOSP
    log_step "4/7" "Syncing AOSP source (this will take a while)..."
    sync_aosp "$PARALLEL_JOBS"

    # Setup device tree
    log_step "5/7" "Setting up device tree..."
    setup_device

    log_success "AOSP source ready"
    echo ""
}

# Build ROM
build_rom_image() {
    log_step "6/7" "Building GlassPorts ROM..."

    # Source environment again (in case it was lost)
    source "$SCRIPT_DIR/build/envsetup.sh"
    export AOSP_BRANCH=$(get_aosp_branch)

    # Clean if requested
    if [ "$CLEAN_BUILD" = true ]; then
        log_info "Cleaning previous build..."
        clean_build
    fi

    # Build
    build_rom "$PARALLEL_JOBS"

    log_success "ROM built successfully"
    echo ""
}

# Package ROM
package_rom_image() {
    log_step "7/7" "Packaging ROM..."

    # Source environment
    source "$SCRIPT_DIR/build/envsetup.sh"
    export AOSP_BRANCH=$(get_aosp_branch)

    package_rom

    log_success "ROM packaged"
    echo ""
}

# Show completion message
show_completion() {
    log_header "BUILD COMPLETE!"

    echo -e "${WHITE}Your GlassPorts ROM has been built successfully!${NC}"
    echo ""
    echo -e "${CYAN}Output files are located in:${NC}"
    echo "  $SCRIPT_DIR/out/"
    echo ""
    echo -e "${CYAN}To flash to your Google Glass:${NC}"
    echo "  1. Connect Glass via USB"
    echo "  2. Enable USB debugging"
    echo "  3. Run: adb reboot bootloader"
    echo "  4. Run: fastboot flash boot boot.img"
    echo "  5. Run: fastboot flash system system.img"
    echo "  6. Run: fastboot reboot"
    echo ""
    echo -e "${YELLOW}Or use the packaged ZIP with custom recovery:${NC}"
    echo "  adb sideload GlassPorts_*.zip"
    echo ""

    # List output files
    if [ -d "$SCRIPT_DIR/out" ]; then
        echo -e "${CYAN}Output files:${NC}"
        ls -lh "$SCRIPT_DIR/out/"*.zip 2>/dev/null || true
        echo ""
    fi
}

# Main function
main() {
    parse_args "$@"

    log_header "GlassPorts One-Click Automated Build System"

    echo -e "${WHITE}Configuration:${NC}"
    echo "  - Android Version: $ANDROID_VERSION ($(get_aosp_branch))"
    echo "  - Parallel Jobs: $PARALLEL_JOBS"
    echo "  - Factory Image: $GLASS_IMAGE_VERSION"
    echo "  - Skip Dependencies: $SKIP_DEPS"
    echo "  - Skip Download: $SKIP_DOWNLOAD"
    echo "  - Skip Sync: $SKIP_SYNC"
    echo "  - Clean Build: $CLEAN_BUILD"
    echo ""

    # Record start time
    START_TIME=$(date +%s)

    # Run build steps
    check_requirements
    install_dependencies
    download_factory_images
    sync_aosp_source
    build_rom_image
    package_rom_image

    # Calculate elapsed time
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    HOURS=$((ELAPSED / 3600))
    MINUTES=$(((ELAPSED % 3600) / 60))

    show_completion

    echo -e "${GREEN}Total build time: ${HOURS}h ${MINUTES}m${NC}"
    echo ""
}

# Run
main "$@"

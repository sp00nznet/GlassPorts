#!/bin/bash
#
# GlassPorts Factory Image Downloader
# Downloads and extracts Google Glass factory images for proprietary blobs
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLASSPORTS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOWNLOAD_DIR="$GLASSPORTS_ROOT/downloads"
EXTRACT_DIR="$DOWNLOAD_DIR/extracted"
VENDOR_DIR="$GLASSPORTS_ROOT/vendor/google/glass/proprietary"

# Google Glass Factory Image URLs
# These are the known factory images for Google Glass Explorer Edition
# Note: Google may change these URLs - update as needed

declare -A FACTORY_IMAGES=(
    # XE24 - Latest official release
    ["XE24"]="https://dl.google.com/glass/xe24/glass-xe24-factory.zip"
    # XE22 - Stable release
    ["XE22"]="https://dl.google.com/glass/xe22/glass-xe22-factory.zip"
    # XE21 - Previous release
    ["XE21"]="https://dl.google.com/glass/xe21/glass-xe21-factory.zip"
    # XE20
    ["XE20"]="https://dl.google.com/glass/xe20/glass-xe20-factory.zip"
    # XE19.1
    ["XE19.1"]="https://dl.google.com/glass/xe19.1/glass-xe19.1-factory.zip"
)

# Fallback mirrors (community mirrors)
declare -A FALLBACK_MIRRORS=(
    ["XE24"]="https://archive.org/download/google-glass-factory-images/glass-xe24-factory.zip"
    ["XE22"]="https://archive.org/download/google-glass-factory-images/glass-xe22-factory.zip"
)

# Required proprietary files to extract
PROPRIETARY_FILES=(
    # GPU - PowerVR SGX540
    "system/vendor/lib/egl/libEGL_POWERVR_SGX540_120.so"
    "system/vendor/lib/egl/libGLESv1_CM_POWERVR_SGX540_120.so"
    "system/vendor/lib/egl/libGLESv2_POWERVR_SGX540_120.so"
    "system/vendor/lib/libglslcompiler.so"
    "system/vendor/lib/libIMGegl.so"
    "system/vendor/lib/libpvr2d.so"
    "system/vendor/lib/libpvrANDROID_WSEGL.so"
    "system/vendor/lib/libPVRScopeServices.so"
    "system/vendor/lib/libsrv_init.so"
    "system/vendor/lib/libsrv_um.so"
    "system/vendor/lib/libusc.so"
    "system/vendor/lib/hw/gralloc.omap4.so"

    # WiFi - TI WiLink
    "system/etc/firmware/ti-connectivity/wl127x-fw-5-sr.bin"
    "system/etc/firmware/ti-connectivity/wl127x-fw-5-mr.bin"
    "system/etc/firmware/ti-connectivity/wl127x-fw-5-plt.bin"
    "system/etc/firmware/ti-connectivity/TIInit_7.6.15.bts"
    "system/vendor/lib/hw/wlan.ti.so"
    "system/lib/modules/wl12xx_sdio.ko"

    # Camera - DUCATI (TI camera subsystem)
    "system/vendor/lib/libcamera.so"
    "system/vendor/lib/libOMX.TI.DUCATI1.VIDEO.CAMERA.so"
    "system/vendor/lib/libOMX.TI.DUCATI1.VIDEO.DECODER.so"
    "system/vendor/lib/libOMX.TI.DUCATI1.VIDEO.H264E.so"
    "system/vendor/lib/libOMX.TI.DUCATI1.MISC.SAMPLE.so"
    "system/etc/firmware/ducati-m3.bin"

    # Audio
    "system/vendor/lib/hw/audio.primary.glass.so"
    "system/vendor/lib/soundfx/libbundlewrapper.so"
    "system/vendor/lib/soundfx/libeffectproxy.so"

    # Sensors
    "system/vendor/lib/hw/sensors.glass.so"
    "system/vendor/lib/libmpl.so"
    "system/vendor/lib/libmllite.so"
    "system/vendor/lib/libmlplatform.so"

    # Bluetooth
    "system/vendor/lib/hw/bluetooth.glass.so"

    # DRM
    "system/vendor/lib/drm/libdrmwvmplugin.so"
    "system/vendor/lib/libwvm.so"
    "system/vendor/lib/libWVStreamControlAPI_L3.so"

    # Misc
    "system/vendor/lib/libpn544_fw.so"
    "system/vendor/lib/lib_Ti_SST.so"
)

# Download with retry
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry=0

    while [ $retry -lt $max_retries ]; do
        log_info "Downloading: $(basename "$output") (attempt $((retry + 1))/$max_retries)"

        if curl -L -# -o "$output" "$url" 2>&1; then
            # Verify file is not empty and is a valid zip
            if [ -s "$output" ]; then
                # Try file command first, fall back to unzip test
                if command -v file &> /dev/null; then
                    file "$output" | grep -q -i "zip" && return 0
                else
                    unzip -t "$output" &> /dev/null && return 0
                fi
            fi
        fi

        retry=$((retry + 1))
        if [ $retry -lt $max_retries ]; then
            log_warning "Download failed, retrying in 5 seconds..."
            sleep 5
        fi
    done

    return 1
}

# Select and download factory image
download_factory_image() {
    local version="${1:-XE24}"

    mkdir -p "$DOWNLOAD_DIR"

    log_step "Downloading Google Glass factory image ($version)..."

    local url="${FACTORY_IMAGES[$version]}"
    local fallback="${FALLBACK_MIRRORS[$version]}"
    local output="$DOWNLOAD_DIR/glass-${version,,}-factory.zip"

    # Check if already downloaded
    if [ -f "$output" ] && [ -s "$output" ]; then
        log_info "Factory image already downloaded: $output"
        echo "$output"
        return 0
    fi

    # Try primary URL
    if [ -n "$url" ]; then
        if download_with_retry "$url" "$output"; then
            log_success "Downloaded from primary source"
            echo "$output"
            return 0
        fi
    fi

    # Try fallback
    if [ -n "$fallback" ]; then
        log_warning "Primary download failed, trying fallback..."
        if download_with_retry "$fallback" "$output"; then
            log_success "Downloaded from fallback source"
            echo "$output"
            return 0
        fi
    fi

    log_error "Failed to download factory image"
    return 1
}

# Extract factory image
extract_factory_image() {
    local zip_file="$1"

    mkdir -p "$EXTRACT_DIR"

    log_step "Extracting factory image..."

    # Extract outer zip
    unzip -o -q "$zip_file" -d "$EXTRACT_DIR"

    # Find and extract inner images
    local image_dir=$(find "$EXTRACT_DIR" -maxdepth 1 -type d -name "glass-*" | head -1)

    if [ -z "$image_dir" ]; then
        image_dir="$EXTRACT_DIR"
    fi

    cd "$image_dir"

    # Extract system.img
    if [ -f "image-*.zip" ]; then
        unzip -o -q image-*.zip
    fi

    # Handle different image formats
    if [ -f "system.img" ]; then
        log_info "Found system.img, extracting..."
        extract_system_image "$image_dir/system.img"
    elif [ -f "system.img.raw" ]; then
        log_info "Found system.img.raw, extracting..."
        extract_system_image "$image_dir/system.img.raw"
    fi

    log_success "Factory image extracted"
    echo "$image_dir"
}

# Extract system image (handles sparse and raw formats)
extract_system_image() {
    local img_file="$1"
    local mount_dir="$EXTRACT_DIR/system_mount"

    mkdir -p "$mount_dir"

    # Check if it's a sparse image
    if file "$img_file" | grep -q "Android sparse image"; then
        log_info "Converting sparse image to raw..."

        # Try simg2img
        if command -v simg2img &>/dev/null; then
            simg2img "$img_file" "${img_file}.raw"
            img_file="${img_file}.raw"
        else
            log_warning "simg2img not found, trying alternative method..."
            # Try with Python
            python3 "$SCRIPT_DIR/simg2img.py" "$img_file" "${img_file}.raw" 2>/dev/null || true
            if [ -f "${img_file}.raw" ]; then
                img_file="${img_file}.raw"
            fi
        fi
    fi

    # Try to mount the image
    if sudo mount -o loop,ro "$img_file" "$mount_dir" 2>/dev/null; then
        log_success "System image mounted at $mount_dir"
        SYSTEM_MOUNT="$mount_dir"
        MOUNTED=true
    else
        # Try extracting with 7z or other tools
        log_warning "Mount failed, trying alternative extraction..."

        if command -v 7z &>/dev/null; then
            7z x -o"$mount_dir" "$img_file" 2>/dev/null || true
        fi

        if [ -d "$mount_dir/system" ]; then
            SYSTEM_MOUNT="$mount_dir"
            MOUNTED=false
        else
            log_error "Could not extract system image"
            return 1
        fi
    fi
}

# Extract proprietary blobs
extract_proprietary_blobs() {
    local system_dir="$1"

    log_step "Extracting proprietary blobs..."

    mkdir -p "$VENDOR_DIR"

    local extracted=0
    local failed=0

    for file in "${PROPRIETARY_FILES[@]}"; do
        local src="$system_dir/$file"
        local dest="$VENDOR_DIR/$file"

        # Also try without system/ prefix
        if [ ! -f "$src" ]; then
            src="$system_dir/${file#system/}"
        fi

        # Try with /system prefix
        if [ ! -f "$src" ]; then
            src="$system_dir/system/${file#system/}"
        fi

        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
            log_info "Extracted: $(basename "$file")"
            extracted=$((extracted + 1))
        else
            log_warning "Not found: $file"
            failed=$((failed + 1))
        fi
    done

    log_info "Extracted $extracted files, $failed not found"

    # Generate blob makefiles
    generate_blob_makefiles

    return 0
}

# Generate Android.mk files for blobs
generate_blob_makefiles() {
    log_step "Generating vendor makefiles..."

    # Create main vendor makefile
    cat > "$VENDOR_DIR/../proprietary-files.txt" << 'EOF'
# Proprietary files for Google Glass
# Automatically extracted from factory image

# GPU - PowerVR SGX540
vendor/lib/egl/libEGL_POWERVR_SGX540_120.so
vendor/lib/egl/libGLESv1_CM_POWERVR_SGX540_120.so
vendor/lib/egl/libGLESv2_POWERVR_SGX540_120.so
vendor/lib/libglslcompiler.so
vendor/lib/libIMGegl.so
vendor/lib/libpvr2d.so
vendor/lib/libpvrANDROID_WSEGL.so
vendor/lib/libPVRScopeServices.so
vendor/lib/libsrv_init.so
vendor/lib/libsrv_um.so
vendor/lib/libusc.so
vendor/lib/hw/gralloc.omap4.so

# WiFi firmware
etc/firmware/ti-connectivity/wl127x-fw-5-sr.bin
etc/firmware/ti-connectivity/wl127x-fw-5-mr.bin
etc/firmware/ti-connectivity/wl127x-fw-5-plt.bin
etc/firmware/ti-connectivity/TIInit_7.6.15.bts

# Camera
vendor/lib/libcamera.so
vendor/lib/libOMX.TI.DUCATI1.VIDEO.CAMERA.so
vendor/lib/libOMX.TI.DUCATI1.VIDEO.DECODER.so
vendor/lib/libOMX.TI.DUCATI1.VIDEO.H264E.so
etc/firmware/ducati-m3.bin

# Audio
vendor/lib/hw/audio.primary.glass.so

# Sensors
vendor/lib/hw/sensors.glass.so
vendor/lib/libmpl.so
vendor/lib/libmllite.so
vendor/lib/libmlplatform.so

# Bluetooth
vendor/lib/hw/bluetooth.glass.so
EOF

    log_success "Vendor makefiles generated"
}

# Cleanup
cleanup() {
    log_step "Cleaning up..."

    # Unmount if mounted
    if [ "${MOUNTED:-false}" = true ] && [ -n "${SYSTEM_MOUNT:-}" ]; then
        sudo umount "$SYSTEM_MOUNT" 2>/dev/null || true
    fi

    # Optionally remove extracted files
    if [ "${KEEP_EXTRACTED:-false}" != true ]; then
        rm -rf "$EXTRACT_DIR"
    fi

    log_success "Cleanup complete"
}

# List available versions
list_versions() {
    echo ""
    echo "Available Google Glass factory image versions:"
    echo ""
    for version in "${!FACTORY_IMAGES[@]}"; do
        echo "  $version"
    done | sort -rV
    echo ""
}

# Main function
main() {
    local version="${1:-XE24}"

    echo ""
    echo "========================================"
    echo "  GlassPorts Factory Image Downloader"
    echo "========================================"
    echo ""

    # Handle arguments
    case "$version" in
        --list|-l)
            list_versions
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [VERSION]"
            echo ""
            echo "Options:"
            echo "  VERSION    Factory image version (default: XE24)"
            echo "  --list     List available versions"
            echo "  --help     Show this help"
            echo ""
            list_versions
            exit 0
            ;;
    esac

    # Check for required tools
    for tool in curl unzip; do
        if ! command -v $tool &>/dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done

    # Download factory image
    local zip_file
    zip_file=$(download_factory_image "$version")

    if [ -z "$zip_file" ] || [ ! -f "$zip_file" ]; then
        log_error "Failed to download factory image"
        exit 1
    fi

    # Extract factory image
    local extract_dir
    extract_dir=$(extract_factory_image "$zip_file")

    # Find system directory
    local system_dir
    for dir in "$extract_dir/system" "$EXTRACT_DIR/system_mount" "$extract_dir"; do
        if [ -d "$dir" ]; then
            system_dir="$dir"
            break
        fi
    done

    if [ -z "$system_dir" ]; then
        log_error "Could not find system directory"
        cleanup
        exit 1
    fi

    # Extract blobs
    extract_proprietary_blobs "$system_dir"

    # Cleanup
    trap cleanup EXIT

    echo ""
    log_success "Proprietary blobs extracted to: $VENDOR_DIR"
    echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

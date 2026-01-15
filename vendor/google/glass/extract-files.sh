#!/bin/bash
#
# GlassPorts Proprietary File Extractor
# Extracts binary blobs from a Google Glass device or factory image
#

set -e

VENDOR=google
DEVICE=glass

BASE="../../../vendor/$VENDOR/$DEVICE/proprietary"

echo "GlassPorts: Extracting proprietary files for $DEVICE"

# Check if running from device or from image
if [ "$1" == "-d" ]; then
    # Extract from connected device via ADB
    SRC="adb"
    echo "Extracting from connected device via ADB..."
    adb wait-for-device
elif [ -f "$1" ]; then
    # Extract from factory image
    SRC="$1"
    echo "Extracting from image: $SRC"
else
    echo "Usage: $0 [-d | <path-to-factory-image>]"
    echo "  -d  Extract from connected device via ADB"
    echo "  Otherwise specify path to factory image"
    exit 1
fi

# Create directory structure
mkdir -p "$BASE/vendor/lib/egl"
mkdir -p "$BASE/vendor/lib/hw"
mkdir -p "$BASE/vendor/lib/mediadrm"
mkdir -p "$BASE/vendor/firmware"
mkdir -p "$BASE/vendor/firmware/ti-connectivity"
mkdir -p "$BASE/vendor/bin"
mkdir -p "$BASE/include"

# Function to extract file
extract() {
    local src="$1"
    local dest="$2"

    if [ "$SRC" == "adb" ]; then
        adb pull "$src" "$BASE/$dest" 2>/dev/null || echo "Warning: Could not extract $src"
    else
        # Extract from image (would need image mounting logic)
        echo "Image extraction not yet implemented for: $src"
    fi
}

echo "Extracting graphics libraries (PowerVR SGX540)..."
extract "/vendor/lib/egl/libEGL_POWERVR_SGX540_120.so" "vendor/lib/egl/"
extract "/vendor/lib/egl/libGLESv1_CM_POWERVR_SGX540_120.so" "vendor/lib/egl/"
extract "/vendor/lib/egl/libGLESv2_POWERVR_SGX540_120.so" "vendor/lib/egl/"
extract "/vendor/lib/libglslcompiler.so" "vendor/lib/"
extract "/vendor/lib/libIMGegl.so" "vendor/lib/"
extract "/vendor/lib/libpvr2d.so" "vendor/lib/"
extract "/vendor/lib/libpvrANDROID_WSEGL.so" "vendor/lib/"
extract "/vendor/lib/libPVRScopeServices.so" "vendor/lib/"
extract "/vendor/lib/libsrv_init.so" "vendor/lib/"
extract "/vendor/lib/libsrv_um.so" "vendor/lib/"
extract "/vendor/lib/libusc.so" "vendor/lib/"
extract "/vendor/lib/hw/gralloc.omap4.so" "vendor/lib/hw/"
extract "/vendor/lib/hw/hwcomposer.omap4.so" "vendor/lib/hw/"
extract "/vendor/lib/hw/memtrack.omap4.so" "vendor/lib/hw/"

echo "Extracting camera libraries (DUCATI)..."
extract "/vendor/lib/hw/camera.omap4.so" "vendor/lib/hw/"
extract "/vendor/lib/libcamera.so" "vendor/lib/"
extract "/vendor/lib/libion_ti.so" "vendor/lib/"
extract "/vendor/lib/libipcutils.so" "vendor/lib/"
extract "/vendor/lib/libmm_osal.so" "vendor/lib/"
extract "/vendor/lib/libOMX_Core.so" "vendor/lib/"
extract "/vendor/lib/libOMX.TI.DUCATI1.VIDEO.DECODER.so" "vendor/lib/"
extract "/vendor/lib/libOMX.TI.DUCATI1.VIDEO.DECODER.secure.so" "vendor/lib/"
extract "/vendor/lib/libOMX.TI.DUCATI1.VIDEO.H264E.so" "vendor/lib/"
extract "/vendor/lib/libOMX.TI.DUCATI1.VIDEO.MPEG4E.so" "vendor/lib/"
extract "/vendor/lib/libomx_rpc.so" "vendor/lib/"
extract "/vendor/lib/librcm.so" "vendor/lib/"
extract "/vendor/lib/libsysmgr.so" "vendor/lib/"
extract "/vendor/lib/libtimemmgr.so" "vendor/lib/"

echo "Extracting audio libraries..."
extract "/vendor/lib/hw/audio.primary.omap4.so" "vendor/lib/hw/"
extract "/vendor/lib/libasound.so" "vendor/lib/"

echo "Extracting sensor libraries..."
extract "/vendor/lib/hw/sensors.glass.so" "vendor/lib/hw/"
extract "/vendor/lib/libmllite.so" "vendor/lib/"
extract "/vendor/lib/libmlplatform.so" "vendor/lib/"
extract "/vendor/lib/libmpl.so" "vendor/lib/"

echo "Extracting firmware..."
extract "/vendor/firmware/ducati-m3.bin" "vendor/firmware/"
extract "/vendor/firmware/ti-connectivity/wl12xx-fw-5.bin" "vendor/firmware/ti-connectivity/"
extract "/vendor/firmware/ti-connectivity/wl1271-nvs.bin" "vendor/firmware/ti-connectivity/"
extract "/vendor/firmware/ti-connectivity/TIInit_7.6.15.bts" "vendor/firmware/ti-connectivity/"
extract "/vendor/firmware/bcm4330.hcd" "vendor/firmware/"

echo ""
echo "GlassPorts: Extraction complete!"
echo "Files extracted to: $BASE"
echo ""
echo "Note: Some files may be missing if they were not found on the source."
echo "You may need to obtain these files from an original Glass ROM."

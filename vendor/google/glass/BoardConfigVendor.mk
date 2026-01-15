#
# GlassPorts Vendor Board Configuration
# Google Glass Explorer Edition
#

# Paths to vendor binaries
BOARD_VENDOR_PATH := vendor/google/glass/proprietary

# Graphics
BOARD_EGL_CFG := $(BOARD_VENDOR_PATH)/vendor/lib/egl/egl.cfg

# Camera
TARGET_SPECIFIC_HEADER_PATH := $(BOARD_VENDOR_PATH)/include

# WiFi
WIFI_DRIVER_FW_PATH := $(BOARD_VENDOR_PATH)/vendor/firmware/ti-connectivity

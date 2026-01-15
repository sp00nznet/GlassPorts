#
# GlassPorts Board Configuration
# Google Glass Explorer Edition (Rev 1) - OMAP4430
#

# Board identification
TARGET_BOARD_PLATFORM := omap4
TARGET_BOARD_INFO_FILE := device/google/glass/board-info.txt

# CPU configuration
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_SMP := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := glass
TARGET_NO_BOOTLOADER := false
TARGET_NO_RADIOIMAGE := true

# Kernel configuration
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_CMDLINE := console=ttyO2,115200n8 mem=1G vmalloc=496M
BOARD_KERNEL_CMDLINE += androidboot.console=ttyO2 androidboot.hardware=glass
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x01000000 --tags_offset 0x00000100

# Kernel build
TARGET_KERNEL_SOURCE := kernel/omap
TARGET_KERNEL_CONFIG := glass_defconfig
TARGET_KERNEL_ARCH := arm
BOARD_KERNEL_IMAGE_NAME := zImage

# Partitions
BOARD_BOOTIMAGE_PARTITION_SIZE := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 10485760
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1073741824
BOARD_USERDATAIMAGE_PARTITION_SIZE := 14495514624
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_FLASH_BLOCK_SIZE := 4096

# Filesystem
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4

# Recovery
TARGET_RECOVERY_FSTAB := device/google/glass/init/fstab.glass
BOARD_RECOVERY_SWIPE := true
BOARD_HAS_NO_SELECT_BUTTON := true

# Graphics
USE_OPENGL_RENDERER := true
BOARD_EGL_CFG := device/google/glass/egl/egl.cfg
TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK := true

# Enable dex-preoptimization
WITH_DEXPREOPT := true

# WiFi configuration
BOARD_WLAN_DEVICE := wl12xx_sdio
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_wl12xx
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_wl12xx
WIFI_DRIVER_MODULE_PATH := "/system/lib/modules/wl12xx_sdio.ko"
WIFI_DRIVER_MODULE_NAME := "wl12xx_sdio"
WIFI_DRIVER_MODULE_ARG := ""
WIFI_FIRMWARE_LOADER := ""

# WiFi AP support
BOARD_HAVE_WIFI := true
WIFI_DRIVER_FW_PATH_PARAM := "/sys/module/wl12xx_sdio/parameters/fwlog"
WIFI_DRIVER_FW_PATH_STA := "sta"
WIFI_DRIVER_FW_PATH_AP := "ap"
WIFI_DRIVER_FW_PATH_P2P := "p2p"
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true

# Bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_TI := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/google/glass/bluetooth

# Audio
BOARD_USES_ALSA_AUDIO := true
BOARD_USES_GENERIC_AUDIO := false
TARGET_USES_QCOM_MM_AUDIO := false
BOARD_USES_TI_OMAP4_HARDWARE := true

# Camera
USE_CAMERA_STUB := false
BOARD_USES_TI_CAMERA_HAL := true

# Sensors
BOARD_USES_GLASS_SENSORS := true

# SELinux
BOARD_SEPOLICY_DIRS += device/google/glass/sepolicy

# Vendor
BOARD_VENDOR := google
BOARD_VENDOR_USE_AKMD := false

# HIDL
DEVICE_MANIFEST_FILE := device/google/glass/manifest.xml
DEVICE_MATRIX_FILE := device/google/glass/compatibility_matrix.xml

# OTA
TARGET_OTA_ASSERT_DEVICE := glass,Glass

# Build flags
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true

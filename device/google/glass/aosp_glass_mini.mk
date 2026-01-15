#
# GlassPorts Mini - Minimal Product Configuration
# Stripped down version with only essential components
#

# Inherit device configuration
$(call inherit-product, device/google/glass/device.mk)

# Inherit minimal AOSP configuration
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_minimal.mk)

# Product identifiers
PRODUCT_NAME := aosp_glass_mini
PRODUCT_DEVICE := glass
PRODUCT_BRAND := google
PRODUCT_MODEL := Glass Explorer Edition (Mini)
PRODUCT_MANUFACTURER := Google

# Remove even more packages for minimal build
PRODUCT_PACKAGES_REMOVE := \
    Browser2 \
    Calendar \
    Camera2 \
    Contacts \
    DeskClock \
    Dialer \
    DocumentsUI \
    DownloadProvider \
    Email \
    ExactCalculator \
    Gallery2 \
    Music \
    MusicFX \
    QuickSearchBox \
    Telecom \
    TeleService

# Only essential packages
PRODUCT_PACKAGES += \
    GlassLauncher \
    GlassSettings \
    GlassWifiApService

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=glass_mini \
    BUILD_FINGERPRINT="google/glass/glass:$(PLATFORM_VERSION)/$(BUILD_ID)/$(BUILD_NUMBER):userdebug/dev-keys" \
    PRIVATE_BUILD_DESC="glass-mini-userdebug $(PLATFORM_VERSION) $(BUILD_ID) $(BUILD_NUMBER) dev-keys"

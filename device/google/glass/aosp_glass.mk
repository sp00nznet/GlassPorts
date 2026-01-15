#
# GlassPorts - Full Product Configuration
# Google Glass Explorer Edition
#

# Inherit device configuration
$(call inherit-product, device/google/glass/device.mk)

# Inherit AOSP configuration
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Product identifiers
PRODUCT_NAME := aosp_glass
PRODUCT_DEVICE := glass
PRODUCT_BRAND := google
PRODUCT_MODEL := Glass Explorer Edition
PRODUCT_MANUFACTURER := Google

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=glass \
    BUILD_FINGERPRINT="google/glass/glass:$(PLATFORM_VERSION)/$(BUILD_ID)/$(BUILD_NUMBER):userdebug/dev-keys" \
    PRIVATE_BUILD_DESC="glass-userdebug $(PLATFORM_VERSION) $(BUILD_ID) $(BUILD_NUMBER) dev-keys"

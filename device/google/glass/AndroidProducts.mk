#
# GlassPorts - Google Glass Device Configuration
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/aosp_glass.mk \
    $(LOCAL_DIR)/aosp_glass_mini.mk

COMMON_LUNCH_CHOICES := \
    aosp_glass-userdebug \
    aosp_glass-eng \
    aosp_glass_mini-userdebug

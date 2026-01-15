#
# GlassPorts Vendor Configuration
# Binary blob wrappers and proprietary files for Google Glass
#

# Call vendor setup
$(call inherit-product-if-exists, vendor/google/glass/device-vendor.mk)

# Proprietary files
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,vendor/google/glass/proprietary/vendor,$(TARGET_COPY_OUT_VENDOR))

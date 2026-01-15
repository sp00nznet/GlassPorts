#
# GlassPorts Device Vendor Configuration
# Google Glass Explorer Edition
#

LOCAL_PATH := vendor/google/glass

# Graphics - PowerVR SGX540
PRODUCT_PACKAGES += \
    libEGL_POWERVR_SGX540_120 \
    libGLESv1_CM_POWERVR_SGX540_120 \
    libGLESv2_POWERVR_SGX540_120 \
    libglslcompiler \
    libIMGegl \
    libpvr2d \
    libpvrANDROID_WSEGL \
    libPVRScopeServices \
    libsrv_init \
    libsrv_um \
    libusc \
    gralloc.omap4.so \
    hwcomposer.omap4.so \
    memtrack.omap4.so

# Camera - TI DUCATI
PRODUCT_PACKAGES += \
    camera.omap4.so \
    libcamera \
    libion_ti \
    libipcutils \
    libmm_osal \
    libOMX_Core \
    libOMX.TI.DUCATI1.VIDEO.DECODER \
    libOMX.TI.DUCATI1.VIDEO.DECODER.secure \
    libOMX.TI.DUCATI1.VIDEO.H264E \
    libOMX.TI.DUCATI1.VIDEO.MPEG4E \
    libomx_rpc \
    librcm \
    libsysmgr \
    libtimemmgr

# Audio - ABE
PRODUCT_PACKAGES += \
    audio.primary.omap4.so \
    libasound \
    libaudioutils \
    libtinyalsa

# Sensors
PRODUCT_PACKAGES += \
    sensors.glass.so \
    libmllite \
    libmlplatform \
    libmpl

# WiFi - TI WiLink
PRODUCT_PACKAGES += \
    wl12xx-fw-5.bin \
    wl1271-nvs.bin \
    TIInit_7.6.15.bts

# Bluetooth
PRODUCT_PACKAGES += \
    bcm4330.hcd

# Firmware
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/proprietary/vendor/firmware/ducati-m3.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/ducati-m3.bin \
    $(LOCAL_PATH)/proprietary/vendor/firmware/wl12xx-fw-5.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/ti-connectivity/wl12xx-fw-5.bin \
    $(LOCAL_PATH)/proprietary/vendor/firmware/wl1271-nvs.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/ti-connectivity/wl1271-nvs.bin \
    $(LOCAL_PATH)/proprietary/vendor/firmware/TIInit_7.6.15.bts:$(TARGET_COPY_OUT_VENDOR)/firmware/ti-connectivity/TIInit_7.6.15.bts \
    $(LOCAL_PATH)/proprietary/vendor/firmware/bcm4330.hcd:$(TARGET_COPY_OUT_VENDOR)/firmware/bcm4330.hcd

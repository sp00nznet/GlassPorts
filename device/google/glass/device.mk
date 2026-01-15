#
# GlassPorts Device Configuration
# Google Glass Explorer Edition (Rev 1)
#
# Hardware Specs:
#   - SoC: Texas Instruments OMAP4430 (dual-core ARM Cortex-A9 @ 1.0 GHz)
#   - RAM: 1GB LPDDR2
#   - Storage: 16GB eMMC
#   - Display: LCoS 640x360 (equivalent to 25" HD from 8 feet)
#   - WiFi: 802.11 b/g
#   - Bluetooth: 4.0 + BLE
#   - Camera: 5MP stills / 720p video
#   - Battery: 570 mAh
#

LOCAL_PATH := device/google/glass

# Device identifier
PRODUCT_DEVICE := glass
PRODUCT_NAME := aosp_glass
PRODUCT_BRAND := google
PRODUCT_MODEL := Glass 1
PRODUCT_MANUFACTURER := Google

# Hardware features
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.camera.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml

# Glass-specific permissions
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/permissions/com.google.glass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.google.glass.xml

# Display configuration
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := hdpi
PRODUCT_CHARACTERISTICS := nosdcard

# Screen density
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=213 \
    ro.opengles.version=131072

# Audio configuration
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_policy.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy.conf \
    $(LOCAL_PATH)/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml

# Media configuration
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    $(LOCAL_PATH)/media/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles.xml

# WiFi configuration
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/wifi/wpa_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    $(LOCAL_PATH)/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf

# WiFi Access Point configuration (GlassPorts feature)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/wifi/hostapd.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/hostapd.conf

# Keylayout
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/glass-touchpad.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/glass-touchpad.kl \
    $(LOCAL_PATH)/keylayout/gpio-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/gpio-keys.kl

# Init scripts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/init.glass.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.glass.rc \
    $(LOCAL_PATH)/init/init.glass.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.glass.usb.rc \
    $(LOCAL_PATH)/init/ueventd.glass.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.glass.rc \
    $(LOCAL_PATH)/init/fstab.glass:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.glass

# Overlays
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# GlassPorts packages
PRODUCT_PACKAGES += \
    GlassLauncher \
    GlassSettings \
    GlassWifiApService

# WiFi packages
PRODUCT_PACKAGES += \
    hostapd \
    wpa_supplicant \
    wpa_supplicant.conf \
    libwpa_client

# WiFi AP service
PRODUCT_PACKAGES += \
    android.hardware.wifi.hostapd@1.0-service

# Graphics
PRODUCT_PACKAGES += \
    libGLES_android

# Audio
PRODUCT_PACKAGES += \
    audio.a2dp.default \
    audio.primary.omap4 \
    audio.r_submix.default \
    audio.usb.default

# Camera
PRODUCT_PACKAGES += \
    camera.omap4

# Bluetooth
PRODUCT_PACKAGES += \
    bluetooth.default \
    libbt-vendor

# Sensors
PRODUCT_PACKAGES += \
    sensors.glass

# Enable sideloading by default (GlassPorts feature)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0 \
    persist.sys.usb.config=mtp,adb \
    ro.secure=0 \
    ro.debuggable=1

# WiFi AP default settings
PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0 \
    wifi.ap.interface=wlan0 \
    ro.wifi.ap.ssid=GlassPorts \
    ro.wifi.ap.enabled=0

# System properties
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapsize=512m \
    dalvik.vm.heapgrowthlimit=128m \
    dalvik.vm.heapminfree=2m \
    dalvik.vm.heaptargetutilization=0.75

# Low memory optimizations for Glass hardware
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.low_ram=false \
    ro.sys.fw.bg_apps_limit=4

# Strip unnecessary system UI components
PRODUCT_PROPERTY_OVERRIDES += \
    ro.lockscreen.disable.default=true \
    ro.setupwizard.mode=DISABLED

# Inherit from vendor
$(call inherit-product-if-exists, vendor/google/glass/glass-vendor.mk)

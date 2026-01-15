#
# GlassPorts Minimal Launcher
# A simple launcher designed for Google Glass
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := optional
LOCAL_PACKAGE_NAME := GlassLauncher
LOCAL_CERTIFICATE := platform
LOCAL_PRIVILEGED_MODULE := true
LOCAL_OVERRIDES_PACKAGES := Launcher2 Launcher3 Home

LOCAL_SRC_FILES := $(call all-java-files-under, src)

LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/res

LOCAL_STATIC_ANDROID_LIBRARIES := \
    androidx.core_core \
    androidx.recyclerview_recyclerview

LOCAL_USE_AAPT2 := true

LOCAL_PROGUARD_ENABLED := disabled

include $(BUILD_PACKAGE)

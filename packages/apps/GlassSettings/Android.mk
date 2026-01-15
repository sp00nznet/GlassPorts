#
# GlassPorts Settings
# Minimal settings app for Google Glass
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := optional
LOCAL_PACKAGE_NAME := GlassSettings
LOCAL_CERTIFICATE := platform
LOCAL_PRIVILEGED_MODULE := true

LOCAL_SRC_FILES := $(call all-java-files-under, src)

LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/res

LOCAL_STATIC_ANDROID_LIBRARIES := \
    androidx.core_core \
    androidx.recyclerview_recyclerview \
    androidx.preference_preference

LOCAL_USE_AAPT2 := true

LOCAL_PROGUARD_ENABLED := disabled

include $(BUILD_PACKAGE)

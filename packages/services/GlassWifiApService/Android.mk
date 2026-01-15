#
# GlassPorts WiFi Access Point Service
# Manages WiFi AP mode for Google Glass
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := GlassWifiApService
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := JAVA_LIBRARIES

LOCAL_SRC_FILES := $(call all-java-files-under, src)

LOCAL_JAVA_LIBRARIES := \
    framework \
    services

LOCAL_STATIC_JAVA_LIBRARIES := \
    android-support-v4

LOCAL_CERTIFICATE := platform
LOCAL_PRIVILEGED_MODULE := true

include $(BUILD_JAVA_LIBRARY)

# Also build the native helper
include $(CLEAR_VARS)

LOCAL_MODULE := libglasswifiap
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES

LOCAL_SRC_FILES := \
    jni/wifi_ap_control.c

LOCAL_C_INCLUDES := \
    $(JNI_H_INCLUDE) \
    system/core/include

LOCAL_SHARED_LIBRARIES := \
    liblog \
    libcutils \
    libnativehelper

LOCAL_CFLAGS := -Wall -Werror

include $(BUILD_SHARED_LIBRARY)

/*
 * GlassPorts WiFi AP Native Control
 * JNI wrapper for low-level WiFi AP operations
 */

#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/wireless.h>

#define LOG_TAG "GlassWifiApJNI"
#include <cutils/log.h>
#include <cutils/properties.h>

#define WIFI_AP_INTERFACE "wlan0"
#define HOSTAPD_CONF_FILE "/data/misc/wifi/hostapd/hostapd.conf"

/*
 * Write hostapd configuration file
 */
static int write_hostapd_config(const char *ssid, const char *password, int channel) {
    FILE *fp = fopen(HOSTAPD_CONF_FILE, "w");
    if (fp == NULL) {
        ALOGE("Failed to open hostapd config file");
        return -1;
    }

    fprintf(fp, "# GlassPorts WiFi AP Configuration\n");
    fprintf(fp, "interface=%s\n", WIFI_AP_INTERFACE);
    fprintf(fp, "driver=nl80211\n");
    fprintf(fp, "ctrl_interface=/data/misc/wifi/hostapd\n");
    fprintf(fp, "ssid=%s\n", ssid);
    fprintf(fp, "channel=%d\n", channel);
    fprintf(fp, "hw_mode=g\n");
    fprintf(fp, "ieee80211n=1\n");
    fprintf(fp, "wmm_enabled=1\n");
    fprintf(fp, "wpa=2\n");
    fprintf(fp, "wpa_key_mgmt=WPA-PSK\n");
    fprintf(fp, "wpa_pairwise=CCMP\n");
    fprintf(fp, "rsn_pairwise=CCMP\n");
    fprintf(fp, "wpa_passphrase=%s\n", password);
    fprintf(fp, "max_num_sta=4\n");
    fprintf(fp, "ignore_broadcast_ssid=0\n");

    fclose(fp);
    ALOGI("Wrote hostapd config: ssid=%s, channel=%d", ssid, channel);
    return 0;
}

/*
 * Check if interface is up
 */
static int is_interface_up(const char *ifname) {
    int sock;
    struct ifreq ifr;

    sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        return 0;
    }

    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, ifname, IFNAMSIZ - 1);

    if (ioctl(sock, SIOCGIFFLAGS, &ifr) < 0) {
        close(sock);
        return 0;
    }

    close(sock);
    return (ifr.ifr_flags & IFF_UP) != 0;
}

/*
 * Set interface up/down
 */
static int set_interface_up(const char *ifname, int up) {
    int sock;
    struct ifreq ifr;

    sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        ALOGE("Failed to create socket");
        return -1;
    }

    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, ifname, IFNAMSIZ - 1);

    if (ioctl(sock, SIOCGIFFLAGS, &ifr) < 0) {
        ALOGE("Failed to get interface flags");
        close(sock);
        return -1;
    }

    if (up) {
        ifr.ifr_flags |= IFF_UP;
    } else {
        ifr.ifr_flags &= ~IFF_UP;
    }

    if (ioctl(sock, SIOCSIFFLAGS, &ifr) < 0) {
        ALOGE("Failed to set interface flags");
        close(sock);
        return -1;
    }

    close(sock);
    ALOGI("Interface %s %s", ifname, up ? "up" : "down");
    return 0;
}

/*
 * JNI: Configure and start WiFi AP
 */
JNIEXPORT jboolean JNICALL
Java_com_glassports_wifiap_WifiApNative_startWifiAp(
        JNIEnv *env, jclass clazz, jstring ssid, jstring password, jint channel) {

    const char *ssid_str = (*env)->GetStringUTFChars(env, ssid, NULL);
    const char *pass_str = (*env)->GetStringUTFChars(env, password, NULL);

    ALOGI("Starting WiFi AP: ssid=%s, channel=%d", ssid_str, channel);

    /* Write configuration */
    if (write_hostapd_config(ssid_str, pass_str, channel) < 0) {
        (*env)->ReleaseStringUTFChars(env, ssid, ssid_str);
        (*env)->ReleaseStringUTFChars(env, password, pass_str);
        return JNI_FALSE;
    }

    /* Set system property to trigger hostapd start */
    property_set("sys.wifi.ap.enabled", "1");

    (*env)->ReleaseStringUTFChars(env, ssid, ssid_str);
    (*env)->ReleaseStringUTFChars(env, password, pass_str);

    return JNI_TRUE;
}

/*
 * JNI: Stop WiFi AP
 */
JNIEXPORT jboolean JNICALL
Java_com_glassports_wifiap_WifiApNative_stopWifiAp(JNIEnv *env, jclass clazz) {
    ALOGI("Stopping WiFi AP");

    /* Set system property to trigger hostapd stop */
    property_set("sys.wifi.ap.enabled", "0");

    return JNI_TRUE;
}

/*
 * JNI: Check if WiFi AP is running
 */
JNIEXPORT jboolean JNICALL
Java_com_glassports_wifiap_WifiApNative_isWifiApRunning(JNIEnv *env, jclass clazz) {
    char value[PROPERTY_VALUE_MAX];
    property_get("sys.wifi.ap.enabled", value, "0");
    return strcmp(value, "1") == 0 ? JNI_TRUE : JNI_FALSE;
}

/*
 * JNI: Get connected station count
 */
JNIEXPORT jint JNICALL
Java_com_glassports_wifiap_WifiApNative_getConnectedStationCount(JNIEnv *env, jclass clazz) {
    /* Read from hostapd control interface */
    /* For now, return 0 */
    return 0;
}

/*
 * JNI native method registration
 */
static JNINativeMethod gMethods[] = {
    {"startWifiAp", "(Ljava/lang/String;Ljava/lang/String;I)Z",
            (void *)Java_com_glassports_wifiap_WifiApNative_startWifiAp},
    {"stopWifiAp", "()Z",
            (void *)Java_com_glassports_wifiap_WifiApNative_stopWifiAp},
    {"isWifiApRunning", "()Z",
            (void *)Java_com_glassports_wifiap_WifiApNative_isWifiApRunning},
    {"getConnectedStationCount", "()I",
            (void *)Java_com_glassports_wifiap_WifiApNative_getConnectedStationCount},
};

/*
 * JNI_OnLoad - Register native methods
 */
JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    JNIEnv *env;

    if ((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }

    jclass clazz = (*env)->FindClass(env, "com/glassports/wifiap/WifiApNative");
    if (clazz == NULL) {
        return JNI_ERR;
    }

    if ((*env)->RegisterNatives(env, clazz, gMethods,
            sizeof(gMethods) / sizeof(gMethods[0])) < 0) {
        return JNI_ERR;
    }

    return JNI_VERSION_1_6;
}

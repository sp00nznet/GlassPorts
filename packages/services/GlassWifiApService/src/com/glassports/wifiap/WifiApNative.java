/*
 * GlassPorts WiFi AP Native Interface
 * JNI bindings for native WiFi AP control
 */

package com.glassports.wifiap;

/**
 * Native interface for low-level WiFi AP control.
 */
public class WifiApNative {
    private static final String TAG = "GlassWifiApNative";

    static {
        System.loadLibrary("glasswifiap");
    }

    /**
     * Start WiFi AP with specified configuration
     *
     * @param ssid     Network name
     * @param password Network password
     * @param channel  WiFi channel (1-11)
     * @return true if AP started successfully
     */
    public static native boolean startWifiAp(String ssid, String password, int channel);

    /**
     * Stop WiFi AP
     *
     * @return true if AP stopped successfully
     */
    public static native boolean stopWifiAp();

    /**
     * Check if WiFi AP is currently running
     *
     * @return true if AP is running
     */
    public static native boolean isWifiApRunning();

    /**
     * Get number of connected stations
     *
     * @return number of connected clients
     */
    public static native int getConnectedStationCount();
}

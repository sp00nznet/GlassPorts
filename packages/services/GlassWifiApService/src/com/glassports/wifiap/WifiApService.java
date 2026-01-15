/*
 * GlassPorts WiFi Access Point Service
 * Manages WiFi AP mode for Google Glass
 */

package com.glassports.wifiap;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiManager;
import android.os.Binder;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.Message;
import android.os.SystemProperties;
import android.util.Log;

import java.lang.reflect.Method;

/**
 * Service for managing WiFi Access Point mode on Google Glass.
 * Provides functionality to enable/disable WiFi AP and configure AP settings.
 */
public class WifiApService extends Service {
    private static final String TAG = "GlassWifiApService";

    // Actions
    public static final String ACTION_WIFI_AP_STATE_CHANGED =
            "com.glassports.wifiap.WIFI_AP_STATE_CHANGED";
    public static final String ACTION_WIFI_AP_ENABLE =
            "com.glassports.wifiap.WIFI_AP_ENABLE";
    public static final String ACTION_WIFI_AP_DISABLE =
            "com.glassports.wifiap.WIFI_AP_DISABLE";

    // Extras
    public static final String EXTRA_WIFI_AP_STATE = "wifi_ap_state";
    public static final String EXTRA_WIFI_AP_SSID = "wifi_ap_ssid";
    public static final String EXTRA_WIFI_AP_PASSWORD = "wifi_ap_password";

    // States
    public static final int WIFI_AP_STATE_DISABLING = 10;
    public static final int WIFI_AP_STATE_DISABLED = 11;
    public static final int WIFI_AP_STATE_ENABLING = 12;
    public static final int WIFI_AP_STATE_ENABLED = 13;
    public static final int WIFI_AP_STATE_FAILED = 14;

    // System properties
    private static final String PROP_WIFI_AP_ENABLED = "sys.wifi.ap.enabled";
    private static final String PROP_WIFI_AP_SSID = "ro.wifi.ap.ssid";

    private WifiManager mWifiManager;
    private int mWifiApState = WIFI_AP_STATE_DISABLED;
    private WifiConfiguration mApConfig;
    private Handler mHandler;

    private final IBinder mBinder = new WifiApBinder();

    /**
     * Binder class for local service binding
     */
    public class WifiApBinder extends Binder {
        public WifiApService getService() {
            return WifiApService.this;
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "GlassPorts WiFi AP Service starting");

        mWifiManager = (WifiManager) getSystemService(Context.WIFI_SERVICE);
        mHandler = new ApHandler(Looper.getMainLooper());

        // Initialize default AP configuration
        initApConfig();

        // Register broadcast receiver
        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_WIFI_AP_ENABLE);
        filter.addAction(ACTION_WIFI_AP_DISABLE);
        filter.addAction(WifiManager.WIFI_STATE_CHANGED_ACTION);
        registerReceiver(mReceiver, filter);

        Log.i(TAG, "GlassPorts WiFi AP Service started");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        unregisterReceiver(mReceiver);
        Log.i(TAG, "GlassPorts WiFi AP Service stopped");
    }

    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            String action = intent.getAction();
            if (ACTION_WIFI_AP_ENABLE.equals(action)) {
                String ssid = intent.getStringExtra(EXTRA_WIFI_AP_SSID);
                String password = intent.getStringExtra(EXTRA_WIFI_AP_PASSWORD);
                enableWifiAp(ssid, password);
            } else if (ACTION_WIFI_AP_DISABLE.equals(action)) {
                disableWifiAp();
            }
        }
        return START_STICKY;
    }

    /**
     * Initialize default AP configuration
     */
    private void initApConfig() {
        mApConfig = new WifiConfiguration();
        mApConfig.SSID = SystemProperties.get(PROP_WIFI_AP_SSID, "GlassPorts");
        mApConfig.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK);
        mApConfig.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.OPEN);
        mApConfig.preSharedKey = "glassports";
    }

    /**
     * Enable WiFi Access Point mode
     *
     * @param ssid     SSID for the AP (null for default)
     * @param password Password for the AP (null for default)
     * @return true if AP is being enabled
     */
    public boolean enableWifiAp(String ssid, String password) {
        Log.i(TAG, "Enabling WiFi AP mode");

        // Update configuration if provided
        if (ssid != null && !ssid.isEmpty()) {
            mApConfig.SSID = ssid;
        }
        if (password != null && password.length() >= 8) {
            mApConfig.preSharedKey = password;
        }

        // Disable WiFi client mode first
        if (mWifiManager.isWifiEnabled()) {
            Log.d(TAG, "Disabling WiFi client mode");
            mWifiManager.setWifiEnabled(false);
        }

        // Enable AP mode
        boolean result = setWifiApEnabled(mApConfig, true);
        if (result) {
            setWifiApState(WIFI_AP_STATE_ENABLING);
            SystemProperties.set(PROP_WIFI_AP_ENABLED, "1");
        }

        return result;
    }

    /**
     * Disable WiFi Access Point mode
     *
     * @return true if AP is being disabled
     */
    public boolean disableWifiAp() {
        Log.i(TAG, "Disabling WiFi AP mode");

        boolean result = setWifiApEnabled(null, false);
        if (result) {
            setWifiApState(WIFI_AP_STATE_DISABLING);
            SystemProperties.set(PROP_WIFI_AP_ENABLED, "0");
        }

        return result;
    }

    /**
     * Check if WiFi AP is currently enabled
     *
     * @return true if AP is enabled
     */
    public boolean isWifiApEnabled() {
        return mWifiApState == WIFI_AP_STATE_ENABLED;
    }

    /**
     * Get current WiFi AP state
     *
     * @return current state
     */
    public int getWifiApState() {
        return mWifiApState;
    }

    /**
     * Get current AP configuration
     *
     * @return WifiConfiguration for current AP
     */
    public WifiConfiguration getWifiApConfiguration() {
        return mApConfig;
    }

    /**
     * Update AP configuration
     *
     * @param ssid     new SSID
     * @param password new password
     */
    public void setWifiApConfiguration(String ssid, String password) {
        if (ssid != null && !ssid.isEmpty()) {
            mApConfig.SSID = ssid;
        }
        if (password != null && password.length() >= 8) {
            mApConfig.preSharedKey = password;
        }
    }

    /**
     * Use reflection to call setWifiApEnabled on WifiManager
     */
    private boolean setWifiApEnabled(WifiConfiguration config, boolean enabled) {
        try {
            Method method = mWifiManager.getClass().getMethod(
                    "setWifiApEnabled", WifiConfiguration.class, boolean.class);
            return (Boolean) method.invoke(mWifiManager, config, enabled);
        } catch (Exception e) {
            Log.e(TAG, "Failed to set WiFi AP enabled: " + e.getMessage());
            return false;
        }
    }

    /**
     * Update and broadcast WiFi AP state
     */
    private void setWifiApState(int state) {
        mWifiApState = state;

        Intent intent = new Intent(ACTION_WIFI_AP_STATE_CHANGED);
        intent.putExtra(EXTRA_WIFI_AP_STATE, state);
        sendBroadcast(intent);
    }

    /**
     * Broadcast receiver for WiFi events
     */
    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            if (ACTION_WIFI_AP_ENABLE.equals(action)) {
                String ssid = intent.getStringExtra(EXTRA_WIFI_AP_SSID);
                String password = intent.getStringExtra(EXTRA_WIFI_AP_PASSWORD);
                enableWifiAp(ssid, password);
            } else if (ACTION_WIFI_AP_DISABLE.equals(action)) {
                disableWifiAp();
            } else if (WifiManager.WIFI_STATE_CHANGED_ACTION.equals(action)) {
                // Handle WiFi state changes if needed
            }
        }
    };

    /**
     * Handler for AP state transitions
     */
    private class ApHandler extends Handler {
        public ApHandler(Looper looper) {
            super(looper);
        }

        @Override
        public void handleMessage(Message msg) {
            // Handle state transition messages
        }
    }
}

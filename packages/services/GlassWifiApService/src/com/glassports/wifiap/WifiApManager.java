/*
 * GlassPorts WiFi Access Point Manager
 * Helper class for managing WiFi AP from other apps
 */

package com.glassports.wifiap;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

/**
 * Manager class for controlling WiFi AP mode from applications.
 * Provides a simple interface to the WifiApService.
 */
public class WifiApManager {
    private static final String TAG = "GlassWifiApManager";

    private Context mContext;
    private WifiApService mService;
    private boolean mBound = false;

    /**
     * Listener interface for WiFi AP state changes
     */
    public interface WifiApStateListener {
        void onWifiApStateChanged(int state);
    }

    private WifiApStateListener mListener;

    /**
     * Create a new WifiApManager
     *
     * @param context Application context
     */
    public WifiApManager(Context context) {
        mContext = context.getApplicationContext();
    }

    /**
     * Bind to the WifiApService
     */
    public void bind() {
        Intent intent = new Intent(mContext, WifiApService.class);
        mContext.bindService(intent, mConnection, Context.BIND_AUTO_CREATE);
    }

    /**
     * Unbind from the WifiApService
     */
    public void unbind() {
        if (mBound) {
            mContext.unbindService(mConnection);
            mBound = false;
        }
    }

    /**
     * Enable WiFi AP with default settings
     *
     * @return true if request was sent
     */
    public boolean enableWifiAp() {
        return enableWifiAp(null, null);
    }

    /**
     * Enable WiFi AP with custom settings
     *
     * @param ssid     SSID for the AP
     * @param password Password for the AP (min 8 characters)
     * @return true if request was sent
     */
    public boolean enableWifiAp(String ssid, String password) {
        if (mBound && mService != null) {
            return mService.enableWifiAp(ssid, password);
        }

        // Send broadcast if not bound
        Intent intent = new Intent(WifiApService.ACTION_WIFI_AP_ENABLE);
        if (ssid != null) {
            intent.putExtra(WifiApService.EXTRA_WIFI_AP_SSID, ssid);
        }
        if (password != null) {
            intent.putExtra(WifiApService.EXTRA_WIFI_AP_PASSWORD, password);
        }
        mContext.sendBroadcast(intent);
        return true;
    }

    /**
     * Disable WiFi AP
     *
     * @return true if request was sent
     */
    public boolean disableWifiAp() {
        if (mBound && mService != null) {
            return mService.disableWifiAp();
        }

        // Send broadcast if not bound
        Intent intent = new Intent(WifiApService.ACTION_WIFI_AP_DISABLE);
        mContext.sendBroadcast(intent);
        return true;
    }

    /**
     * Check if WiFi AP is currently enabled
     *
     * @return true if AP is enabled, false otherwise
     */
    public boolean isWifiApEnabled() {
        if (mBound && mService != null) {
            return mService.isWifiApEnabled();
        }
        return false;
    }

    /**
     * Get current WiFi AP state
     *
     * @return current state constant
     */
    public int getWifiApState() {
        if (mBound && mService != null) {
            return mService.getWifiApState();
        }
        return WifiApService.WIFI_AP_STATE_DISABLED;
    }

    /**
     * Set listener for WiFi AP state changes
     *
     * @param listener Listener to receive state changes
     */
    public void setWifiApStateListener(WifiApStateListener listener) {
        mListener = listener;
    }

    /**
     * Service connection callbacks
     */
    private final ServiceConnection mConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            Log.d(TAG, "Connected to WifiApService");
            WifiApService.WifiApBinder binder = (WifiApService.WifiApBinder) service;
            mService = binder.getService();
            mBound = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            Log.d(TAG, "Disconnected from WifiApService");
            mService = null;
            mBound = false;
        }
    };
}

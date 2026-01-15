/*
 * GlassPorts WiFi AP Settings
 * Toggle and configure WiFi Access Point mode
 */

package com.glassports.settings;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.SystemProperties;
import android.text.InputType;
import android.view.GestureDetector;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Switch;
import android.widget.TextView;

import java.lang.reflect.Method;

/**
 * WiFi Access Point Settings
 * Allows users to enable/disable WiFi AP and configure SSID/password
 */
public class WifiApSettingsActivity extends Activity implements
        GestureDetector.OnGestureListener {

    private static final String TAG = "GlassWifiApSettings";
    private static final String PROP_WIFI_AP_SSID = "ro.wifi.ap.ssid";

    private WifiManager mWifiManager;
    private GestureDetector mGestureDetector;
    private Handler mHandler;

    private Switch mApSwitch;
    private TextView mStatusText;
    private TextView mSsidText;
    private TextView mPasswordText;
    private ImageView mStatusIcon;

    private String mSsid = "GlassPorts";
    private String mPassword = "glassports";
    private boolean mApEnabled = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_wifi_ap_settings);

        mWifiManager = (WifiManager) getSystemService(Context.WIFI_SERVICE);
        mGestureDetector = new GestureDetector(this, this);
        mHandler = new Handler();

        mApSwitch = findViewById(R.id.wifi_ap_switch);
        mStatusText = findViewById(R.id.wifi_ap_status);
        mSsidText = findViewById(R.id.wifi_ap_ssid);
        mPasswordText = findViewById(R.id.wifi_ap_password);
        mStatusIcon = findViewById(R.id.wifi_ap_icon);

        // Load saved SSID
        mSsid = SystemProperties.get(PROP_WIFI_AP_SSID, "GlassPorts");

        // Setup switch listener
        mApSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                enableWifiAp();
            } else {
                disableWifiAp();
            }
        });

        // Setup SSID click
        findViewById(R.id.ssid_row).setOnClickListener(v -> showSsidDialog());

        // Setup password click
        findViewById(R.id.password_row).setOnClickListener(v -> showPasswordDialog());

        updateState();

        // Register for WiFi AP state changes
        IntentFilter filter = new IntentFilter("android.net.wifi.WIFI_AP_STATE_CHANGED");
        registerReceiver(mReceiver, filter);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(mReceiver);
    }

    /**
     * Update UI state
     */
    private void updateState() {
        mApEnabled = isWifiApEnabled();
        mApSwitch.setChecked(mApEnabled);

        if (mApEnabled) {
            mStatusText.setText(R.string.wifi_ap_on);
            mStatusIcon.setImageResource(R.drawable.ic_wifi_tethering_on);
        } else {
            mStatusText.setText(R.string.wifi_ap_off);
            mStatusIcon.setImageResource(R.drawable.ic_wifi_tethering);
        }

        mSsidText.setText(mSsid);
        mPasswordText.setText(maskPassword(mPassword));
    }

    /**
     * Mask password for display
     */
    private String maskPassword(String password) {
        if (password == null || password.length() == 0) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < password.length(); i++) {
            sb.append('*');
        }
        return sb.toString();
    }

    /**
     * Enable WiFi AP
     */
    private void enableWifiAp() {
        // Disable WiFi client mode first
        if (mWifiManager.isWifiEnabled()) {
            mWifiManager.setWifiEnabled(false);
        }

        WifiConfiguration config = new WifiConfiguration();
        config.SSID = mSsid;
        config.preSharedKey = mPassword;
        config.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK);

        setWifiApEnabled(config, true);
        mStatusText.setText(R.string.wifi_ap_enabling);
    }

    /**
     * Disable WiFi AP
     */
    private void disableWifiAp() {
        setWifiApEnabled(null, false);
        mStatusText.setText(R.string.wifi_ap_disabling);
    }

    /**
     * Use reflection to call setWifiApEnabled
     */
    private boolean setWifiApEnabled(WifiConfiguration config, boolean enabled) {
        try {
            Method method = mWifiManager.getClass().getMethod(
                    "setWifiApEnabled", WifiConfiguration.class, boolean.class);
            return (Boolean) method.invoke(mWifiManager, config, enabled);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Check if WiFi AP is enabled using reflection
     */
    private boolean isWifiApEnabled() {
        try {
            Method method = mWifiManager.getClass().getMethod("isWifiApEnabled");
            return (Boolean) method.invoke(mWifiManager);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Show SSID configuration dialog
     */
    private void showSsidDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.wifi_ap_ssid_title);

        final EditText input = new EditText(this);
        input.setInputType(InputType.TYPE_CLASS_TEXT);
        input.setText(mSsid);
        builder.setView(input);

        builder.setPositiveButton(android.R.string.ok, (dialog, which) -> {
            String newSsid = input.getText().toString().trim();
            if (!newSsid.isEmpty()) {
                mSsid = newSsid;
                updateState();

                // If AP is enabled, restart with new config
                if (mApEnabled) {
                    disableWifiAp();
                    mHandler.postDelayed(this::enableWifiAp, 1000);
                }
            }
        });

        builder.setNegativeButton(android.R.string.cancel, null);
        builder.show();
    }

    /**
     * Show password configuration dialog
     */
    private void showPasswordDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.wifi_ap_password_title);

        final EditText input = new EditText(this);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        input.setText(mPassword);
        builder.setView(input);

        builder.setPositiveButton(android.R.string.ok, (dialog, which) -> {
            String newPassword = input.getText().toString();
            if (newPassword.length() >= 8) {
                mPassword = newPassword;
                updateState();

                // If AP is enabled, restart with new config
                if (mApEnabled) {
                    disableWifiAp();
                    mHandler.postDelayed(this::enableWifiAp, 1000);
                }
            }
        });

        builder.setNegativeButton(android.R.string.cancel, null);
        builder.show();
    }

    /**
     * Broadcast receiver for WiFi AP state changes
     */
    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            int state = intent.getIntExtra("wifi_state", -1);
            mHandler.post(() -> updateState());
        }
    };

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return mGestureDetector.onTouchEvent(event) || super.onTouchEvent(event);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            finish();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    // GestureDetector callbacks
    @Override
    public boolean onDown(MotionEvent e) {
        return true;
    }

    @Override
    public void onShowPress(MotionEvent e) {
    }

    @Override
    public boolean onSingleTapUp(MotionEvent e) {
        mApSwitch.toggle();
        return true;
    }

    @Override
    public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
        return false;
    }

    @Override
    public void onLongPress(MotionEvent e) {
    }

    @Override
    public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY) {
        if (e1 == null || e2 == null) {
            return false;
        }

        float diffY = e2.getY() - e1.getY();
        if (diffY > 100 && Math.abs(velocityY) > 100) {
            finish();
            return true;
        }
        return false;
    }
}

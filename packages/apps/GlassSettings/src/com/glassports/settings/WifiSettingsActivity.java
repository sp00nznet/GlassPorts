/*
 * GlassPorts WiFi Settings
 * Basic WiFi connectivity settings
 */

package com.glassports.settings;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.wifi.ScanResult;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Handler;
import android.view.KeyEvent;
import android.view.View;
import android.widget.Switch;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

/**
 * WiFi Settings Activity
 * Allows connecting to WiFi networks
 */
public class WifiSettingsActivity extends Activity {

    private WifiManager mWifiManager;
    private Switch mWifiSwitch;
    private TextView mStatusText;
    private RecyclerView mNetworkList;
    private Handler mHandler;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_wifi_settings);

        mWifiManager = (WifiManager) getSystemService(Context.WIFI_SERVICE);
        mHandler = new Handler();

        mWifiSwitch = findViewById(R.id.wifi_switch);
        mStatusText = findViewById(R.id.wifi_status);
        mNetworkList = findViewById(R.id.network_list);

        mNetworkList.setLayoutManager(new LinearLayoutManager(this));

        mWifiSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            mWifiManager.setWifiEnabled(isChecked);
            updateState();
        });

        IntentFilter filter = new IntentFilter();
        filter.addAction(WifiManager.WIFI_STATE_CHANGED_ACTION);
        filter.addAction(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION);
        registerReceiver(mReceiver, filter);

        updateState();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(mReceiver);
    }

    private void updateState() {
        boolean enabled = mWifiManager.isWifiEnabled();
        mWifiSwitch.setChecked(enabled);

        if (enabled) {
            mStatusText.setText(R.string.wifi_on);
            mWifiManager.startScan();
        } else {
            mStatusText.setText(R.string.wifi_off);
        }
    }

    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (WifiManager.WIFI_STATE_CHANGED_ACTION.equals(action) ||
                    WifiManager.SCAN_RESULTS_AVAILABLE_ACTION.equals(action)) {
                mHandler.post(() -> updateState());
            }
        }
    };

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            finish();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }
}

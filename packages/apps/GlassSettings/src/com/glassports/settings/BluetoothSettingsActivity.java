/*
 * GlassPorts Bluetooth Settings
 */

package com.glassports.settings;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.view.KeyEvent;
import android.widget.Switch;
import android.widget.TextView;

/**
 * Bluetooth Settings Activity
 */
public class BluetoothSettingsActivity extends Activity {

    private BluetoothAdapter mBluetoothAdapter;
    private Switch mBluetoothSwitch;
    private TextView mStatusText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bluetooth_settings);

        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

        mBluetoothSwitch = findViewById(R.id.bluetooth_switch);
        mStatusText = findViewById(R.id.bluetooth_status);

        mBluetoothSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                mBluetoothAdapter.enable();
            } else {
                mBluetoothAdapter.disable();
            }
            updateState();
        });

        IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        registerReceiver(mReceiver, filter);

        updateState();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(mReceiver);
    }

    private void updateState() {
        boolean enabled = mBluetoothAdapter != null && mBluetoothAdapter.isEnabled();
        mBluetoothSwitch.setChecked(enabled);
        mStatusText.setText(enabled ? R.string.bluetooth_on : R.string.bluetooth_off);
    }

    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            updateState();
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

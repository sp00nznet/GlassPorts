/*
 * GlassPorts Developer Settings
 */

package com.glassports.settings;

import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemProperties;
import android.provider.Settings;
import android.view.KeyEvent;
import android.widget.Switch;
import android.widget.TextView;

/**
 * Developer Settings Activity
 * ADB and development options
 */
public class DeveloperSettingsActivity extends Activity {

    private Switch mAdbSwitch;
    private Switch mStayAwakeSwitch;
    private TextView mAdbStatus;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_developer_settings);

        mAdbSwitch = findViewById(R.id.adb_switch);
        mStayAwakeSwitch = findViewById(R.id.stay_awake_switch);
        mAdbStatus = findViewById(R.id.adb_status);

        // ADB is enabled by default in GlassPorts
        boolean adbEnabled = Settings.Global.getInt(getContentResolver(),
                Settings.Global.ADB_ENABLED, 1) == 1;
        mAdbSwitch.setChecked(adbEnabled);
        updateAdbStatus(adbEnabled);

        mAdbSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            Settings.Global.putInt(getContentResolver(),
                    Settings.Global.ADB_ENABLED, isChecked ? 1 : 0);
            updateAdbStatus(isChecked);
        });

        boolean stayAwake = Settings.Global.getInt(getContentResolver(),
                Settings.Global.STAY_ON_WHILE_PLUGGED_IN, 0) != 0;
        mStayAwakeSwitch.setChecked(stayAwake);

        mStayAwakeSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            Settings.Global.putInt(getContentResolver(),
                    Settings.Global.STAY_ON_WHILE_PLUGGED_IN,
                    isChecked ? 3 : 0); // 3 = USB + AC
        });
    }

    private void updateAdbStatus(boolean enabled) {
        if (enabled) {
            mAdbStatus.setText(R.string.adb_enabled);
        } else {
            mAdbStatus.setText(R.string.adb_disabled);
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            finish();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }
}

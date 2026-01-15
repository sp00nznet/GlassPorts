/*
 * GlassPorts Display Settings
 */

package com.glassports.settings;

import android.app.Activity;
import android.os.Bundle;
import android.provider.Settings;
import android.view.KeyEvent;
import android.widget.SeekBar;
import android.widget.TextView;

/**
 * Display Settings Activity
 * Control Glass display brightness
 */
public class DisplaySettingsActivity extends Activity {

    private SeekBar mBrightnessSeekBar;
    private TextView mBrightnessValue;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_display_settings);

        mBrightnessSeekBar = findViewById(R.id.brightness_seekbar);
        mBrightnessValue = findViewById(R.id.brightness_value);

        // Get current brightness
        int brightness = 128;
        try {
            brightness = Settings.System.getInt(
                    getContentResolver(), Settings.System.SCREEN_BRIGHTNESS);
        } catch (Settings.SettingNotFoundException e) {
            e.printStackTrace();
        }

        mBrightnessSeekBar.setMax(255);
        mBrightnessSeekBar.setProgress(brightness);
        updateBrightnessLabel(brightness);

        mBrightnessSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser) {
                    Settings.System.putInt(getContentResolver(),
                            Settings.System.SCREEN_BRIGHTNESS, progress);
                    updateBrightnessLabel(progress);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });
    }

    private void updateBrightnessLabel(int value) {
        int percent = (value * 100) / 255;
        mBrightnessValue.setText(percent + "%");
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

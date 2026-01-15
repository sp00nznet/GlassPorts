/*
 * GlassPorts About Settings
 */

package com.glassports.settings;

import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.view.KeyEvent;
import android.widget.TextView;

/**
 * About Settings Activity
 * Display device and GlassPorts version info
 */
public class AboutSettingsActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_about_settings);

        TextView modelView = findViewById(R.id.about_model);
        TextView androidView = findViewById(R.id.about_android);
        TextView buildView = findViewById(R.id.about_build);
        TextView glassportsView = findViewById(R.id.about_glassports);

        modelView.setText(Build.MODEL);
        androidView.setText(String.format("Android %s (API %d)",
                Build.VERSION.RELEASE, Build.VERSION.SDK_INT));
        buildView.setText(Build.DISPLAY);
        glassportsView.setText(getString(R.string.glassports_version));
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

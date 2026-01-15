/*
 * GlassPorts Minimal Launcher
 * Main launcher activity for Google Glass
 */

package com.glassports.launcher;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.widget.TextView;
import android.widget.ImageView;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * GlassPorts Minimal Launcher
 *
 * A simple launcher designed for Google Glass's unique interface.
 * Features:
 * - Displays current time and date
 * - Swipe gestures for navigation
 * - Quick access to Settings and Apps
 */
public class GlassLauncherActivity extends Activity implements
        GestureDetector.OnGestureListener {

    private static final String TAG = "GlassLauncher";

    private static final int SWIPE_THRESHOLD = 100;
    private static final int SWIPE_VELOCITY_THRESHOLD = 100;

    private GestureDetector mGestureDetector;
    private TextView mTimeView;
    private TextView mDateView;
    private TextView mStatusView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_launcher);

        mGestureDetector = new GestureDetector(this, this);

        mTimeView = findViewById(R.id.time_view);
        mDateView = findViewById(R.id.date_view);
        mStatusView = findViewById(R.id.status_view);

        updateTime();

        // Set initial status
        mStatusView.setText(R.string.status_ready);
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateTime();
    }

    /**
     * Update time and date display
     */
    private void updateTime() {
        Date now = new Date();

        SimpleDateFormat timeFormat = new SimpleDateFormat("h:mm", Locale.getDefault());
        SimpleDateFormat dateFormat = new SimpleDateFormat("EEEE, MMMM d", Locale.getDefault());

        mTimeView.setText(timeFormat.format(now));
        mDateView.setText(dateFormat.format(now));
    }

    /**
     * Open Settings app
     */
    private void openSettings() {
        Intent intent = new Intent();
        intent.setComponent(new ComponentName(
                "com.glassports.settings",
                "com.glassports.settings.GlassSettingsActivity"));

        // Fallback to system settings if GlassPorts settings not available
        if (!isActivityAvailable(intent)) {
            intent = new Intent(android.provider.Settings.ACTION_SETTINGS);
        }

        startActivity(intent);
    }

    /**
     * Open App List
     */
    private void openAppList() {
        Intent intent = new Intent(this, AppListActivity.class);
        startActivity(intent);
    }

    /**
     * Check if an intent can be resolved
     */
    private boolean isActivityAvailable(Intent intent) {
        PackageManager pm = getPackageManager();
        ResolveInfo info = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
        return info != null;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return mGestureDetector.onTouchEvent(event) || super.onTouchEvent(event);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        switch (keyCode) {
            case KeyEvent.KEYCODE_CAMERA:
                // Camera button - open camera app if available
                Intent cameraIntent = new Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE);
                if (isActivityAvailable(cameraIntent)) {
                    startActivity(cameraIntent);
                }
                return true;

            case KeyEvent.KEYCODE_DPAD_CENTER:
            case KeyEvent.KEYCODE_ENTER:
                // Tap - open app list
                openAppList();
                return true;

            default:
                return super.onKeyDown(keyCode, event);
        }
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
        openAppList();
        return true;
    }

    @Override
    public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
        return false;
    }

    @Override
    public void onLongPress(MotionEvent e) {
        openSettings();
    }

    @Override
    public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY) {
        if (e1 == null || e2 == null) {
            return false;
        }

        float diffX = e2.getX() - e1.getX();
        float diffY = e2.getY() - e1.getY();

        if (Math.abs(diffX) > Math.abs(diffY)) {
            // Horizontal swipe
            if (Math.abs(diffX) > SWIPE_THRESHOLD &&
                    Math.abs(velocityX) > SWIPE_VELOCITY_THRESHOLD) {
                if (diffX > 0) {
                    // Swipe right - open Settings
                    openSettings();
                } else {
                    // Swipe left - open App List
                    openAppList();
                }
                return true;
            }
        } else {
            // Vertical swipe
            if (Math.abs(diffY) > SWIPE_THRESHOLD &&
                    Math.abs(velocityY) > SWIPE_VELOCITY_THRESHOLD) {
                if (diffY > 0) {
                    // Swipe down - show status
                    mStatusView.setVisibility(View.VISIBLE);
                } else {
                    // Swipe up - hide status
                    mStatusView.setVisibility(View.GONE);
                }
                return true;
            }
        }
        return false;
    }
}

/*
 * GlassPorts Settings
 * Main settings activity for Google Glass
 */

package com.glassports.settings;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.GestureDetector;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

/**
 * GlassPorts Settings
 * Main settings menu optimized for Glass interface
 */
public class GlassSettingsActivity extends Activity implements
        GestureDetector.OnGestureListener {

    private static final int SWIPE_THRESHOLD = 100;
    private static final int SWIPE_VELOCITY_THRESHOLD = 100;

    private RecyclerView mSettingsList;
    private SettingsAdapter mAdapter;
    private List<SettingsItem> mItems;
    private GestureDetector mGestureDetector;
    private int mCurrentPosition = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        mGestureDetector = new GestureDetector(this, this);

        mSettingsList = findViewById(R.id.settings_list);
        mSettingsList.setLayoutManager(new LinearLayoutManager(
                this, LinearLayoutManager.HORIZONTAL, false));

        initSettingsItems();

        mAdapter = new SettingsAdapter(mItems);
        mSettingsList.setAdapter(mAdapter);
    }

    /**
     * Initialize settings items
     */
    private void initSettingsItems() {
        mItems = new ArrayList<>();

        // WiFi
        mItems.add(new SettingsItem(
                getString(R.string.wifi_title),
                getString(R.string.wifi_summary),
                R.drawable.ic_wifi,
                WifiSettingsActivity.class));

        // WiFi AP - Primary feature for GlassPorts
        mItems.add(new SettingsItem(
                getString(R.string.wifi_ap_title),
                getString(R.string.wifi_ap_summary),
                R.drawable.ic_wifi_tethering,
                WifiApSettingsActivity.class));

        // Bluetooth
        mItems.add(new SettingsItem(
                getString(R.string.bluetooth_title),
                getString(R.string.bluetooth_summary),
                R.drawable.ic_bluetooth,
                BluetoothSettingsActivity.class));

        // Display
        mItems.add(new SettingsItem(
                getString(R.string.display_title),
                getString(R.string.display_summary),
                R.drawable.ic_display,
                DisplaySettingsActivity.class));

        // Developer Options
        mItems.add(new SettingsItem(
                getString(R.string.developer_title),
                getString(R.string.developer_summary),
                R.drawable.ic_developer,
                DeveloperSettingsActivity.class));

        // About
        mItems.add(new SettingsItem(
                getString(R.string.about_title),
                getString(R.string.about_summary),
                R.drawable.ic_about,
                AboutSettingsActivity.class));
    }

    /**
     * Open selected setting
     */
    private void openSetting(int position) {
        if (position >= 0 && position < mItems.size()) {
            SettingsItem item = mItems.get(position);
            Intent intent = new Intent(this, item.activityClass);
            startActivity(intent);
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return mGestureDetector.onTouchEvent(event) || super.onTouchEvent(event);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        switch (keyCode) {
            case KeyEvent.KEYCODE_DPAD_LEFT:
                if (mCurrentPosition > 0) {
                    mCurrentPosition--;
                    mSettingsList.smoothScrollToPosition(mCurrentPosition);
                }
                return true;

            case KeyEvent.KEYCODE_DPAD_RIGHT:
                if (mCurrentPosition < mItems.size() - 1) {
                    mCurrentPosition++;
                    mSettingsList.smoothScrollToPosition(mCurrentPosition);
                }
                return true;

            case KeyEvent.KEYCODE_DPAD_CENTER:
            case KeyEvent.KEYCODE_ENTER:
                openSetting(mCurrentPosition);
                return true;

            case KeyEvent.KEYCODE_BACK:
                finish();
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
        openSetting(mCurrentPosition);
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

        float diffX = e2.getX() - e1.getX();

        if (Math.abs(diffX) > SWIPE_THRESHOLD &&
                Math.abs(velocityX) > SWIPE_VELOCITY_THRESHOLD) {
            if (diffX > 0) {
                if (mCurrentPosition > 0) {
                    mCurrentPosition--;
                    mSettingsList.smoothScrollToPosition(mCurrentPosition);
                }
            } else {
                if (mCurrentPosition < mItems.size() - 1) {
                    mCurrentPosition++;
                    mSettingsList.smoothScrollToPosition(mCurrentPosition);
                }
            }
            return true;
        }

        float diffY = e2.getY() - e1.getY();
        if (diffY > SWIPE_THRESHOLD && Math.abs(velocityY) > SWIPE_VELOCITY_THRESHOLD) {
            finish();
            return true;
        }

        return false;
    }

    /**
     * Settings item holder
     */
    static class SettingsItem {
        String title;
        String summary;
        int iconRes;
        Class<? extends Activity> activityClass;

        SettingsItem(String title, String summary, int iconRes,
                     Class<? extends Activity> activityClass) {
            this.title = title;
            this.summary = summary;
            this.iconRes = iconRes;
            this.activityClass = activityClass;
        }
    }

    /**
     * Settings list adapter
     */
    class SettingsAdapter extends RecyclerView.Adapter<SettingsAdapter.ViewHolder> {
        private List<SettingsItem> mItems;

        SettingsAdapter(List<SettingsItem> items) {
            mItems = items;
        }

        @Override
        public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_setting, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(ViewHolder holder, int position) {
            SettingsItem item = mItems.get(position);
            holder.icon.setImageResource(item.iconRes);
            holder.title.setText(item.title);
            holder.summary.setText(item.summary);

            holder.itemView.setOnClickListener(v -> {
                mCurrentPosition = position;
                openSetting(position);
            });
        }

        @Override
        public int getItemCount() {
            return mItems.size();
        }

        class ViewHolder extends RecyclerView.ViewHolder {
            ImageView icon;
            TextView title;
            TextView summary;

            ViewHolder(View itemView) {
                super(itemView);
                icon = itemView.findViewById(R.id.setting_icon);
                title = itemView.findViewById(R.id.setting_title);
                summary = itemView.findViewById(R.id.setting_summary);
            }
        }
    }
}

/*
 * GlassPorts App List
 * Displays installed applications
 */

package com.glassports.launcher;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.drawable.Drawable;
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
import java.util.Collections;
import java.util.List;

/**
 * App List Activity
 * Displays a horizontal scrolling list of installed apps
 */
public class AppListActivity extends Activity implements
        GestureDetector.OnGestureListener {

    private static final int SWIPE_THRESHOLD = 100;
    private static final int SWIPE_VELOCITY_THRESHOLD = 100;

    private RecyclerView mAppList;
    private AppAdapter mAdapter;
    private List<AppInfo> mApps;
    private GestureDetector mGestureDetector;
    private int mCurrentPosition = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_app_list);

        mGestureDetector = new GestureDetector(this, this);

        mAppList = findViewById(R.id.app_list);
        mAppList.setLayoutManager(new LinearLayoutManager(
                this, LinearLayoutManager.HORIZONTAL, false));

        loadApps();

        mAdapter = new AppAdapter(mApps);
        mAppList.setAdapter(mAdapter);
    }

    /**
     * Load installed applications
     */
    private void loadApps() {
        mApps = new ArrayList<>();
        PackageManager pm = getPackageManager();

        Intent mainIntent = new Intent(Intent.ACTION_MAIN, null);
        mainIntent.addCategory(Intent.CATEGORY_LAUNCHER);

        List<ResolveInfo> apps = pm.queryIntentActivities(mainIntent, 0);

        for (ResolveInfo info : apps) {
            String packageName = info.activityInfo.packageName;

            // Skip the launcher itself
            if (packageName.equals(getPackageName())) {
                continue;
            }

            AppInfo appInfo = new AppInfo();
            appInfo.name = info.loadLabel(pm).toString();
            appInfo.packageName = packageName;
            appInfo.activityName = info.activityInfo.name;
            appInfo.icon = info.loadIcon(pm);

            mApps.add(appInfo);
        }

        // Sort by name
        Collections.sort(mApps, (a, b) -> a.name.compareToIgnoreCase(b.name));
    }

    /**
     * Launch selected app
     */
    private void launchApp(int position) {
        if (position >= 0 && position < mApps.size()) {
            AppInfo app = mApps.get(position);
            Intent intent = new Intent(Intent.ACTION_MAIN);
            intent.addCategory(Intent.CATEGORY_LAUNCHER);
            intent.setComponent(new ComponentName(app.packageName, app.activityName));
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            finish();
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
                    mAppList.smoothScrollToPosition(mCurrentPosition);
                }
                return true;

            case KeyEvent.KEYCODE_DPAD_RIGHT:
                if (mCurrentPosition < mApps.size() - 1) {
                    mCurrentPosition++;
                    mAppList.smoothScrollToPosition(mCurrentPosition);
                }
                return true;

            case KeyEvent.KEYCODE_DPAD_CENTER:
            case KeyEvent.KEYCODE_ENTER:
                launchApp(mCurrentPosition);
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
        launchApp(mCurrentPosition);
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
                // Swipe right - previous app
                if (mCurrentPosition > 0) {
                    mCurrentPosition--;
                    mAppList.smoothScrollToPosition(mCurrentPosition);
                }
            } else {
                // Swipe left - next app
                if (mCurrentPosition < mApps.size() - 1) {
                    mCurrentPosition++;
                    mAppList.smoothScrollToPosition(mCurrentPosition);
                }
            }
            return true;
        }

        // Swipe down to go back
        float diffY = e2.getY() - e1.getY();
        if (diffY > SWIPE_THRESHOLD && Math.abs(velocityY) > SWIPE_VELOCITY_THRESHOLD) {
            finish();
            return true;
        }

        return false;
    }

    /**
     * App info holder
     */
    static class AppInfo {
        String name;
        String packageName;
        String activityName;
        Drawable icon;
    }

    /**
     * RecyclerView adapter for app list
     */
    class AppAdapter extends RecyclerView.Adapter<AppAdapter.ViewHolder> {
        private List<AppInfo> mApps;

        AppAdapter(List<AppInfo> apps) {
            mApps = apps;
        }

        @Override
        public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_app, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(ViewHolder holder, int position) {
            AppInfo app = mApps.get(position);
            holder.icon.setImageDrawable(app.icon);
            holder.name.setText(app.name);

            holder.itemView.setOnClickListener(v -> {
                mCurrentPosition = position;
                launchApp(position);
            });
        }

        @Override
        public int getItemCount() {
            return mApps.size();
        }

        class ViewHolder extends RecyclerView.ViewHolder {
            ImageView icon;
            TextView name;

            ViewHolder(View itemView) {
                super(itemView);
                icon = itemView.findViewById(R.id.app_icon);
                name = itemView.findViewById(R.id.app_name);
            }
        }
    }
}

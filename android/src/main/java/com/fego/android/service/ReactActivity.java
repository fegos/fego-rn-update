package com.fego.android.service;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.support.v4.app.FragmentActivity;
import android.view.KeyEvent;

import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactRootView;
import com.facebook.react.modules.core.DefaultHardwareBackBtnHandler;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;


/**
 * rn页面基类
 * Created by wx on 17/3/28.
 */
public abstract class ReactActivity extends FragmentActivity implements DefaultHardwareBackBtnHandler {

    private ReactRootView mReactRootView;
    private ReactInstanceManager mReactInstanceManager;
    private OnVersionUpdateListener listener;

    /**
     * Gets listener.
     *
     * @return the listener
     */
    public OnVersionUpdateListener getListener() {
        return listener;
    }

    /**
     * Sets listener.
     *
     * @param listener the listener
     */
    public void setListener(OnVersionUpdateListener listener) {
        this.listener = listener;
    }

    /**
     * module名字
     *
     * @return module名字 module name
     */
    public abstract String getModuleName();

    /**
     * 是否为开发状态
     *
     * @return 是 ，则返回true，否则返回false
     */
    public abstract boolean isDevelopStatus();

    /**
     * 初始化ReactInstanceManager
     */
    public abstract void initReactManager();

    /**
     * On create.
     *
     * @param savedInstanceState the saved instance state
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EventBus.getDefault().register(this);
        if (isDevelopStatus() && Build.VERSION.SDK_INT >= 23 && !Settings.canDrawOverlays(this)) {
            showPermissonDialog();
        } else {
            updateReactView();
        }
    }

    /**
     * 展示权限提醒
     */
    private void showPermissonDialog() {
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("提示")
                .setMessage("请设置应用允许在其他应用的上层显示")
                .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        finish();
                    }
                })
                .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + getPackageName()));
                        startActivityForResult(intent, 1000);
                    }
                })
                .create();
        dialog.show();
    }

    /**
     * Invoke default on back pressed.
     */
    @Override
    public void invokeDefaultOnBackPressed() {
        super.onBackPressed();
    }

    /**
     * On pause.
     */
    @Override
    protected void onPause() {
        super.onPause();

        if (mReactInstanceManager != null) {
            ReactManager.getInstance().setCurrentActivity(null);
            mReactInstanceManager.onHostPause(this);
        }
    }

    /**
     * On resume.
     */
    @Override
    protected void onResume() {
        super.onResume();
        if (mReactInstanceManager != null) {
            ReactManager.getInstance().setCurrentActivity(this);
            mReactInstanceManager.onHostResume(this, this);
        }
        if (ReactManager.getInstance().hasNewVersion()) {
            questionUpdateReactSource();
        }
    }

    /**
     * On destroy.
     */
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mReactRootView != null) {
            mReactRootView.unmountReactApplication();
            mReactRootView = null;
        }
        if (mReactInstanceManager != null) {
            mReactInstanceManager.onHostDestroy(this);
        }
        EventBus.getDefault().unregister(this);
        System.gc();
    }

    /**
     * On back pressed.
     */
    @Override
    public void onBackPressed() {
        if (mReactInstanceManager != null) {
            mReactInstanceManager.onBackPressed();
        } else {
            super.onBackPressed();
        }
    }

    /**
     * On key up boolean.
     *
     * @param keyCode the key code
     * @param event   the event
     * @return the boolean
     */
    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_MENU && mReactInstanceManager != null) {
            mReactInstanceManager.showDevOptionsDialog();
            return true;
        }
        return super.onKeyUp(keyCode, event);
    }

    /**
     * On event main thread.
     *
     * @param task the task
     */
    @Subscribe
    public void onEventMainThread(ReactManager.NPReactManagerTask task) {
        if (task == ReactManager.NPReactManagerTask.GetNewReactVersionSource) {
            questionUpdateReactSource();
        }
    }

    /**
     * 询问是否更新最新包提示
     */
    protected void questionUpdateReactSource() {
        //此处标记已经下载了新的rn资源包,提示用户是否进行更新
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("温馨提示")
                .setMessage("有新的资源包可以更新，是否立即更新?")
                .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        dialog.cancel();
                    }
                })
                .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        ReactManager.getInstance().doReloadBundle();
                        if (listener != null) {
                            listener.onVersionUpdate();
                        }
                    }
                })
                .create();
        dialog.show();
    }

    /**
     * On activity result.
     *
     * @param requestCode the request code
     * @param resultCode  the result code
     * @param data        the data
     */
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (mReactInstanceManager != null) {
            mReactInstanceManager.onActivityResult(this, requestCode, resultCode, data);
        } else {
            super.onActivityResult(requestCode, resultCode, data);
        }

        if (requestCode == 1000) {
            if (Build.VERSION.SDK_INT >= 23 && !Settings.canDrawOverlays(this)) {
                showPermissonDialog();
            } else {
                updateReactView();
            }
        }
    }

    /**
     * On new intent.
     *
     * @param intent the intent
     */
    @Override
    protected void onNewIntent(Intent intent) {
        if (mReactInstanceManager != null) {
            mReactInstanceManager.onNewIntent(intent);
        } else {
            super.onNewIntent(intent);
        }
    }

    /**
     * 更新reactview
     */
    private void updateReactView() {
        if (mReactRootView == null) {
            mReactInstanceManager = ReactManager.getInstance().getRnInstanceManager();
            if (mReactInstanceManager == null) {
                initReactManager();
                mReactInstanceManager = ReactManager.getInstance().getRnInstanceManager();
            }
            Bundle bundle = getIntent().getExtras();
            Bundle dealBundle = null;
            if (bundle != null) {
                dealBundle = (Bundle) bundle.clone();
                for (String key : bundle.keySet()) {
                    Object obj = bundle.get(key);
                    if (obj instanceof Boolean
                            || obj instanceof Integer
                            || obj instanceof Number
                            || obj instanceof String) {
                    } else {
                        dealBundle.remove(key);
                    }
                }
            }
            mReactRootView = ReactManager.getInstance().getReactViewByModuleName(getModuleName(), this, dealBundle);
            setContentView(mReactRootView);
        }
    }

    /**
     * The interface On version update listener.
     */
    public interface OnVersionUpdateListener {
        /**
         * On version update.
         */
        void onVersionUpdate();
    }
}

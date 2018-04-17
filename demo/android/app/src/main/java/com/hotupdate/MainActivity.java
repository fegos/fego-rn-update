package com.hotupdate;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.support.annotation.Nullable;
import android.view.KeyEvent;

import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactPackage;
import com.facebook.react.ReactRootView;
import com.facebook.react.modules.core.DefaultHardwareBackBtnHandler;
import com.fego.android.service.HotUpdatePackage;
import com.fego.android.service.ReactManager;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends Activity implements DefaultHardwareBackBtnHandler, ReactManager.SuccessListener, ReactManager.FailListener {
    private ReactRootView mReactRootView;
    private ReactInstanceManager mReactInstanceManager;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (BuildConfig.DEBUG && Build.VERSION.SDK_INT >= 23 && !Settings.canDrawOverlays(this)) {
            showPermissonDialog();
        } else {
            updateReactView();
        }
    }

    /**
     * 更新reactview
     */
    private void updateReactView() {
        ReactManager.getInstance().init(getApplication(), "index", "index.jsbundle", "https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/android/");
        if (mReactRootView == null) {
            if (mReactInstanceManager == null) {
                if (ReactManager.getInstance().getRnInstanceManager() == null) {
                    List<ReactPackage> reactPackages = new ArrayList<>();
                    // 添加额外的package
                    reactPackages.add(new HotUpdatePackage());
                    ReactManager.getInstance().loadBundle(reactPackages, BuildConfig.DEBUG, "");
                }
                mReactInstanceManager = ReactManager.getInstance().getRnInstanceManager();
            }
            mReactRootView = ReactManager.getInstance().getReactViewByModuleName("hotUpdate", this, null);
            setContentView(mReactRootView);
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
                        ReactManager.getInstance().unzipBundle("");
                        ReactManager.getInstance().doReloadBundle("");
                        // 下次启动应用时更新
                        // ReactManager.getInstance().unzipBundle();
                    }
                })
                .create();
        dialog.show();
    }

    @Override
    public void onSuccess() {
        questionUpdateReactSource();
    }

    @Override
    public void onFail(ReactManager.NPReactManagerTask task) {
        if (task == ReactManager.NPReactManagerTask.GetConfigFail) {
            // 获取config失败
        } else if (task == ReactManager.NPReactManagerTask.GetSourceFail) {
            // 获取zip包失败
        } else if (task == ReactManager.NPReactManagerTask.Md5VerifyFail) {
            // md5验证失败
        }
    }
}

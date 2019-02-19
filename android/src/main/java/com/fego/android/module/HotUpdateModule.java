package com.fego.android.module;

import android.app.Activity;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.fego.android.service.ReactManager;

/**
 * 用于在js中想要进行bundle更新的逻辑
 * Created by sxiaoxia on 2017/12/7.
 */
public class HotUpdateModule extends ReactContextBaseJavaModule {

    ReactApplicationContext context;
    /**
     * Instantiates a new Hot update module.
     *
     * @param reactContext the react context
     */
    public HotUpdateModule(ReactApplicationContext reactContext) {
        super(reactContext);
        context = reactContext;
    }

    /**
     * Gets name.
     *
     * @return the name
     */
    @Override
    public String getName() {
        return "FegoRnUpdate";
    }

    /**
     * Hot reload.
     */
    @ReactMethod
    public void hotReload(String businessName) {
        ReactManager.SuccessListener sucListener = null;
        ReactManager.FailListener failListener = null;
        Activity activity = getCurrentActivity();
        if (activity != null && activity instanceof ReactManager.SuccessListener) {
            sucListener = (ReactManager.SuccessListener)activity;
        }
        if (activity != null && activity instanceof ReactManager.FailListener) {
            failListener = (ReactManager.FailListener)activity;
        }
        ReactManager.getInstance().loadBundleBehind(businessName, sucListener, failListener);
    }
}

package com.fego.android.service;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.fego.android.module.HotUpdateModule;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by sxiaoxia on 2017/12/7.
 */
public class HotUpdatePackage implements ReactPackage {

    /**
     * Create native modules list.
     *
     * @param reactContext the react context
     * @return the list
     */
    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
        List<NativeModule> list = new ArrayList<>();
        list.add(new HotUpdateModule(reactContext));
        return list;
    }

    /**
     * Create view managers list.
     *
     * @param reactContext the react context
     * @return the list
     */
    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        List<ViewManager> list = new ArrayList<>();
        return list;
    }
}

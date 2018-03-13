package com.hybrid.hotupdate.utils;

import android.app.Application;
import android.content.Context;

import com.facebook.react.ReactPackage;
import com.fego.android.service.HotUpdatePackage;
import com.fego.android.service.ReactManager;
import com.hybrid.hotupdate.BuildConfig;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by sxiaoxia on 2018/3/8.
 */

public class ConfigUtil {

    private static ConfigUtil instance = null;

    public static ConfigUtil getInstance() {
        if (instance == null) {
            instance = new ConfigUtil();
        }
        return instance;
    }

    private ConfigUtil() {
    }

    public void initReactManager(Application application, String mainModuleName, String bundleName) {
//        if (ReactManager.getInstance().getRnInstanceManager() == null) {
            // 设置react native启动文件的名称
            ReactManager.getInstance().setJsMainModuleName(mainModuleName);
            // 设置加载的文件名
            ReactManager.getInstance().setBundleName(bundleName);
            // 设置热更新路径
            ReactManager.getInstance().setSourceUrl("https://raw.githubusercontent.com/fegos/fego-rn-update/master/hybriddemo/rn/increment/android/");
            List<ReactPackage> reactPackages = new ArrayList<>();
            // 添加额外的package
            reactPackages.add(new HotUpdatePackage());
            ReactManager.getInstance().init(application, reactPackages, BuildConfig.DEBUG);
//        }
    }
}

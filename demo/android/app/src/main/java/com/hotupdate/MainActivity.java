package com.hotupdate;

import android.os.Bundle;

import com.facebook.react.ReactPackage;
import com.fego.android.service.HotUpdatePackage;
import com.fego.android.service.ReactActivity;
import com.fego.android.service.ReactManager;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends ReactActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // 启动后台热更新操作
        // ReactManager.getInstance().loadBundleBehind();
    }

    @Override
    public String getModuleName() {
        return "hotUpdate";
    }

    @Override
    public boolean isDevelopStatus() {
        return BuildConfig.DEBUG;
    }

    @Override
    public void initReactManager() {
        if (ReactManager.getInstance().getRnInstanceManager() == null) {
            // 设置react native启动文件的名称
            ReactManager.getInstance().setJsMainModuleName("index");
            // 设置加载的文件名
            ReactManager.getInstance().setBundleName("index.jsbundle");
            // 设置热更新路径
            ReactManager.getInstance().setSourceUrl("https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/android/increment/");
            List<ReactPackage> reactPackages = new ArrayList<>();
            // 添加额外的package
            reactPackages.add(new HotUpdatePackage());
            ReactManager.getInstance().init(getApplication(), reactPackages, BuildConfig.DEBUG);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
    }
}

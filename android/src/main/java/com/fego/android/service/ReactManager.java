package com.fego.android.service;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.graphics.Typeface;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactInstanceManagerBuilder;
import com.facebook.react.ReactPackage;
import com.facebook.react.ReactRootView;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.common.LifecycleState;
import com.facebook.react.shell.MainReactPackage;
import com.facebook.react.views.text.ReactFontManager;
import com.fego.android.utils.AssetUtil;
import com.fego.android.utils.DiffMatchPatchUtils;
import com.fego.android.utils.FileUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.Writer;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.LinkedList;
import java.util.List;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * 热更新管理类
 */
public class ReactManager {

    private final static String TAG = "REACT_MANAGER";
    private final static String BUNDLE_VERSION = "BUNDLE_VERSION";        // 用来标记本地rn资源版本号
    private final static String APP_VERSIONCODE = "APP_VERSIONCODE";      // 用来标记apk的versioncode
    private final static String NEW_BUNDLE_PATH = "NEW_BUNDLE_PATH";      // 用来存储下载的最新的rn资源路径
    private final static String NEW_BUNDLE_VERSION = "NEW_BUNDLE_VERSION";// 用来记录最新的rn资源版本号

    private String sourceUrl = "";                                  // 热更新rn资源下载路径
    private String jsMainModuleName = "index";                      // 启动文件名
    private String bundleName = "index.jsbundle";                   // rn bundle文件名
    private Activity currentActivity;                               // 当前activity
    private SuccessListener successListener;                        // 成功监听
    private FailListener failListener;                              // 失败监听

    private Call<ResponseBody> configCall;                          // 用于请求配置文件
    private Call<ResponseBody> bundleCall;                          // 用于请求rn资源文件
    private String sourceDir = null;                                // rn资源的本地存储路径
    private String localDataVersion = "0";                          // 记录本地rn资源包版本号
    private String type = null;                                     // 用来临时记录增量还是全量
    private boolean isAll = false;                                  // 是否使用全量更新
    private String rnZipName = "";                                  // 下载下来的zip包名
    private String apkVersion = "1.0";                              // 用来临时标记本地apk版本号
    private String md5Value = "";                                   // 用来临时记录zip包的md5值
    private Application application = null;                         // application
    private ReactInstanceManager rnInstanceManager;                 // ReactInstanceManager
    private String businessName;                                    // 业务名
    /**
     * The enum Np react manager task.
     * 用于通知有新的资源包
     */
    public enum NPReactManagerTask {
        GetConfigFail,
        GetSourceFail,
        Md5VerifyFail
    }
    private static ReactManager instance = null;

    /**
     * Gets instance.
     *
     * @return the instance
     */
    public static ReactManager getInstance() {
        if (instance == null) {
            instance = new ReactManager();
        }
        return instance;
    }


    private ReactManager() {

    }

    /**
     * 启动application时需要初始化reactInstance
     *
     * @param <T>           the type parameter
     * @param application   application
     * @param reactPackages reactPackages
     * @param useDevelop    是否开发模式
     */
    public <T extends ReactPackage> void init(Application application, List<T> reactPackages, boolean useDevelop) {

        this.application = application;
        ReactPreference.getInstance().setContext(application.getApplicationContext());

        //获取app的沙盒目录
        sourceDir = this.application.getFilesDir().getAbsolutePath() + File.separator + "rn" + File.separator;

        //添加versionCode的校验，确保每次发的包能够区分开
        //获取android versioncode
        try {
            PackageInfo pi = application.getPackageManager().getPackageInfo(application.getPackageName(), 0);
            Log.d(TAG, String.valueOf(pi.versionCode));
            int appVersionCode = pi.versionCode;
            apkVersion = pi.versionName;
            int localRNVersionCode = ReactPreference.getInstance().getInt(APP_VERSIONCODE);
            if (localRNVersionCode == 0 || localRNVersionCode < appVersionCode) {
                //说明没有储存过appversionCode或者包发生了更新，需要将asset目录下的rn资源copy到沙盒目录
                //清理沙盒目录下的rn缓存
                File fileRNSourceDir = new File(sourceDir);
                FileUtils.delete(fileRNSourceDir);
                //copy bundle+assets到沙盒目录
                AssetUtil.copyAssetFolder(application.getAssets(), "rn", sourceDir);
                //完了后设置本地的appversioncode
                ReactPreference.getInstance().saveInt(APP_VERSIONCODE, appVersionCode);
            }
            if (!businessName.equals("common")) {
                //rn manager初始化，仅使用位于沙盒目录下的bundle资源
                ReactInstanceManagerBuilder builder = ReactInstanceManager.builder()
                        .setApplication(application);
                if (ReactPreference.getInstance().getInt(businessName) != 1) {
                    String patchStr = getJsBundle(sourceDir + businessName + "/" + bundleName, false);
                    String assetsBundle = getJsBundle(sourceDir + "common/" + bundleName, false);
                    merge(patchStr, assetsBundle, sourceDir + businessName + "/");
                }
                ReactPreference.getInstance().saveInt(businessName, 1);

                Class<?> clazz = builder.getClass();
                Method method = null;
                try {
                    method = clazz.getMethod("setJSMainModuleName", String.class);
                } catch (Exception ex) {
                    try {
                        method = clazz.getMethod("setJSMainModulePath", String.class);

                    } catch (Exception ex0) {

                    }
                }
                if (method != null) {
                    method.invoke(builder, jsMainModuleName);
                }

                builder.addPackage(new MainReactPackage())
                        .setUseDeveloperSupport(useDevelop)
                        .setInitialLifecycleState(LifecycleState.BEFORE_CREATE);

                if (reactPackages != null && reactPackages.size() > 0) {
                    for (ReactPackage reactPackage : reactPackages) {
                        builder.addPackage(reactPackage);
                    }
                }
                //直接读取该bundle资源
                builder.setJSBundleFile(sourceDir + businessName + "/" + bundleName);
                //更新字体文件
                updateReactFonts();
                rnInstanceManager = builder.build();
                rnInstanceManager.createReactContextInBackground();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 更新字体文件
     */
    private void updateReactFonts() {
        File rnSourceDirFile = new File(sourceDir + businessName + '/');
        FilenameFilter fileNameFilter = new FilenameFilter() {
            @Override
            public boolean accept(File dir, String filename) {
                return filename.endsWith(".ttf");
            }
        };
        String[] fontsFiles = rnSourceDirFile.list(fileNameFilter);
        for (int i = 0; i < fontsFiles.length; i++) {
            String[] fontsNames = fontsFiles[i].split("\\.");
            File fontFile = new File(sourceDir + businessName + '/' + fontsFiles[i]);
            if (fontFile.exists()) {
                Typeface tf = Typeface.createFromFile(sourceDir + businessName + '/' + fontsFiles[i]);
                ReactFontManager.getInstance().setTypeface(fontsNames[0], 0, tf);
            }
        }
    }

    /**
     * 后台执行热更新逻辑
     */
    public void loadBundleBehind() {
        //获取本地rn资源的sdk版本号、资源数据迭代版本号
        localDataVersion = ReactPreference.getInstance().getString(businessName + BUNDLE_VERSION);

        if (this.localDataVersion.equals("")) {
            this.localDataVersion = "0";
        }
        //请求远程的rn资源最新的配置文件,获取rn最新的对应sdk的数据迭代版本号
        ReactService service = new ReactService();
        String rnConfigSourceUrl = sourceUrl + "config";
        configCall = service.downloadFile(rnConfigSourceUrl, new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    Log.d(TAG, "load react data behind success!");
                    String downloadFilePath = application.getFilesDir().getAbsolutePath() + File.separator + "rn_" + businessName + "_config";
                    File file = new File(downloadFilePath);
                    boolean writtenToDisk = FileUtils.writeResponseBodyToDisk(response.body(), file);
                    if (writtenToDisk) {
                        byte[] bytes = FileUtils.readFile(downloadFilePath);
                        String configDetail = new String(bytes);
                        Log.d(TAG, configDetail);
                        checkRNConfigFile(configDetail);
                    } else {
                        if (failListener != null) {
                            failListener.onFail(NPReactManagerTask.GetConfigFail);
                        }
                    }
                } else {
                    Log.d(TAG, "load react data behind fail!");
                    if (failListener != null) {
                        failListener.onFail(NPReactManagerTask.GetConfigFail);
                    }
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                Log.d(TAG, "load react data behind fail!");
                if (failListener != null) {
                    failListener.onFail(NPReactManagerTask.GetConfigFail);
                }
            }
        });
    }

    /**
     * 下载rn配置文件后,在本地读取配置文件来决定是否下载线上的rn资源包
     *
     * @param configDetail 配置文件内容
     */
    private void checkRNConfigFile(String configDetail) {
        try {
            String[] lines = configDetail.split(",");
            for (String line : lines) {
                String[] infos = line.split("_");
                if (infos.length > 1) {
                    String remoteSdkVersion = "";
                    String remoteDataVersion = "";
                    remoteSdkVersion = infos[0];
                    remoteDataVersion = infos[1];
                    if (infos.length == 3) {
                        isAll = true;
                        md5Value = infos[2];
                        type = "1";
                    } else {
                        isAll = false;
                        String localDataVer = infos[2];
                        if (!localDataVer.equals(localDataVersion)) {
                            continue;
                        }
                        type = infos[3];
                        md5Value = infos[4];
                    }
                    if (remoteSdkVersion.equals(apkVersion)) {
                        //如果新版本字典存在,说明是已下载还没有使用的资源,如果跟线上的版本号相同也不必要下载了
                        String needUpdateVersion = ReactPreference.getInstance().getString(businessName + NEW_BUNDLE_VERSION);
                        if (TextUtils.isEmpty(needUpdateVersion)) {// 没有新资源
                            // 远程版本不为""；远程版本与本地版本不一致；
                            if (!remoteDataVersion.equals("") && !remoteDataVersion.equals(localDataVersion)) {
                                loadRNSource(remoteDataVersion);
                            } else {
                                Log.d(TAG, "version is same,no need load rn data!");
                            }
                        } else {// 资源已经下载好，但是还未被重新load
                            if (remoteDataVersion.equals(needUpdateVersion)) {
                                unzipBundle();
                                doReloadBundle();
                            } else {
                                loadRNSource(remoteDataVersion);
                            }
                        }
                        break;
                    }

                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    /**
     * 根据获取的远程的当前sdk版本的资源迭代版本号,下载指定的资源
     *
     * @param remoteDataVersion 远程sdk版本号
     */
    private void loadRNSource(final String remoteDataVersion) {
        ReactService service = new ReactService();
        String rnSourceUrl = "";
        if (isAll) {
            rnZipName = "rn_" + apkVersion + "_" + remoteDataVersion + ".zip";
            rnSourceUrl = sourceUrl + "all/" + apkVersion + "/" + rnZipName;
        }else {
            rnZipName = "rn_" + apkVersion + "_" + remoteDataVersion + "_" + localDataVersion + "_" + type + ".zip";
            rnSourceUrl = sourceUrl + "increment/" + apkVersion + "/" + rnZipName;
        }
        bundleCall = service.downloadFile(rnSourceUrl, new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    String downloadFilePath = application.getFilesDir().getAbsolutePath() + File.separator + rnZipName;
                    File file = new File(downloadFilePath);
                    boolean writtenToDisk = FileUtils.writeResponseBodyToDisk(response.body(), file);
                    if (writtenToDisk) {
                        String tmpValue = FileUtils.getMd5ByFile(file);
                        if (tmpValue.equals(md5Value)) {
                            ReactPreference.getInstance().save(businessName + NEW_BUNDLE_PATH, downloadFilePath);
                            ReactPreference.getInstance().save(businessName + NEW_BUNDLE_VERSION, remoteDataVersion);
                            if (successListener != null) {
                                successListener.onSuccess();
                            } else {
                                unzipBundle();
                                if (!businessName.equals("common")) {
                                    doReloadBundle();
                                }
                            }
                        } else {
                            if (failListener != null) {
                                failListener.onFail(NPReactManagerTask.Md5VerifyFail);
                            }

                        }
                    } else {
                        if (failListener != null) {
                            failListener.onFail(NPReactManagerTask.GetSourceFail);
                        }
                    }
                } else {
                    if (failListener != null) {
                        failListener.onFail(NPReactManagerTask.GetSourceFail);
                    }
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                if (failListener != null) {
                    failListener.onFail(NPReactManagerTask.GetSourceFail);
                }
            }
        });
    }

    /**
     * 解压
     */
    public void unzipBundle() {
        String downloadFilePath = ReactPreference.getInstance().getString(businessName + NEW_BUNDLE_PATH);
        String rnDir = sourceDir + businessName + "/";
        File fileRNDir = new File(rnDir);
        if (!fileRNDir.exists()) {
            fileRNDir.mkdirs();
        }
        File file = new File(downloadFilePath);
        if (file.exists()) {
            //a、解压到rnSourceDir下
            FileUtils.upZipFile(file, rnDir);
            //b、type为"0"，bundle合并；否则继续
            if (type.equals("0")) {
                String patchStr = getJsBundle(rnDir + "increment.jsbundle", false);
                String assetsBundle = getJsBundle(rnDir + bundleName, false);
                merge(patchStr, assetsBundle, rnDir);
            }
            //c、解析assetsConfig.txt，获取到需要删除的资源文件，进而删除
            if (!isAll) {
                byte[] bytes = FileUtils.readFile(rnDir + "assetsConfig.txt");
                String configDetail = new String(bytes);
                checkAssetconfigFile(configDetail, rnDir);
                FileUtils.deleteFile(rnDir + "increment.jsbundle");
                FileUtils.deleteFile(rnDir + "assetsConfig.txt");
            }
            updateReactFonts();
            FileUtils.delete(file);
        }
    }

    /**
     * 重新加载指定目录的rn的bundle资源
     */
    public void doReloadBundle() {
        String remoteDataVersion = ReactPreference.getInstance().getString(businessName + NEW_BUNDLE_VERSION);
        String rnDir = sourceDir + businessName + "/";
        File file = new File(rnDir + File.separator + bundleName);
        if (file == null || !file.exists()) {
            Log.i(TAG, "js bundle file download error, check URL or network state");
            return;
        }
        Log.i(TAG, "js bundle file file success, reload js bundle");
        try {
            Class<?> rnManagerClazz = rnInstanceManager.getClass();

            try {

                Field f = rnManagerClazz.getDeclaredField("mJSCConfig");
                f.setAccessible(true);

                Object jscConfig = f.get(rnInstanceManager);
                Method getConfigMapMethod = jscConfig.getClass().getDeclaredMethod("getConfigMap");
                Object jsConfigMap = getConfigMapMethod.invoke(jscConfig);

                Class jsConfigClass = Class.forName("com.facebook.react.bridge.JavaScriptExecutor$Factory");
                Method method = rnManagerClazz.getDeclaredMethod("recreateReactContextInBackground",
                        jsConfigClass,
                        com.facebook.react.bridge.JSBundleLoader.class);
                method.setAccessible(true);

                Class jsConfigFactoryClass = Class.forName("com.facebook.react.bridge.JSCJavaScriptExecutor$Factory");
                method.invoke(rnInstanceManager,
                        jsConfigFactoryClass.getDeclaredConstructor(WritableNativeMap.class).newInstance(jsConfigMap),
                        com.facebook.react.bridge.JSBundleLoader.createFileLoader(rnDir + bundleName));
            } catch (Exception ex) {

                Field f = rnManagerClazz.getDeclaredField("mJavaScriptExecutorFactory");
                f.setAccessible(true);
                Object jscConfig = f.get(rnInstanceManager);

                Method method = rnManagerClazz.getDeclaredMethod("recreateReactContextInBackground",
                        Class.forName("com.facebook.react.bridge.JavaScriptExecutorFactory"),
                        com.facebook.react.bridge.JSBundleLoader.class);
                method.setAccessible(true);

                method.invoke(rnInstanceManager,
                        jscConfig,
                        com.facebook.react.bridge.JSBundleLoader.createFileLoader(rnDir + bundleName));
            }


        } catch (Exception e) {
            e.printStackTrace();
        }
        ReactPreference.getInstance().save(businessName + BUNDLE_VERSION, remoteDataVersion);
        ReactPreference.getInstance().delete(businessName + NEW_BUNDLE_PATH);
        ReactPreference.getInstance().delete(businessName + NEW_BUNDLE_VERSION);
    }

    /******************************tools*******************************/
    /**
     * 获取指定bundle文件内容
     *
     * @param patPath  bundle文件路径
     * @param isAssets 是否为assets下
     * @return string
     */
    private String getJsBundle(String patPath, boolean isAssets) {
        String result = "";
        try {
            InputStream is;
            if (isAssets) {
                is = application.getAssets().open(bundleName);
            } else {
                is = new FileInputStream(patPath);
            }
            int size = is.available();
            byte[] buffer = new byte[size];
            is.read(buffer);
            is.close();
            result = new String(buffer, "utf-8");
        } catch (Exception e) {
            e.printStackTrace();
        }
        return result;
    }

    /**
     * 增量包和旧包合并
     *
     * @param patchStr 增量包内容
     * @param bundle   旧bundle包内容
     * @param rnDir    更新后的bundle路径
     */
    private void merge(String patchStr, String bundle, String rnDir) {
        DiffMatchPatchUtils dmp = new DiffMatchPatchUtils();
        // 转换pat
        LinkedList<DiffMatchPatchUtils.Patch> pathes = (LinkedList<DiffMatchPatchUtils.Patch>) dmp.patch_fromText(patchStr);
        // pat与bundle合并，生成新的bundle
        Object[] bundleArray = dmp.patch_apply(pathes, bundle);
        // 保存新的bundle文件
        try {
            Writer writer = new FileWriter(rnDir + bundleName);
            String newBundle = (String) bundleArray[0];
            writer.write(newBundle);
            writer.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 读取assets配置文件，删除需要删除的文件
     *
     * @param configDetail 配置文件内容
     * @param rnDir        删除初始路径
     */
    private void checkAssetconfigFile(String configDetail, String rnDir) {
        String[] lines = configDetail.split(",");
        for (String line : lines) {
            if (!TextUtils.isEmpty(line)) {
                File file = new File(rnDir + line);
                if (file.exists() && file.isFile()) {
                    FileUtils.delete(file);
                }
            }
        }
    }

    /**
     * 取消当前的热更新请求
     */
    public void cancelRequest() {
        if (configCall != null && !configCall.isCanceled()) {
            configCall.cancel();
        }
        if (bundleCall != null && !bundleCall.isCanceled()) {
            bundleCall.cancel();
        }
    }

    /**
     * destroy ReactInstanceManager
     */
    public void destroyReactInstanceManager() {
        if (rnInstanceManager != null) {
            rnInstanceManager.destroy();
        }
    }

    /**
     * 获取当前activity
     *
     * @return Activity 当前activity
     */
    public Activity getCurrentActivity() {
        return currentActivity;
    }

    /**
     * 设置当前activity
     *
     * @param currentActivity 当前activity
     */
    public void setCurrentActivity(Activity currentActivity) {
        this.currentActivity = currentActivity;
    }

    /**
     * Gets rn instance manager.
     *
     * @return the rn instance manager
     */
    public ReactInstanceManager getRnInstanceManager() {
        return rnInstanceManager;
    }

    /**
     * 设置资源请求路径
     *
     * @param sourceUrl 请求路径
     */
    public void setSourceUrl(String sourceUrl) {
        this.sourceUrl = sourceUrl;
    }

    /**
     * 获取入口文件名称
     *
     * @return String 文件名称
     */
    public String getJsMainModuleName() {
        return jsMainModuleName;
    }

    /**
     * 设置启动文件名称
     *
     * @param jsMainModuleName 启动文件名称
     */
    public void setJsMainModuleName(String jsMainModuleName) {
        this.jsMainModuleName = jsMainModuleName;
    }

    /**
     * 获取bundle名字
     *
     * @return String bundle名字
     */
    public String getBundleName() {
        return bundleName;
    }

    /**
     * 设置bundle名字
     *
     * @param bundleName bundle名字
     */
    public void setBundleName(String bundleName) {
        this.bundleName = bundleName;
    }

    public SuccessListener getSuccessListener() {
        return successListener;
    }

    public void setSuccessListener(SuccessListener successListener) {
        this.successListener = successListener;
    }

    public FailListener getFailListener() {
        return failListener;
    }

    public void setFailListener(FailListener failListener) {
        this.failListener = failListener;
    }


    /**
     * 获取业务名
     *
     * @return
     */
    public String getBusinessName() {
        return businessName;
    }

    /**
     * 设置业务名
     *
     * @param businessName 业务名
     */
    public void setBusinessName(String businessName) {
        this.businessName = businessName;
    }

    /**
     * 获取ReactRootView
     *
     * @param moduleName moudule名
     * @param context    Context
     * @param bundle     Bundle参数
     * @return ReactRootView react view by module name
     */
    public ReactRootView getReactViewByModuleName(String moduleName, Context context, Bundle bundle) {
        ReactRootView rnRootView = new ReactRootView(context);
        rnRootView.setLayoutParams(new RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        rnRootView.startReactApplication(rnInstanceManager, moduleName, bundle);
        if (rnRootView != null && rnRootView.getParent() != null) {
            ((ViewGroup) rnRootView.getParent()).removeView(rnRootView);
        }
        return rnRootView;
    }

    /**
     * 是否有最新的rn资源版本
     *
     * @return boolean true为有，false为没有
     */
    public boolean hasNewVersion() {
        String newVersion = ReactPreference.getInstance().getString(businessName + NEW_BUNDLE_VERSION);
        return !TextUtils.isEmpty(newVersion);
    }

    /**
     * 获取app版本，包含当前的rn资源版本号
     *
     * @return String 包含rn资源版本号的的版本号
     */
    public String getReactVersion() {
        String dataVersion = ReactPreference.getInstance().getString(businessName + BUNDLE_VERSION);
        if (TextUtils.isEmpty(dataVersion)) {
            return apkVersion;
        }
        return apkVersion + "_" + dataVersion;
    }

    public interface SuccessListener {
        abstract void onSuccess();
    }

    public interface FailListener {
        abstract void onFail(NPReactManagerTask task);
    }
}

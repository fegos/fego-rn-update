package com.fego.android.utils;

import android.content.res.AssetManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * assets相关操作
 * Created by wangxiang on 2017/9/18.
 */
public class AssetUtil {

    /**
     * 将assets下文件夹拷贝到指定目录
     *
     * @param assetManager  assetManager
     * @param fromAssetPath assets下路径
     * @param toPath        要拷贝到路径
     * @return boolean true为成功，false为失败
     */
    public static boolean copyAssetFolder(AssetManager assetManager, String fromAssetPath, String toPath) {
        try {
            String[] files = assetManager.list(fromAssetPath);
            new File(toPath).mkdirs();
            boolean res = true;
            for (String file : files)
                if (file.contains("."))
                    res &= copyAsset(assetManager,
                            fromAssetPath + "/" + file,
                            toPath + "/" + file);
                else
                    res &= copyAssetFolder(assetManager,
                            fromAssetPath + "/" + file,
                            toPath + "/" + file);
            return res;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 将assets下文件拷贝到指定目录
     *
     * @param assetManager  assetManager
     * @param fromAssetPath assets下路径
     * @param toPath        要拷贝到路径
     * @return boolean true为成功，false为失败
     */
    public static boolean copyAsset(AssetManager assetManager, String fromAssetPath, String toPath) {
        InputStream in = null;
        OutputStream out = null;
        try {
            in = assetManager.open(fromAssetPath);
            new File(toPath).createNewFile();
            out = new FileOutputStream(toPath);
            copyFile(in, out);
            in.close();
            in = null;

            out.flush();
            out.close();
            out = null;

            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 文件拷贝
     *
     * @param in  InputStream
     * @param out OutputStream
     */
    public static void copyFile(InputStream in, OutputStream out) {
        try {
            byte[] buffer = new byte[1024];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

}

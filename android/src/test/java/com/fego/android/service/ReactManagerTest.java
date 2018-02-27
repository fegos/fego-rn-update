
package com.fego.android.service;

import android.app.Application;
import android.os.Environment;
import android.util.Log;

import com.fego.android.BuildConfig;
import com.fego.android.utils.FileUtils;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

import java.io.File;
import java.math.BigInteger;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.security.MessageDigest;
import java.util.concurrent.CountDownLatch;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

import static org.junit.Assert.*;

/**
 * Created by sxiaoxia on 2018/1/8.
 */
public class ReactManagerTest {

    private Call<ResponseBody> configCall;
    private Call<ResponseBody> bundleCall;
    private String sourceUrl = "https://raw.githubusercontent.com/fegos/fego-rn-update/master/demo/increment/android/increment/";
    private String configDetail = "";
    private String configDetailTest = "1.0_2_0_0_312442971cb56abeddac047103ee0a31,1.0_2_1_0_8e02a4e335afe618e57b574e9ff07368";
    CountDownLatch latch = new CountDownLatch(1);
    CountDownLatch latch2 = new CountDownLatch(1);
    Application application;
    /**
     * 本地的版本
     */
    private String localDataVersion = "0";
    /**
     * 本地sdk版本号
     */
    private String localSdkVersion = "1.0";
    /**
     * 用来临时记录增量还是全量
     */
    private String type = null;
    /**
     * 用来临时记录zip包的md5值
     */
    private String md5Value = "";
    String remoteSdkVersion = "";
    String remoteDataVersion = "";
//    String remoteMd5 = "";
    boolean isSuc = false;

    @Before
    public void setUp() throws Exception {
        application = RuntimeEnvironment.application;
    }

    @After
    public void tearDown() throws Exception {
    }

    /**
     * 1、下载config
     * @throws Exception
     */
    @Test
    public void loadBundleBehind() throws Exception {
        ReactService service = new ReactService();
        configCall = service.downloadFile(sourceUrl + "config", new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    try {
                        configDetail = response.body().source().readUtf8();
                        System.out.println(response.body().source().readUtf8());
                    } catch (Exception e) {
                        configDetail = "fail";
                        e.printStackTrace();
                    }
                } else {
                    configDetail = "fail";
                }
                latch.countDown();
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                configDetail = "fail";
                latch.countDown();
            }
        });
        latch.await();
        assertEquals("1.0_2_0_0_312442971cb56abeddac047103ee0a31,1.0_2_1_0_8e02a4e335afe618e57b574e9ff07368,", configDetail);
    }
    /**
     * 2、解析config
     */
    @Test
    public void checkRNConfigFile() throws Exception {
        String[] lines = configDetailTest.split(",");
        for (String line : lines) {
            String[] infos = line.split("_");
            if (infos.length > 1) {
                remoteSdkVersion = infos[0];
                remoteDataVersion = infos[1];
                String localDataVer = infos[2];
                if (!localDataVer.equals(localDataVersion)) {
                    continue;
                }
                type = infos[3];
                md5Value = infos[4];
            }
        }
        assertEquals("312442971cb56abeddac047103ee0a31", md5Value);
        assertEquals(localSdkVersion, remoteSdkVersion);
    }

    /**
     * 3、下载bundle
     * @throws Exception
     */
    @Test
    public void loadRNSource() throws Exception {
        ReactService service = new ReactService();
        final String rnZipName = "rn_" + localSdkVersion + "_" + "2" + "_" + localDataVersion + "_" + "0" + ".zip";
        String rnSourceUrl = sourceUrl + localSdkVersion + "/" + "2" + "/" + rnZipName;
        bundleCall = service.downloadFile(rnSourceUrl, new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    isSuc = true;
                } else {
                    isSuc = false;
                }
                latch2.countDown();
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                isSuc = false;
                latch2.countDown();
            }
        });
        latch2.await();
        assertEquals(true, isSuc);
    }
}

package com.fego.android.utils;

import com.fego.android.BuildConfig;

import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

import java.io.File;
import java.net.URL;

import okhttp3.MediaType;
import okhttp3.ResponseBody;
import okio.BufferedSource;

import static org.junit.Assert.*;

/**
 * Created by sxiaoxia on 2018/2/27.
 */
@RunWith(RobolectricTestRunner.class)
@Config(constants = BuildConfig.class, manifest=Config.NONE)
public class FileUtilsTest {

    String filePath = "hello.txt";
    ClassLoader classLoader = getClass().getClassLoader();
    URL resource = classLoader.getResource(filePath);
    String path = resource.getPath();
    File file = new File(path);


    @Before
    public void setUp() throws Exception {

    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void delete() throws Exception {
        String filePath = "world.txt";
        ClassLoader classLoader = getClass().getClassLoader();
        URL resource = classLoader.getResource(filePath);
        String path = resource.getPath();
        File file = new File(path);
        boolean suc = FileUtils.delete(file);
        Assert.assertEquals(true, suc);
    }

    @Test
    public void readFile() throws Exception {
        byte[] content = FileUtils.readFile(path);
        byte[] temp = "hello world".getBytes();
        Assert.assertEquals(new String(content), new String(temp));
    }

    @Test
    public void writeFile() throws Exception {
        boolean suc = FileUtils.writeFile("hello world".getBytes(), path);
        Assert.assertEquals(true, suc);
    }

    @Test
    public void upZipFile() throws Exception {
        String filePath = "test.zip";
        ClassLoader classLoader = getClass().getClassLoader();
        URL resource = classLoader.getResource(filePath);
        String path = resource.getPath();
        File file = new File(path);
        boolean suc = FileUtils.upZipFile(file,"build");
        Assert.assertEquals(true, suc);
    }

    @Test
    public void deleteFile() throws Exception {
        String filePath = "test.txt";
        ClassLoader classLoader = getClass().getClassLoader();
        URL resource = classLoader.getResource(filePath);
        String path = resource.getPath();
        boolean suc = FileUtils.deleteFile(path);
        Assert.assertEquals(true, suc);
    }

    @Test
    public void getMd5ByFile() throws Exception {
        String tempMd5 = FileUtils.getMd5ByFile(file);
        assertEquals("5eb63bbbe01eeed093cb22bb8f5acdc3", tempMd5);
    }

}
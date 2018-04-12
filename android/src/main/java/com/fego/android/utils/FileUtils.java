package com.fego.android.utils;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigInteger;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.security.MessageDigest;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import okhttp3.ResponseBody;

/**
 * 文件处理
 * Created by sxiaoxia on 2017/12/6.
 */
public class FileUtils {

    /**
     * 删除文件或者目录
     *
     * @param file File
     * @return boolean true为删除成功，false为删除失败
     */
    public static boolean delete(File file) {
        if (file == null) {
            return false;
        }
        if (file.isFile()) {
            return file.delete();
        }
        if (file.isDirectory()) {
            File[] arrayOfFile = file.listFiles();
            for (File localFile : arrayOfFile) {
                delete(localFile);
            }
        }
        return file.delete();
    }


    /**
     * 读文件
     *
     * @param fileName 要读的文件
     * @return byte[] 文件内容
     */
    public static byte[] readFile(String fileName) {
        try {
            FileInputStream fin = new FileInputStream(fileName);
            int length = fin.available();
            byte[] buffer = new byte[length];
            fin.read(buffer);
            fin.close();
            return buffer;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;

    }

    /**
     * 写文件
     *
     * @param data         要写入的内容
     * @param fileFullName 写入的文件
     */
    public static boolean writeFile(byte[] data, String fileFullName) {
        try {
            File file = new File(fileFullName);
            FileOutputStream fileOutputStream = new FileOutputStream(file);
            fileOutputStream.write(data);
            fileOutputStream.flush();
            fileOutputStream.close();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 解压缩功能.
     * 将zipFile文件解压到folderPath目录下.
     *
     * @param zipFile    zip文件
     * @param folderPath 解压的目标路径
     */
    public static boolean upZipFile(File zipFile, String folderPath) {
        try {
            ZipFile zFile = new ZipFile(zipFile);
            Enumeration zList = zFile.entries();
            ZipEntry ze = null;
            byte[] buf = new byte[1024];
            while (zList.hasMoreElements()) {
                ze = (ZipEntry) zList.nextElement();
                if (ze != null && ze.isDirectory()) {
                    String dirStr = folderPath + File.separator + ze.getName();
                    File f = new File(dirStr);
                    if (!f.exists()) {
                        f.mkdir();
                    }
                    continue;
                }

                File realFile = getRealFileName(folderPath, ze.getName());
                FileOutputStream outputStream = new FileOutputStream(realFile);
                OutputStream os = new BufferedOutputStream(outputStream);
                InputStream is = new BufferedInputStream(zFile.getInputStream(ze));
                int readLen = 0;
                while ((readLen = is.read(buf, 0, 1024)) != -1) {
                    os.write(buf, 0, readLen);
                }
                is.close();
                os.close();
            }
            zFile.close();
            return true;
        } catch (Exception ex) {
            ex.printStackTrace();
            return false;
        }
    }

    /**
     * 给定根目录，返回一个相对路径所对应的实际文件名.
     *
     * @param baseDir     指定根目录
     * @param absFileName 相对路径名，来自于ZipEntry中的name
     * @return java.io.File 实际的文件
     */
    public static File getRealFileName(String baseDir, String absFileName) {
        String[] dirs = absFileName.split("/");
        if (dirs.length > 1) {
            String subStr = null;
            File ret = new File(baseDir);
            for (int i = 0; i < dirs.length - 1; i++) {
                subStr = dirs[i];
                ret = new File(ret, subStr);
            }
            if (!ret.exists()) {
                ret.mkdirs();
            }
            subStr = dirs[dirs.length - 1];
            ret = new File(ret, subStr);
            return ret;
        } else {
            return new File(baseDir, absFileName);
        }
    }

    /**
     * 删除某路径下的文件
     *
     * @param filePath 文件路径
     */
    public static boolean deleteFile(String filePath) {
        File patFile = new File(filePath);
        if (patFile.exists()) {
            return patFile.delete();
        } else {
            return false;
        }
    }

    /**
     * 将下载后的文件写入到磁盘的函数
     *
     * @param body 请求返回body
     * @param file 下载的文件
     * @return boolean true为写入成功，false为写入失败
     */
    public static boolean writeResponseBodyToDisk(ResponseBody body, File file) {
        try {
            File futureFile = file;
            InputStream inputStream = null;
            OutputStream outputStream = null;
            try {
                byte[] fileReader = new byte[4096];
                inputStream = body.byteStream();
                outputStream = new FileOutputStream(futureFile);
                while (true) {
                    int read = inputStream.read(fileReader);
                    if (read == -1) {
                        break;
                    }
                    outputStream.write(fileReader, 0, read);
                }
                outputStream.flush();
                return true;
            } catch (Exception e) {
                return false;
            } finally {
                if (inputStream != null) {
                    inputStream.close();
                }
                if (outputStream != null) {
                    outputStream.close();
                }
            }
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 获取文件md5值
     * @param file
     * @return String 文件md值
     */
    public static String getMd5ByFile(File file) {
        String value = null;
        FileInputStream in = null;
        try {
            in = new FileInputStream(file);
            MappedByteBuffer byteBuffer = in.getChannel().map(FileChannel.MapMode.READ_ONLY, 0, file.length());
            MessageDigest md5 = MessageDigest.getInstance("MD5");
            md5.update(byteBuffer);
            BigInteger bi = new BigInteger(1, md5.digest());
            value = String.format("%032x", bi);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if(in != null) {
                try {
                    in.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return value;
    }

}

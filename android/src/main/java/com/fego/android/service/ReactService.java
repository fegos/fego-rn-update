package com.fego.android.service;

import android.util.Log;

import java.io.IOException;
import java.util.HashMap;
import java.util.concurrent.TimeUnit;

import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.http.GET;
import retrofit2.http.QueryMap;
import retrofit2.http.Url;

/**
 * 网络请求相关service
 * Created by wx on 17/3/27.
 */
public class ReactService {
    /**
     * The constant TAG.
     */
    public static final String TAG = "SERVICE";

    /**
     * The constant BASE_URL.
     */
    public static final String BASE_URL = "http://example.com/";
    /**
     * The constant okHttpClient.
     */
    public static OkHttpClient okHttpClient;
    /**
     * The constant retrofit.
     */
    public static Retrofit retrofit;

    static {
        okHttpClient = (new OkHttpClient.Builder()).readTimeout(60L, TimeUnit.SECONDS)
                .writeTimeout(60L, TimeUnit.SECONDS)
                .connectTimeout(20L, TimeUnit.SECONDS)
                .addInterceptor(new Interceptor() {

                    public Response intercept(Chain chain) throws IOException {
                        Request original = chain.request();
                        okhttp3.Request.Builder requestBuilder = this.createBuilder(original);
                        long start = System.nanoTime();
                        Request request = requestBuilder.build();
                        Response response = chain.proceed(request);
                        long elapsedTime = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);
                        Log.d(TAG, "请求耗时" + String.valueOf(elapsedTime) + "ms");
                        return response;
                    }

                    private okhttp3.Request.Builder createBuilder(Request original) {
                        return original.newBuilder().method(original.method(), original.body());
                    }

                }).build();

        retrofit = (new retrofit2.Retrofit.Builder())
                .baseUrl(BASE_URL)
                .addConverterFactory(GsonConverterFactory.create())
                .callFactory(okHttpClient)
                .build();
    }

    /**
     * Instantiates a new React service.
     */
    public ReactService() {
    }

    /**
     * Download file call.
     *
     * @param url      the url
     * @param callback the callback
     * @return the call
     */
    public static Call<ResponseBody> downloadFile(String url, Callback<ResponseBody> callback) {
        IReactUpdateService serviceInterface = retrofit.create(IReactUpdateService.class);
        Call<ResponseBody> call = serviceInterface.downloadFile(url, new HashMap<String, String>());
        call.enqueue(callback);
        return call;
    }

    private interface IReactUpdateService {
        /**
         * Download file call.
         *
         * @param path   the path
         * @param params the params
         * @return the call
         */
        @GET
        Call<ResponseBody> downloadFile(@Url String path, @QueryMap HashMap<String, String> params);
    }
}

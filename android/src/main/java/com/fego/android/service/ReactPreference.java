package com.fego.android.service;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.preference.PreferenceManager;

/**
 * shareprefs存储
 * Created by wx on 17/3/27.
 */
public class ReactPreference {

    protected SharedPreferences prefs;
    protected boolean mUseApply;
    private static ReactPreference instance;

    public static ReactPreference getInstance() {
        if (instance == null) {
            synchronized (ReactPreference.class) {
                if (instance == null) {
                    instance = new ReactPreference();
                }
            }
        }
        return instance;
    }

    public void setContext(Context context) {
        mUseApply = Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD;
        prefs = PreferenceManager.getDefaultSharedPreferences(context);
    }

    public void save(String key, String value) {
        if (prefs != null) {
            SharedPreferences.Editor editor = prefs.edit();
            editor.putString(key, value);
            if (mUseApply) {
                editor.apply();
            } else {
                editor.commit();
            }
        }
    }

    public int getInt(String key) {
        if (prefs != null) {
            return prefs.getInt(key, 0);
        } else {
            return 0;
        }
    }

    public void saveInt(String key, int value) {
        if (prefs != null) {
            SharedPreferences.Editor editor = prefs.edit();
            editor.putInt(key, value);
            if (mUseApply) {
                editor.apply();
            } else {
                editor.commit();
            }
        }
    }

    public String getString(String key) {
        if (prefs != null) {
            return prefs.getString(key, "");
        } else {
            return "";
        }
    }

    public void delete(String key) {
        if (prefs != null) {
            SharedPreferences.Editor editor = prefs.edit();
            editor.remove(key);
            if (mUseApply) {
                editor.apply();
            } else {
                editor.commit();
            }
        }
    }
}

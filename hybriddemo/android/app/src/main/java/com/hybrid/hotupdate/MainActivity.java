package com.hybrid.hotupdate;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import com.fego.android.service.ReactManager;
import com.hybrid.hotupdate.rn.RNActivity;
import com.hybrid.hotupdate.utils.ConfigUtil;

public class MainActivity extends Activity implements View.OnClickListener, ReactManager.SuccessListener {

    Button btnRn1, btnRn2;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        initViews();
        ConfigUtil.getInstance().initReactManager(getApplication());
        ReactManager.getInstance().setSuccessListener(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        ReactManager.getInstance().loadBundleBehind();
    }

    private void initViews() {
        btnRn1 = (Button) findViewById(R.id.btn_rn1);
        btnRn2 = (Button) findViewById(R.id.btn_rn2);
        btnRn1.setOnClickListener(this);
        btnRn2.setOnClickListener(this);
    }

    @Override
    public void onClick(View view) {
        if (view == btnRn1) {
            Intent intent = new Intent(this, RNActivity.class);
            Bundle bundle = new Bundle();
            bundle.putString("moduleName", "First");
            intent.putExtras(bundle);
            startActivity(intent);
        } else if (view == btnRn2) {
            Intent intent = new Intent(this, RNActivity.class);
            Bundle bundle = new Bundle();
            bundle.putString("moduleName", "Second");
            intent.putExtras(bundle);
            startActivity(intent);
        }
    }

    @Override
    public void onSuccess() {
        questionUpdateReactSource();
    }

    /**
     * 询问是否更新最新包提示
     */
    protected void questionUpdateReactSource() {
        //此处标记已经下载了新的rn资源包,提示用户是否进行更新
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("温馨提示")
                .setMessage("有新的资源包可以更新，是否立即更新?")
                .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        dialog.cancel();
                    }
                })
                .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        ReactManager.getInstance().unzipBundle();
                        ReactManager.getInstance().doReloadBundle();
                        // 下次启动应用时更新
                        // ReactManager.getInstance().unzipBundle();
                    }
                })
                .create();
        dialog.show();
    }
}

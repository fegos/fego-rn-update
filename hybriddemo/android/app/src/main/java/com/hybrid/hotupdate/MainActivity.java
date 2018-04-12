package com.hybrid.hotupdate;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import com.fego.android.service.ReactManager;
import com.hybrid.hotupdate.rn.RNHelloActivity;
import com.hybrid.hotupdate.rn.RNWorldActivity;
import com.hybrid.hotupdate.utils.ConfigUtil;

public class MainActivity extends Activity implements View.OnClickListener {

    Button btnRn1, btnRn2;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        initViews();
        updateData();
    }

    @Override
    protected void onResume() {
        super.onResume();
//        ReactManager.getInstance().loadBundleBehind();
    }

    private void updateData () {
        ConfigUtil.getInstance().initReactManager(getApplication(), "index","index.jsbundle","common");
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
            Intent intent = new Intent(this, RNHelloActivity.class);
            Bundle bundle = new Bundle();
            bundle.putString("moduleName", "First");
            intent.putExtras(bundle);
            startActivity(intent);
        } else if (view == btnRn2) {
            Intent intent = new Intent(this, RNWorldActivity.class);
            Bundle bundle = new Bundle();
            bundle.putString("moduleName", "Second");
            intent.putExtras(bundle);
            startActivity(intent);
        }
    }
}

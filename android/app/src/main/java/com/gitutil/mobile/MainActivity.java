package com.gitutil.mobile;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private AlertDialog errorDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button launchAppButton = findViewById(R.id.launchAppButton);

        // Launch the standalone GitUtil app
        launchAppButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                launchGitUtil();
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // Dismiss dialog if it's showing to prevent window leak
        if (errorDialog != null && errorDialog.isShowing()) {
            errorDialog.dismiss();
            errorDialog = null;
        }
    }

    private void launchGitUtil() {
        try {
            Intent intent = new Intent(this, GitUtilActivity.class);
            startActivity(intent);
        } catch (Exception e) {
            showError("Could not launch GitUtil: " + e.getMessage());
        }
    }

    private void showError(String message) {
        // Dismiss any existing error dialog
        if (errorDialog != null && errorDialog.isShowing()) {
            errorDialog.dismiss();
        }
        
        errorDialog = new AlertDialog.Builder(this)
                .setTitle("Error")
                .setMessage(message)
                .setPositiveButton("OK", null)
                .show();
    }
}

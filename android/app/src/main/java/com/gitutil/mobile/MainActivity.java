package com.gitutil.mobile;

import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private AlertDialog errorDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        TextView infoText = findViewById(R.id.infoText);
        Button installTermuxButton = findViewById(R.id.installTermuxButton);
        Button downloadPackageButton = findViewById(R.id.downloadPackageButton);
        Button viewDocsButton = findViewById(R.id.viewDocsButton);

        installTermuxButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openFDroidTermux();
            }
        });

        downloadPackageButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openGitHubReleases();
            }
        });

        viewDocsButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openDocumentation();
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

    private void openFDroidTermux() {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setData(Uri.parse("https://f-droid.org/en/packages/com.termux/"));
            startActivity(intent);
        } catch (ActivityNotFoundException e) {
            showError("Could not open F-Droid. Please install a web browser.");
        }
    }

    private void openGitHubReleases() {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setData(Uri.parse("https://github.com/felix-dieterle/GitUtil/releases"));
            startActivity(intent);
        } catch (ActivityNotFoundException e) {
            showError("Could not open GitHub. Please install a web browser.");
        }
    }

    private void openDocumentation() {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setData(Uri.parse("https://github.com/felix-dieterle/GitUtil#mobile-interface-androidtermux"));
            startActivity(intent);
        } catch (ActivityNotFoundException e) {
            showError("Could not open documentation. Please install a web browser.");
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

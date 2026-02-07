package com.gitutil.mobile;

import android.Manifest;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

/**
 * WebView-based activity for GitUtil Mobile interface
 * Provides standalone git operations without Termux
 */
public class GitUtilActivity extends AppCompatActivity {
    
    private static final int PERMISSION_REQUEST_CODE = 1;
    private WebView webView;
    private GitBridge gitBridge;
    private boolean waitingForPermissionFromSettings = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Request storage permissions for accessing git repositories
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)
                    != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this,
                    new String[]{
                        Manifest.permission.READ_EXTERNAL_STORAGE,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE
                    },
                    PERMISSION_REQUEST_CODE);
            } else {
                initializeWebView();
            }
        } else {
            initializeWebView();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                initializeWebView();
            } else {
                showPermissionDeniedDialog();
            }
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Re-check permissions when returning from Settings
        if (waitingForPermissionFromSettings && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)
                    == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    == PackageManager.PERMISSION_GRANTED) {
                waitingForPermissionFromSettings = false;
                initializeWebView();
            }
        }
    }

    private void showPermissionDeniedDialog() {
        waitingForPermissionFromSettings = true;
        new AlertDialog.Builder(this)
            .setTitle("Storage Permission Required")
            .setMessage("GitUtil needs storage access to manage git repositories. Please grant permission in Settings.")
            .setPositiveButton("Open Settings", (dialog, which) -> {
                // Open app settings page
                Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                Uri uri = Uri.fromParts("package", getPackageName(), null);
                intent.setData(uri);
                startActivity(intent);
            })
            .setNegativeButton("Cancel", (dialog, which) -> {
                waitingForPermissionFromSettings = false;
                finish();
            })
            .setCancelable(false)
            .show();
    }

    private void initializeWebView() {
        // Create WebView
        webView = new WebView(this);
        setContentView(webView);

        // Configure WebView settings
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        
        // Create and add JavaScript bridge
        gitBridge = new GitBridge();
        webView.addJavascriptInterface(gitBridge, "AndroidBridge");
        
        // Set WebView client to handle navigation
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                // Keep navigation within WebView
                return false;
            }
        });

        // Handle back button using modern API
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (webView != null && webView.canGoBack()) {
                    webView.goBack();
                } else {
                    setEnabled(false);
                    getOnBackPressedDispatcher().onBackPressed();
                }
            }
        });

        // Load the HTML interface from assets
        webView.loadUrl("file:///android_asset/touch-ui.html");
    }
}

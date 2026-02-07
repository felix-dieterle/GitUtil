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
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
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
        
        // Check and request storage permissions based on Android version
        if (!hasStoragePermission()) {
            requestStoragePermission();
        } else {
            initializeWebView();
        }
    }
    
    /**
     * Check if the app has the required storage permissions
     */
    private boolean hasStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ requires MANAGE_EXTERNAL_STORAGE
            return Environment.isExternalStorageManager();
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6-10 uses READ/WRITE_EXTERNAL_STORAGE
            return ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)
                    == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    == PackageManager.PERMISSION_GRANTED;
        } else {
            // Below Android 6, permissions are granted at install time
            return true;
        }
    }
    
    /**
     * Request storage permissions based on Android version
     */
    private void requestStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+: Show dialog and redirect to MANAGE_EXTERNAL_STORAGE settings
            showPermissionDeniedDialog();
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6-10: Request READ/WRITE_EXTERNAL_STORAGE at runtime
            ActivityCompat.requestPermissions(this,
                new String[]{
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
                },
                PERMISSION_REQUEST_CODE);
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
        if (waitingForPermissionFromSettings) {
            if (hasStoragePermission()) {
                waitingForPermissionFromSettings = false;
                initializeWebView();
            }
        }
    }

    private void showPermissionDeniedDialog() {
        waitingForPermissionFromSettings = true;
        
        String message;
        Intent intent;
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+
            message = "GitUtil needs All Files Access permission to manage git repositories. " +
                     "Please enable \"Allow access to manage all files\" in the app settings.";
            intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
        } else {
            // Android 6-10
            message = "GitUtil needs storage access to manage git repositories. " +
                     "Please grant the Storage permission in the app settings.";
            intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        }
        
        Uri uri = Uri.fromParts("package", getPackageName(), null);
        intent.setData(uri);
        
        final Intent settingsIntent = intent;
        new AlertDialog.Builder(this)
            .setTitle("Storage Permission Required")
            .setMessage(message)
            .setPositiveButton("Open Settings", (dialog, which) -> {
                startActivity(settingsIntent);
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
        
        // Set WebChromeClient to handle JavaScript dialogs (alert, confirm, prompt)
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onJsConfirm(WebView view, String url, String message, JsResult result) {
                // Show a native Android dialog for JavaScript confirm()
                new AlertDialog.Builder(GitUtilActivity.this)
                    .setTitle("Confirm")
                    .setMessage(message)
                    .setPositiveButton("OK", (dialog, which) -> result.confirm())
                    .setNegativeButton("Cancel", (dialog, which) -> result.cancel())
                    .setCancelable(false)
                    .show();
                return true;
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

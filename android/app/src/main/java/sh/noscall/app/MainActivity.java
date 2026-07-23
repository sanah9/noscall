package sh.noscall.app;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.view.WindowManager;
import android.os.Bundle;
import androidx.annotation.Nullable;
import android.app.PictureInPictureParams;
import android.util.Rational;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.util.DisplayMetrics;
import android.graphics.Rect;
import android.util.Log;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "sh.noscall.native_methods";
    private static final String PIP_CHANNEL = "sh.noscall.pip";
    private boolean isVideoCallActive = false;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(new NativeMethodHandler());

        AccountSecretStore.register(this, flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PIP_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "enablePip":
                            isVideoCallActive = true;
                            result.success(true);
                            break;
                        case "disablePip":
                            isVideoCallActive = false;
                            // Exit PiP mode if currently in PiP
                            exitPictureInPictureMode();
                            result.success(true);
                            break;
                        case "isPipSupported":
                            result.success(isPictureInPictureSupported());
                            break;
                        case "enterPip":
                            if (isPictureInPictureSupported()) {
                                enterPictureInPictureMode(createPipParams());
                                result.success(true);
                            } else {
                                result.success(false);
                            }
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    @Override
    public void onUserLeaveHint() {
        super.onUserLeaveHint();
        // When user presses Home button, if video call is active, enter PiP mode
        if (isVideoCallActive && isPictureInPictureSupported()) {
            enterPictureInPictureMode(createPipParams());
        }
    }

    @Override
    public void onPictureInPictureModeChanged(
            boolean isInPictureInPictureMode,
            Configuration newConfig) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);

        // Notify Flutter about PiP state change
        if (getFlutterEngine() != null) {
            new MethodChannel(
                    getFlutterEngine().getDartExecutor().getBinaryMessenger(),
                    PIP_CHANNEL
            ).invokeMethod("onPipModeChanged", isInPictureInPictureMode);
        }
    }

    private PictureInPictureParams createPipParams() {
        PictureInPictureParams.Builder builder = new PictureInPictureParams.Builder();
        DisplayMetrics dm = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(dm);

        int width = dm.widthPixels;
        int height = dm.heightPixels;

        double ratio = (double) width / height;

        final double MIN_RATIO = 0.418410;
        final double MAX_RATIO = 2.39;

        if (ratio < MIN_RATIO) ratio = MIN_RATIO;
        else if (ratio > MAX_RATIO) ratio = MAX_RATIO;

        Rational aspectRatio = new Rational((int)(ratio * 1000), 1000);
        builder.setAspectRatio(aspectRatio);

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            builder.setSourceRectHint(new Rect(0, 0, width, height));
        }

        return builder.build();
    }

    private boolean isPictureInPictureSupported() {
        return getPackageManager().hasSystemFeature(
                PackageManager.FEATURE_PICTURE_IN_PICTURE
        );
    }

    private void exitPictureInPictureMode() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            try {
                if (isInPictureInPictureMode()) {
                    moveTaskToBack(true);
                }
            } catch (Exception e) {
                Log.e("MainActivity", "Error exiting PiP mode: " + e.getMessage());
            }
        }
    }
}

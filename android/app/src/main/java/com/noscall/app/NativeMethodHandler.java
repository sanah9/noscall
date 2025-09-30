package com.noscall.app;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class NativeMethodHandler implements MethodCallHandler {
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "audioSessionDidActivate":
            case "audioSessionDidDeactivate":
                result.notImplemented();
                break;
                
            default:
                result.notImplemented();
                break;
        }
    }
}

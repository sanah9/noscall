import UIKit
import Flutter
import AVFoundation
import WebRTC

class NativeMethodHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.noscall.native_methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = NativeMethodHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "useManualAudio":
            useManualAudio(result: result)
        case "audioSessionDidActivate":
            audioSessionDidActivate(result: result)
        case "audioSessionDidDeactivate":
            audioSessionDidDeactivate(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func useManualAudio(result: @escaping FlutterResult) {
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        result(nil)
    }
    
    private func audioSessionDidActivate(result: @escaping FlutterResult) {
        RTCAudioSession.sharedInstance().audioSessionDidActivate(AVAudioSession.sharedInstance())
        RTCAudioSession.sharedInstance().isAudioEnabled = true
        result(nil)
    }

    private func audioSessionDidDeactivate(result: @escaping FlutterResult) {
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(AVAudioSession.sharedInstance())
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        result(nil)
    }
}


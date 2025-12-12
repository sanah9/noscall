import FlutterMacOS
import AVFoundation

class MacOSPermissionsPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "sh.noscall.macos_permissions",
            binaryMessenger: registrar.messenger
        )
        let instance = MacOSPermissionsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestMicrophonePermission":
            requestMicrophonePermission(result: result)
        case "requestCameraPermission":
            requestCameraPermission(result: result)
        case "checkMicrophonePermission":
            checkMicrophonePermission(result: result)
        case "checkCameraPermission":
            checkCameraPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestMicrophonePermission(result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                result(granted)
            }
        }
    }
    
    private func requestCameraPermission(result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                result(granted)
            }
        }
    }
    
    private func checkMicrophonePermission(result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            result(true)
        case .notDetermined, .denied, .restricted:
            result(false)
        @unknown default:
            result(false)
        }
    }
    
    private func checkCameraPermission(result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            result(true)
        case .notDetermined, .denied, .restricted:
            result(false)
        @unknown default:
            result(false)
        }
    }
}

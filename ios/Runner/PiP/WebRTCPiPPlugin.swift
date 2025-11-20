import Foundation
import Flutter
import WebRTC
import AVKit

public class WebRTCPiPPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?
    private var pip: WebRTCPictureInPictureController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "sh.noscall.pip",
                                           binaryMessenger: registrar.messenger())
        let events = FlutterEventChannel(name: "sh.noscall.pip/events",
                                         binaryMessenger: registrar.messenger())

        let instance = WebRTCPiPPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        events.setStreamHandler(instance)
    }

    // MARK: - Stream

    public func onListen(withArguments args: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    public func onCancel(withArguments args: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // MARK: - Methods

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {
        case "isPipAvailable":
            if #available(iOS 15.0, *) {
                result(AVPictureInPictureController.isPictureInPictureSupported())
            } else {
                result(false)
            }

        case "startPip":
            guard let args = call.arguments as? [String: Any],
                  let trackId = args["trackId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "trackId required", details: nil))
                return
            }
            start(trackId: trackId)
            result(nil)

        case "stopPip":
            stop()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - PiP Control

    private func start(trackId: String) {
        guard #available(iOS 15.0, *) else { return }
        guard let mediaTrack = FlutterWebRTCPlugin.sharedSingleton()?.remoteTrack(forId: trackId) as? RTCVideoTrack else {
            eventSink?(["event": "error", "data": "Track not found"])
            return
        }

        if pip == nil {
            pip = WebRTCPictureInPictureController(eventSink: eventSink)
        }

        pip?.attach(track: mediaTrack)
        pip?.start()
    }

    private func stop() {
        if #available(iOS 15.0, *) {
            pip?.stop()
        }
    }
}

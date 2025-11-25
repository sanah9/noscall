import Foundation
import Flutter
import WebRTC
import AVKit

@available(iOS 15.0, *)
public class WebRTCPiPPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?
    private var pipController: VideoCallPiPController?

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "sh.noscall.pip",
            binaryMessenger: registrar.messenger()
        )

        let eventChannel = FlutterEventChannel(
            name: "sh.noscall.pip/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = WebRTCPiPPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }


    // MARK: - Event Stream

    public func onListen(withArguments args: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    public func onCancel(withArguments args: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }


    // MARK: - Method Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {

        case "isPipAvailable":
            result(AVPictureInPictureController.isPictureInPictureSupported())

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

        case "attach":
            guard let args = call.arguments as? [String: Any],
                  let trackId = args["trackId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "trackId required", details: nil))
                return
            }
            attach(trackId: trackId)
            result(nil)

        case "detach":
            detach()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }


    // MARK: - PiP Lifecycle Control

    private func attach(trackId: String) {
        guard let track = FlutterWebRTCPlugin.sharedSingleton()?.remoteTrack(forId: trackId) as? RTCVideoTrack else {
            eventSink?(["event": "error", "data": "Track not found"])
            return
        }

        if pipController == nil {
            pipController = VideoCallPiPController(eventSink: eventSink)
        }

        pipController?.attach(track: track)
    }

    private func start(trackId: String) {
        attach(trackId: trackId)
        pipController?.start()
    }

    private func stop() {
        pipController?.stop()
    }

    private func detach() {
        pipController?.detach()
    }
}


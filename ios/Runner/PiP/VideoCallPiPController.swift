import Foundation
import AVKit
import WebRTC

@available(iOS 15.0, *)
final class VideoCallPiPController: NSObject {

    private let videoCallView = SampleBufferVideoCallView()
    private let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
    private var pipController: AVPictureInPictureController?

    private weak var currentTrack: RTCVideoTrack?
    private var eventSink: FlutterEventSink?

    init(eventSink: FlutterEventSink?) {
        self.eventSink = eventSink
        super.init()

        setupPiP()
    }

    private func setupPiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("PiP not supported on this device")
            return
        }
        guard let activeVideoCallSourceView = ScreenTool.shared.rootViewController?.view else {
            print("PiP not supported on this device")
            return
        }

        pipVideoCallViewController.preferredContentSize = ScreenTool.shared.bounds.size
        videoCallView.frame = pipVideoCallViewController.view.bounds
        pipVideoCallViewController.view.addSubview(videoCallView)

        let contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: activeVideoCallSourceView,
            contentViewController: pipVideoCallViewController
        )

        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = true

        self.pipController = controller
    }

    func attach(track: RTCVideoTrack) {
        currentTrack?.remove(videoCallView)
        currentTrack = track
        track.add(videoCallView)
    }

    func detach() {
        currentTrack?.remove(videoCallView)
        currentTrack = nil
        videoCallView.reset()
        pipController?.contentSource = nil
    }

    func start() {
        guard let pipController, !pipController.isPictureInPictureActive else { return }
        pipController.startPictureInPicture()
    }

    func stop() {
        guard let pipController, pipController.isPictureInPictureActive else { return }
        pipController.stopPictureInPicture()
        pipController.contentSource = nil
    }

    func invalidate() {
        stop()
        detach()
        pipController = nil
    }

    private func pipEvent(_ name: String, extra: Any? = nil) {
        print(" PiP ", name)
        var dict: [String: Any] = ["event": name]
        if let extra = extra { dict["data"] = extra }
        eventSink?(dict)
    }
}

@available(iOS 15.0, *)
extension VideoCallPiPController: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ c: AVPictureInPictureController) {
        pipEvent("willStart")
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ c: AVPictureInPictureController) {
        pipEvent("started")
    }

    func pictureInPictureController(_ c: AVPictureInPictureController,
                                    failedToStartPictureInPictureWithError error: Error) {
        pipEvent("failed", extra: error.localizedDescription)
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ c: AVPictureInPictureController) {
        pipEvent("willStop")
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ c: AVPictureInPictureController) {
        pipEvent("stopped")
    }

    func pictureInPictureController(_ c: AVPictureInPictureController,
                                    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}

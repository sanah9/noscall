import Foundation
import AVKit
import WebRTC

@available(iOS 15.0, *)
final class VideoCallPiPController: NSObject {

    private var videoCallView: SampleBufferVideoCallView?
    private var pipController: AVPictureInPictureController?

    private weak var currentTrack: RTCVideoTrack?
    private var eventSink: FlutterEventSink?

    init(eventSink: FlutterEventSink?) {
        self.eventSink = eventSink
        super.init()
    }

    func attach(track: RTCVideoTrack) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        guard let activeVideoCallSourceView = ScreenTool.shared.rootViewController?.view else {
            return
        }
        
        let videoCallView = SampleBufferVideoCallView()
        self.videoCallView = videoCallView
        let pipVideoCallViewController = createPiPVideoCallViewController(videoCallView: videoCallView)
        
        videoCallView.activate()
        
        let controller = AVPictureInPictureController(contentSource: AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: activeVideoCallSourceView,
            contentViewController: pipVideoCallViewController
        ))
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = true

        pipController = controller

        // Bind track
        currentTrack?.remove(videoCallView)
        currentTrack = track
        track.add(videoCallView)
    }
    
    private func createPiPVideoCallViewController(videoCallView: SampleBufferVideoCallView) -> AVPictureInPictureVideoCallViewController {
        let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
        pipVideoCallViewController.preferredContentSize = ScreenTool.shared.bounds.size
        pipVideoCallViewController.view.addSubview(videoCallView)
        videoCallView.frame = pipVideoCallViewController.view.bounds
        return pipVideoCallViewController
    }

    func detach() {
        if let videoCallView = videoCallView {
            videoCallView.removeFromSuperview()
            currentTrack?.remove(videoCallView)
            videoCallView.deactivate()
        }
        videoCallView = nil
        currentTrack = nil
        pipController = nil
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

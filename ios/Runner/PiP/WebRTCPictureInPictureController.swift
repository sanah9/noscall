import Foundation
import AVKit
import WebRTC

class WebRTCPictureInPictureController: NSObject {

    private let sink = WebRTCPiPVideoSink()
    private var controller: AVPictureInPictureController?
    private weak var currentTrack: RTCVideoTrack?
    private var eventSink: FlutterEventSink?

    init(eventSink: FlutterEventSink?) {
        self.eventSink = eventSink
        super.init()

        if #available(iOS 15.0, *) {
            let source = AVPictureInPictureController.ContentSource(
                sampleBufferDisplayLayer: sink.layer,
                playbackDelegate: sink
            )
            
            controller = AVPictureInPictureController(contentSource: source)
            controller?.delegate = self
        }
    }

    func attach(track: RTCVideoTrack) {
        currentTrack?.remove(sink)
        currentTrack = track
        track.add(sink)
    }

    func start() {
        guard let controller else { return }
        sink.attachToRootView()
    }

    func stop() {
        sink.detachFromRootView()
    }

    func pipEvent(_ name: String, extra: Any? = nil) {
        var dict: [String: Any] = ["event": name]
        if let extra = extra { dict["data"] = extra }
        eventSink?(dict)
    }
}


@available(iOS 15.0, *)
extension WebRTCPictureInPictureController: AVPictureInPictureControllerDelegate {
    
    func pictureInPictureControllerDidStartPictureInPicture(_ c: AVPictureInPictureController) {
        pipEvent("started")
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ c: AVPictureInPictureController) {
        pipEvent("willStart")
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ c: AVPictureInPictureController) {
        pipEvent("willStop")
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ c: AVPictureInPictureController) {
        pipEvent("stopped")
        currentTrack?.remove(sink)
    }

    func pictureInPictureController(_ c: AVPictureInPictureController,
                                    failedToStartPictureInPictureWithError error: Error) {
        pipEvent("failed", extra: error.localizedDescription)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
    }
}

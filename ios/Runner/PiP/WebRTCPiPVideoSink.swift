import Foundation
import WebRTC
import AVFoundation
import AVKit

class WebRTCPiPVideoSink: NSObject, RTCVideoRenderer {

    let layer = AVSampleBufferDisplayLayer()
    private var formatDescription: CMVideoFormatDescription?
    private let queue = DispatchQueue(label: "webrtc.pip.render")

    override init() {
        super.init()
        layer.videoGravity = .resizeAspect
    }

    // MARK: - RTCVideoRenderer

    func setSize(_ size: CGSize) {}

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else { return }

        queue.async { [weak self] in
            guard let self = self,
                  let buffer = frame.buffer as? RTCCVPixelBuffer else { return }

            let pixelBuffer = buffer.pixelBuffer

            // Create description once
            if self.formatDescription == nil {
                var desc: CMVideoFormatDescription?
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil,
                                                             imageBuffer: pixelBuffer,
                                                             formatDescriptionOut: &desc)
                self.formatDescription = desc
            }

            guard let desc = self.formatDescription else { return }

            var timing = CMSampleTimingInfo(
                duration: .invalid,
                presentationTimeStamp: CMTime(value: CMTimeValue(frame.timeStamp), timescale: 1000),
                decodeTimeStamp: .invalid
            )

            var sampleBuffer: CMSampleBuffer?
            let status = CMSampleBufferCreateReadyWithImageBuffer(
                allocator: nil,
                imageBuffer: pixelBuffer,
                formatDescription: desc,
                sampleTiming: &timing,
                sampleBufferOut: &sampleBuffer
            )

            if status == noErr, let sample = sampleBuffer {
                if self.layer.status == .failed {
                    self.layer.flush()
                }
                self.layer.enqueue(sample)
            }
        }
    }
}

@available(iOS 15.0, *)
extension WebRTCPiPVideoSink: AVPictureInPictureSampleBufferPlaybackDelegate {
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
        
    }
    
    func pictureInPictureControllerTimeRangeForPlayback(_ controller: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ controller: AVPictureInPictureController) -> Bool {
        false
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController, skipByInterval interval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController, setPlaying playing: Bool) {
        
    }
}

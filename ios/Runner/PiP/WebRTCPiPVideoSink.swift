import Foundation
import WebRTC
import AVFoundation
import AVKit

class WebRTCPiPVideoSink: NSObject {
    
    private var hostView: UIView?
    
    let layer = AVSampleBufferDisplayLayer()
    private let queue = DispatchQueue(label: "webrtc.pip.render")
    
    private var lastRotation: RTCVideoRotation = ._0
    
    override init() {
        super.init()
        layer.videoGravity = .resizeAspectFill
    }
    
    func attachToRootView() {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first,
            let rootVC = window.rootViewController
        else { return }
        
        if hostView == nil {
            let view = UIView(frame: rootVC.view.bounds)
            view.backgroundColor = .clear
            view.isOpaque = false
            view.isUserInteractionEnabled = false
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            rootVC.view.insertSubview(view, at: 0)
            hostView = view
        }
        
        guard layer.superlayer == nil, let hostView = hostView else { return }
        
        layer.frame = hostView.bounds
        layer.opacity = 0.001
        layer.isOpaque = false
        
        hostView.layer.addSublayer(layer)
    }
    
    func detachFromRootView() {
        layer.stopRequestingMediaData()

        if layer.status == .failed || layer.status == .unknown {
            layer.flushAndRemoveImage()
        } else {
            layer.flush()
        }

        layer.removeFromSuperlayer()
    }
    
    private func updateLayerTransform(for rotation: RTCVideoRotation) {
        
        guard rotation != lastRotation else { return }
        lastRotation = rotation
        
        let angle: CGFloat
        switch rotation {
        case ._0: angle = 0
        case ._90: angle = .pi / 2
        case ._180: angle = .pi
        case ._270: angle = .pi * 3 / 2
        @unknown default: angle = 0
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let screen = UIScreen.main.bounds
            
            if rotation == ._90 || rotation == ._270 {
                self.layer.bounds = CGRect(x: 0, y: 0, width: screen.height, height: screen.width)
            } else {
                self.layer.bounds = CGRect(x: 0, y: 0, width: screen.width, height: screen.height)
            }
            
            self.layer.position = CGPoint(x: screen.midX, y: screen.midY)
            
            self.layer.setAffineTransform(CGAffineTransform(rotationAngle: angle))
        }
    }
}

extension WebRTCPiPVideoSink: RTCVideoRenderer {
    
    func setSize(_ size: CGSize) {}
    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else { return }
        
        queue.async { [weak self] in
            guard let self = self,
                  let rtcBuffer = frame.buffer as? RTCCVPixelBuffer else {
                return
            }
            
            let srcPixelBuffer = rtcBuffer.pixelBuffer
            let pixelBufferForPip = self.rotatePixelBuffer(srcPixelBuffer, rotation: frame.rotation)
            
            var desc: CMVideoFormatDescription?
            let descStatus = CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBufferForPip,
                formatDescriptionOut: &desc
            )
            guard descStatus == noErr, let formatDesc = desc else { return }
            
            var timing = CMSampleTimingInfo(
                duration: .invalid,
                presentationTimeStamp: CMTime(
                    value: CMTimeValue(frame.timeStamp),
                    timescale: 1000
                ),
                decodeTimeStamp: .invalid
            )
            
            var sampleBuffer: CMSampleBuffer?
            let status = CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBufferForPip,
                formatDescription: formatDesc,
                sampleTiming: &timing,
                sampleBufferOut: &sampleBuffer
            )
            
            guard status == noErr, let sb = sampleBuffer else { return }
            
            if self.layer.status == .failed {
                self.layer.flush()
            }
            
            self.layer.enqueue(sb)
        }
    }
    
    private func rotatePixelBuffer(_ pixelBuffer: CVPixelBuffer, rotation: RTCVideoRotation) -> CVPixelBuffer {
        guard rotation != ._0 else {
            return pixelBuffer
        }
        
        let srcWidth = CVPixelBufferGetWidth(pixelBuffer)
        let srcHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        let orientation: CGImagePropertyOrientation
        let dstWidth: Int
        let dstHeight: Int
        
        switch rotation {
        case ._90:
            orientation = .right
            dstWidth = srcHeight
            dstHeight = srcWidth
        case ._180:
            orientation = .down
            dstWidth = srcWidth
            dstHeight = srcHeight
        case ._270:
            orientation = .left
            dstWidth = srcHeight
            dstHeight = srcWidth
        default:
            return pixelBuffer
        }
        
        let attrs = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            kCVPixelBufferWidthKey: dstWidth,
            kCVPixelBufferHeightKey: dstHeight,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ] as CFDictionary
        
        var rotatedBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            dstWidth,
            dstHeight,
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            attrs,
            &rotatedBuffer
        )
        
        guard status == kCVReturnSuccess, let out = rotatedBuffer else {
            return pixelBuffer
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)
        
        let ciContext = CIContext(options: [
            .workingColorSpace: NSNull()
        ])
        ciContext.render(ciImage, to: out)
        
        return out
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

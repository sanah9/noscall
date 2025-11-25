import UIKit
import AVFoundation
import WebRTC

final class SampleBufferVideoCallView: UIView {

    let displayLayer = AVSampleBufferDisplayLayer()
    private let renderQueue = DispatchQueue(label: "webrtc.videocall.pip.render")
    private var formatDescription: CMVideoFormatDescription?
    private let ciContext = CIContext(options: [.workingColorSpace: NSNull()])

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .black

        displayLayer.videoGravity = .resizeAspectFill
        displayLayer.isOpaque = true
        displayLayer.frame = bounds

        layer.addSublayer(displayLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let superViewBounds = superview?.bounds {
            displayLayer.frame = superViewBounds
        }
    }

    func reset() {
        renderQueue.async { [weak self] in
            guard let self = self else { return }

            self.displayLayer.stopRequestingMediaData()
            self.displayLayer.flushAndRemoveImage()
            self.formatDescription = nil
        }
    }
}

// MARK: - RTCVideoRenderer

extension SampleBufferVideoCallView: RTCVideoRenderer {

    func setSize(_ size: CGSize) {}

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else { return }

        renderQueue.async { [weak self] in
            guard let self = self,
                  let rtcBuffer = frame.buffer as? RTCCVPixelBuffer else {
                return
            }

            let srcPixelBuffer = rtcBuffer.pixelBuffer

            // 🔁 rotate according to RTCVideoRotation so that image is "upright"
            let pixelBufferForDisplay = self.rotatePixelBuffer(
                srcPixelBuffer,
                rotation: frame.rotation
            )

            // Create or update formatDescription for the (possibly rotated) buffer
            var desc: CMVideoFormatDescription?
            let statusDesc = CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBufferForDisplay,
                formatDescriptionOut: &desc
            )

            guard statusDesc == noErr, let formatDesc = desc else { return }
            self.formatDescription = formatDesc

            var timing = CMSampleTimingInfo(
                duration: .invalid,
                presentationTimeStamp: CMTime(
                    value: CMTimeValue(frame.timeStamp),
                    timescale: 1000
                ),
                decodeTimeStamp: .invalid
            )

            var sampleBuffer: CMSampleBuffer?
            let statusSample = CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBufferForDisplay,
                formatDescription: formatDesc,
                sampleTiming: &timing,
                sampleBufferOut: &sampleBuffer
            )

            guard statusSample == noErr, let sb = sampleBuffer else { return }

            if self.displayLayer.status == .failed {
                self.displayLayer.flush()
            }

            self.displayLayer.enqueue(sb)
        }
    }

    /// Rotate WebRTC CVPixelBuffer according to RTCVideoRotation so that
    /// the image is upright when rendered in PiP / full screen.
    private func rotatePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                                   rotation: RTCVideoRotation) -> CVPixelBuffer {

        // No rotation needed
        guard rotation != ._0 else {
            return pixelBuffer
        }

        let srcWidth = CVPixelBufferGetWidth(pixelBuffer)
        let srcHeight = CVPixelBufferGetHeight(pixelBuffer)

        let orientation: CGImagePropertyOrientation
        let dstWidth: Int
        let dstHeight: Int

        // WebRTC rotation is clockwise; CoreImage orientation uses EXIF semantics
        switch rotation {
        case ._90:
            orientation = .right          // 90° clockwise
            dstWidth = srcHeight
            dstHeight = srcWidth
        case ._180:
            orientation = .down           // 180°
            dstWidth = srcWidth
            dstHeight = srcHeight
        case ._270:
            orientation = .left           // 270° clockwise = 90° CCW
            dstWidth = srcHeight
            dstHeight = srcWidth
        default:
            return pixelBuffer
        }

        let attrs: CFDictionary = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            kCVPixelBufferWidthKey: dstWidth,
            kCVPixelBufferHeightKey: dstHeight,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as NSDictionary
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

        // Build CIImage from source buffer and apply orientation
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)

        // Render into destination buffer
        ciContext.render(ciImage, to: out)

        return out
    }
}


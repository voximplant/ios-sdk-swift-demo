/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import CocoaLumberjack
import VoxImplantSDK

class CustomCamera: NSObject {
    public let customVideoSource: VICustomVideoSource
    let image = UIImage(named: "Logo")!.cgImage
    var count = 0
    var videoFormat: VIVideoFormat = VIVideoFormat(frame: CGSize(width: 640, height: 480), fps: 30)
    var timer: Timer?

    override init() {
        customVideoSource = VICustomVideoSource(videoFormats: [self.videoFormat])
        super.init()
        customVideoSource.delegate = self
    }
}


extension CustomCamera: VICustomVideoSourceDelegate {
    func start(with format: VIVideoFormat!) {
        Log.i("CustomCameraSource:Start with format: \(String(describing: format))")
        let timePerFrame = Double(format.interval) / Double(NSEC_PER_SEC)

        DispatchQueue.main.async { () -> Void in
            self.timer = Timer.scheduledTimer(timeInterval: timePerFrame, target: self, selector: #selector(self.processNextFrame), userInfo: nil, repeats: true)
        }
    }

    @objc func processNextFrame() {
        let options = [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true]

        var pBuffer: CVPixelBuffer?

        var status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.videoFormat.frame.width), Int(self.videoFormat.frame.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pBuffer)
        guard status == kCVReturnSuccess, pBuffer != nil else {
            self.timer?.invalidate()
            return
        }

        if let pixelBuffer = pBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
            let pixelBufferAddress = CVPixelBufferGetBaseAddress(pixelBuffer);

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB();

            if let context = CGContext(data: pixelBufferAddress, width: Int(self.videoFormat.frame.width), height: Int(self.videoFormat.frame.height),
                    bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) {

                context.concatenate(CGAffineTransform.identity)

                context.setFillColor(Theme.headerColor.cgColor)
                context.fill(CGRect(x: 0, y: 0, width: Int(self.videoFormat.frame.width), height: Int(self.videoFormat.frame.height)))

                var width = CGFloat(self.image!.width), height = CGFloat(self.image!.height)
                if (width > self.videoFormat.frame.width) {
                    height = height * (self.videoFormat.frame.width / width)
                    width = self.videoFormat.frame.width
                } else if (height > self.videoFormat.frame.height) {
                    width = width * (self.videoFormat.frame.height / height)
                    height = self.videoFormat.frame.height
                }

                let x = (self.videoFormat.frame.width - width) / 2, y = (self.videoFormat.frame.height - height) / 2
                context.draw(self.image!, in: CGRect(x: x, y: y, width: width, height: height))

                status = CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));

                self.customVideoSource.sendVideoFrame(pixelBuffer, rotation: VIRotation._90)
                return
            }
        }

        self.timer?.invalidate()
    }

    func stop() {
        Log.i("CustomCameraSource:Stop")
        if let timer = self.timer {
            timer.invalidate()
        }
    }

}

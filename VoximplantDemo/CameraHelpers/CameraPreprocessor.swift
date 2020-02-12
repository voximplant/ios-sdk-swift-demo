/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

class CameraPreprocessor: NSObject {
    let cameraManager = VICameraManager.shared()

    override init() {
        super.init()
        cameraManager?.videoPreprocessDelegate = self
    }

}

extension CameraPreprocessor: VIVideoPreprocessDelegate {


    func preprocessVideoFrame(_ pixelBuffer: CVPixelBuffer!, rotation: VIRotation) {
        //Log.info("onPreprocessCameraCapturedVideo: rotation=\(rotation)")
        if (pixelBuffer == nil) {
            return
        }

        var _ = CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
        let size = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1) * CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)

        memset(baseAddress, 900, size)

        var _ = CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
    }

}

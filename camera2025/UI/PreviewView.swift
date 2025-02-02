//
//  PreviewView.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import UIKit
import AVFoundation

final class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else { return AVCaptureVideoPreviewLayer() }
        return layer
    }

    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
}

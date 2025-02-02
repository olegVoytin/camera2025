//
//  PreviewView.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import UIKit
import SwiftUI
@preconcurrency import AVFoundation

struct PreviewView: UIViewRepresentable {
    let videoCaptureSession: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIKitView {
        let view = PreviewUIKitView()
        view.session = videoCaptureSession
        return view
    }

    func updateUIView(_ uiView: PreviewUIKitView, context: Context) {
        guard uiView.session == nil else { return }
        uiView.session = videoCaptureSession
    }
}

final class PreviewUIKitView: UIView {
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

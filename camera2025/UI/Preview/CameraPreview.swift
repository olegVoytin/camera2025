//
//  CameraPreview.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.session = session
    }
}

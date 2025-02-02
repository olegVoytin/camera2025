//
//  CameraPreview.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import SwiftUI
@preconcurrency import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let presenter: PreviewPresenter

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()

//        Task { @MainActor in
//            let session = await presenter.videoCaptureSession
//            view.session = session
//        }

        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        Task { @MainActor in
            let videoCaptureSession = await presenter.videoCaptureSession
            uiView.session = videoCaptureSession
        }
    }
}

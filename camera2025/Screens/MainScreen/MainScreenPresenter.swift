//
//  MainScreenPresenter.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@CapturingActor
final class MainScreenPresenter {

    var videoCaptureSession: AVCaptureSession {
        captureManager.sessionsManager.videoSession
    }

    lazy var actionHandler = MainScreenActionHandler(
        onTapPhotoButton: {

        }
    )

    private let captureManager = CaptureManager()

    func startSession() {
        captureManager.startCapture()
    }
}

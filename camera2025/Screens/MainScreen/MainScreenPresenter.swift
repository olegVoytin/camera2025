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
        captureService.sessionsService.videoSession
    }

    private let captureService = CaptureService()

    func startSession() {
        captureService.startCapture()
    }

    func createActionHandler() -> MainScreenActionHandler {
        MainScreenActionHandler(onTapPhotoButton: {

        })
    }
}

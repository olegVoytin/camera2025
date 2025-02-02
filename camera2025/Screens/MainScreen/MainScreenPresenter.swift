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
        mainMediaManager.videoSession
    }

    lazy var actionHandler = MainScreenActionHandler(
        onTapPhotoButton: {

        }
    )

    private let mainMediaManager: MainMediaManager

    init(mainMediaManager: MainMediaManager) {
        self.mainMediaManager = mainMediaManager
    }

    func startSession() {
        mainMediaManager.startCapture()
    }
}

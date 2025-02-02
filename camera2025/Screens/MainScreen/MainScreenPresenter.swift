//
//  MainScreenPresenter.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@CapturingActor
final class MainScreenPresenter: NSObject {

    var videoCaptureSession: AVCaptureSession {
        mainMediaManager.videoSession
    }

    lazy var actionHandler = MainScreenActionHandler(
        onTapPhotoButton: {

        }
    )

    private let photoCaptureObserver = PhotoCaptureObserver()

    private let mainMediaManager: MainMediaManager

    init(mainMediaManager: MainMediaManager) {
        self.mainMediaManager = mainMediaManager
        super.init()
        photoCaptureObserver.delegate = self
    }

    func startSession() {
        mainMediaManager.startCapture(photoNotificationsObserver: photoCaptureObserver)
    }
}

extension MainScreenPresenter: PhotoCaptureDelegate {
    func photoWillCaptured() {

    }
    
    func photoDataCreated(data: Data) {

    }
    
    func photoDidCaptured() {

    }
}

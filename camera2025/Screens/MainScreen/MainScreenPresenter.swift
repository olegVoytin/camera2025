//
//  MainScreenPresenter.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@MainMediaActor
final class MainScreenPresenter: NSObject {

    var videoCaptureSession: AVCaptureSession {
        mainMediaManager.videoSession
    }

    lazy var actionHandler = MainScreenActionHandler(triggerAction: { action in
        Task { @MainMediaActor in
            self.handleAction(action)
        }
    })

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

    private func handleAction(_ action: Action) {
        switch action {
        case.takePhoto:
            try? mainMediaManager.takePhoto()

        case .startVideoRecording:
            Task {
                try await mainMediaManager.startVideoRecording()
            }
        }
    }
}

extension MainScreenPresenter: PhotoCaptureDelegate {
    func photoWillCaptured() {

    }
    
    func photoDataCreated(data: Data) {
        Task {
            try? await mainMediaManager.savePhotoInGallery(data)
        }
    }
    
    func photoDidCaptured() {

    }
}

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

    @MainActor lazy var model = MainScreenModel(triggerAction: { action in
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
            Task { @MainActor in
                model.isTakingPhotoPossible = false
                try? await mainMediaManager.takePhoto()
            }

        case .startVideoRecording:
            Task { @MainActor in
                model.isVideoRecordingActive = true
                model.isVideoRecordingPossible = false
                
                do {
                    try await mainMediaManager.startVideoRecording()
                } catch {
                    print(1)
                }
            }

        case .stopVideoRecording:
            Task { @MainActor in
                do {
                    try await mainMediaManager.stopVideoRecording()
                } catch {
                    print(1)
                }

                model.isVideoRecordingActive = false
                model.isVideoRecordingPossible = true
            }
        }
    }
}

extension MainScreenPresenter: PhotoCaptureDelegate {
    func photoWillCaptured() {

    }
    
    func photoDataCreated(data: Data) {
        Task { @MainActor in
            try? await mainMediaManager.savePhotoInGallery(data)
            model.isTakingPhotoPossible = false
        }
    }
    
    func photoDidCaptured() {

    }
}

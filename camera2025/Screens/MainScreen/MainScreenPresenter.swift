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

    private let mainMediaManager: MainMediaManager

    init(mainMediaManager: MainMediaManager) {
        self.mainMediaManager = mainMediaManager
        super.init()
    }

    func startSession() async {
        await mainMediaManager.startCapture(photoNotificationsObserver: self)
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
                model.isVideoRecordingStateChangePossible = false
                
                do {
                    try await mainMediaManager.startVideoRecording()
                } catch {
                    print(1)
                }

                model.isVideoRecordingStateChangePossible = true
            }

        case .stopVideoRecording:
            Task { @MainActor in
                model.isVideoRecordingStateChangePossible = false
                
                do {
                    try await mainMediaManager.stopVideoRecording()
                } catch {
                    print(1)
                }

                model.isVideoRecordingActive = false
                model.isVideoRecordingStateChangePossible = true
            }

        case .changeCameraPosition:
            Task {
                try? await mainMediaManager.changeCameraPosition()
            }
        }
    }
}

@MainActor
extension MainScreenPresenter: @preconcurrency AVCapturePhotoCaptureDelegate {
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {

    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task {
            guard let data = photo.fileDataRepresentation() else { return }
            try? await mainMediaManager.savePhotoInGallery(data)
            onTakingPhotoPossible()
        }
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {

    }

    @MainActor
    private func onTakingPhotoPossible() {
        model.isTakingPhotoPossible = true
    }
}

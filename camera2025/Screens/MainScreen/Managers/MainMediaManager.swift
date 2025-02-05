//
//  MainMediaManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@MainMediaActor
final class MainMediaManager {

    let videoSession = AVCaptureSession()

    private let deviceManager: DeviceManager
    private lazy var videoSessionManager = VideoSessionManager(videoSession: videoSession)
    private let audioSessionManager = AudioSessionManager()

    private let photoTakingManager = PhotoTakingManager()
    private let videoRecordingManager = VideoRecordingManager()

    init(deviceManager: DeviceManager) throws {
        self.deviceManager = try DeviceManager()
    }

    func startCapture(photoNotificationsObserver: PhotoCaptureObserver) {
        do {
            try deviceManager.start(
                videoBufferDelegate: videoRecordingManager,
                audioBufferDelegate: videoRecordingManager
            )
            try videoSessionManager.start(
                videoDeviceInput: deviceManager.videoDeviceInput,
                videoOutput: deviceManager.videoOutput,
                photoOutput: photoTakingManager.photoOutput
            )
            try audioSessionManager.start(
                audioInput: deviceManager.audioDeviceInput,
                audioOutput: deviceManager.audioOutput
            )
        } catch {
            guard let error = error as? SessionError else { return }
            print(error.localizedDescription)
        }

        photoTakingManager.delegate = photoNotificationsObserver
    }

    func takePhoto() throws {
        try photoTakingManager.takePhoto()
    }

    func savePhotoInGallery(_ imageData: Data) async throws {
        try await photoTakingManager.savePhotoInGallery(imageData)
    }

    func startVideoRecording() async throws {
        audioSessionManager.startRunning()

        let cameraResolution = deviceManager.getCameraResolution()
        try await videoRecordingManager.startVideoRecording(captureResolution: cameraResolution)
    }

    func stopVideoRecording() async throws {
        audioSessionManager.stopRunning()
        try await videoRecordingManager.stopVideoRecording()
    }

    func changeCameraPosition() async throws {
        let (oldInput, newInput) = try deviceManager.setNewInput()
        videoSessionManager.setNewDeviceToSession(
            oldInput: oldInput,
            newInput: newInput,
            videoOutput: deviceManager.videoOutput
        )

        try await videoRecordingManager.rotateVideoOutput()
    }
}

enum SessionError: Error {
    case addVideoInputError
    case addAudioInputError
    case addVideoOutputError
    case addPhotoOutputError
    case setTorchValueError
    case makePhotoError
    case savePhotoToLibraryError
    case saveVideoToLibraryError
    case changeCameraPositionError

    var localizedDescription: String {
        switch self {
        case .addVideoInputError:
            return "Could not add video input."

        case .addVideoOutputError:
            return "Could not add video output."

        case .setTorchValueError:
            return "Could not set torch value."

        case .addAudioInputError:
            return "Could not add audio input."

        case .makePhotoError:
            return "Could not make photo."

        case .addPhotoOutputError:
            return "Could not add photo output."

        case .savePhotoToLibraryError:
            return "Could not save photo to library."

        case .saveVideoToLibraryError:
            return "Could not save video to library."

        case .changeCameraPositionError:
            return "Could not change camera position."
        }
    }
}

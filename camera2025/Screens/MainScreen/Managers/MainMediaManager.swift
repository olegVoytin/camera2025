//
//  MainMediaManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@CapturingActor
final class MainMediaManager {

    let videoSession = AVCaptureSession()

    private lazy var videoSessionManager = VideoSessionManager(videoSession: videoSession)
    private let audioSessionManager = AudioSessionManager()
    private let photoManager = PhotoManager()

    private let deviceInputManager: DeviceInputManager

    init(deviceInputManager: DeviceInputManager) throws {
        self.deviceInputManager = try DeviceInputManager()
    }

    func startCapture(photoNotificationsObserver: PhotoCaptureObserver) {
        do {
            try deviceInputManager.start()
            try videoSessionManager.start(
                videoDeviceInput: deviceInputManager.videoDeviceInput,
                photoOutput: photoManager.photoOutput
            )
        } catch {
            guard let error = error as? SessionError else { return }
            print(error.localizedDescription)
        }

        photoManager.delegate = photoNotificationsObserver
    }

    func takePhoto() throws {
        try photoManager.takePhoto()
    }

    func savePhotoInGallery(_ imageData: Data) async throws {
        try await photoManager.savePhotoInGallery(imageData)
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
        }
    }
}

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
    private let deviceInputManager: DeviceInputManager

    init(deviceInputManager: DeviceInputManager) throws {
        self.deviceInputManager = try DeviceInputManager()
    }

    func startCapture() {
        do {
            try deviceInputManager.start()
            try videoSessionManager.start(videoDeviceInput: deviceInputManager.videoDeviceInput)
        } catch {
            guard let error = error as? SessionError else {
                return
            }
            print(error.localizedDescription)
        }
    }
}

enum SessionError: Error {
    case addVideoInputError
    case addAudioInputError
    case addVideoOutputError
    case setTorchValueError
    case setPhotoOutputError

    var localizedDescription: String {
        switch self {
        case .addVideoInputError:
            return "Could not add video input."

        case .addVideoOutputError:
            return "Could not add video output."

        case .setTorchValueError:
            return "Could not set torch value."

        case .setPhotoOutputError:
            return "Could not set photo output."

        case .addAudioInputError:
            return "Could not add audio input."
        }
    }
}

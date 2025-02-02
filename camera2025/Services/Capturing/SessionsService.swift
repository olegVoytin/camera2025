//
//  SessionsService.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@CapturingActor
final class SessionsService {

    let videoSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?

    private let audioSession = AVCaptureSession()

    func start() throws {
        videoSession.beginConfiguration()
        defer { videoSession.commitConfiguration() }

        videoSession.sessionPreset = .high

        try addVideoInput()
        try addVideoOutput()
        try setNewTorchValue(.off)
    }

    private func addVideoInput() throws {
        guard
            let videoDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            )
        else {
            print("Default video device is unavailable.")
            throw SessionError.addVideoInputError
        }
        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

        if videoSession.canAddInput(videoDeviceInput) {
            videoSession.addInput(videoDeviceInput)

            try videoDeviceInput.device.lockForConfiguration()
            videoDeviceInput.device.setExposureTargetBias(0, completionHandler: nil)
            videoDeviceInput.device.exposureMode = .continuousAutoExposure
            videoDeviceInput.device.unlockForConfiguration()
        } else {
            print("Couldn't add video device input to the session.")
            throw SessionError.addVideoInputError
        }
    }

    private func addVideoOutput() throws {
        guard videoSession.canAddOutput(videoOutput) else { throw SessionError.addVideoOutputError }

        videoSession.beginConfiguration()

        videoSession.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait

            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .standard
            }
        }

        videoSession.commitConfiguration()
    }

    private func setNewTorchValue(_ newValue: AVCaptureDevice.TorchMode) throws {
        guard
            let device = self.videoDeviceInput?.device,
            device.hasTorch,
            device.isTorchModeSupported(newValue)
        else {
            throw SessionError.setTorchValueError
        }

        try device.lockForConfiguration()
        device.torchMode = newValue
        device.unlockForConfiguration()
    }
}

enum SessionError: Error {
    case addVideoInputError
    case addVideoOutputError
    case setTorchValueError

    var localizedDescription: String {
        switch self {
        case .addVideoInputError:
            return "Could not add video input."
        case .addVideoOutputError:
            return "Could not add video output."
        case .setTorchValueError:
            return "Could not set torch value."
        }
    }
}

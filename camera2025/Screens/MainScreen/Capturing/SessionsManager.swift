//
//  SessionsManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@CapturingActor
final class SessionsManager {

    let videoSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?

    let photoOutput = AVCapturePhotoOutput()

    private let audioSession = AVCaptureSession()

    func start() throws {
        videoSession.beginConfiguration()

        videoSession.sessionPreset = .high

        do {
            try addVideoInput()
            try addVideoOutput()
            try addPhotoOutput()
        } catch {
            videoSession.commitConfiguration()
            throw error
        }

        setNewTorchValue(.off)

        videoSession.commitConfiguration()

        videoSession.startRunning()
    }

    func capturePhoto() {

    }

    func getPhotoSettings() -> AVCapturePhotoSettings {
        var photoSettings = AVCapturePhotoSettings()

        if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        }

        if self.videoDeviceInput?.device.isFlashAvailable == true {
            photoSettings.flashMode = .off
        }

        if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
        }
        photoSettings.photoQualityPrioritization = .quality

        return photoSettings
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

            self.videoDeviceInput = videoDeviceInput
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

    private func addPhotoOutput() throws {
        if videoSession.canAddOutput(photoOutput) {
            videoSession.addOutput(photoOutput)

            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = false
            photoOutput.isDepthDataDeliveryEnabled = false
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            print("Could not add photo output to the session")
            throw SessionError.setPhotoOutputError
        }
    }

    private func setNewTorchValue(_ newValue: AVCaptureDevice.TorchMode) {
        guard
            let device = self.videoDeviceInput?.device,
            device.hasTorch,
            device.isTorchModeSupported(newValue)
        else { return }

        try? device.lockForConfiguration()
        device.torchMode = newValue
        device.unlockForConfiguration()
    }
}

enum SessionError: Error {
    case addVideoInputError
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
        }
    }
}

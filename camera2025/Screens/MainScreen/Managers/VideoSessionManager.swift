//
//  VideoSessionManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@CapturingActor
final class VideoSessionManager {

    let videoSession: AVCaptureSession
    private let videoOutput = AVCaptureVideoDataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?

    init(videoSession: AVCaptureSession) {
        self.videoSession = videoSession
    }

    func start() throws {
        videoSession.beginConfiguration()

        videoSession.sessionPreset = .high

        do {
            try addVideoInput()
            try addVideoOutput()
        } catch {
            videoSession.commitConfiguration()
            throw error
        }

        videoSession.commitConfiguration()

        videoSession.startRunning()
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
}

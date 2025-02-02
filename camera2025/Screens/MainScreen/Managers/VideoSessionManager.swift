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

    init(videoSession: AVCaptureSession) {
        self.videoSession = videoSession
    }

    func start(videoDeviceInput: AVCaptureDeviceInput, photoOutput: AVCapturePhotoOutput) throws {
        videoSession.beginConfiguration()

        videoSession.sessionPreset = .high

        do {
            try addVideoInput(videoDeviceInput: videoDeviceInput)
            try addVideoOutput()
            try addPhotoOutput(photoOutput: photoOutput)
        } catch {
            videoSession.commitConfiguration()
            throw error
        }

        videoSession.commitConfiguration()

        videoSession.startRunning()
    }

    private func addVideoInput(videoDeviceInput: AVCaptureDeviceInput) throws {
        guard videoSession.canAddInput(videoDeviceInput) else {
            throw SessionError.addVideoInputError
        }
        videoSession.addInput(videoDeviceInput)
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

    private func addPhotoOutput(photoOutput: AVCapturePhotoOutput) throws {
        guard videoSession.canAddOutput(photoOutput) else { throw SessionError.addPhotoOutputError }
        videoSession.addOutput(photoOutput)
    }
}

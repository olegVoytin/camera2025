//
//  VideoSessionManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@MainMediaActor
final class VideoSessionManager {

    private let videoSession: AVCaptureSession

    init(videoSession: AVCaptureSession) {
        self.videoSession = videoSession
    }

    func start(
        videoDeviceInput: AVCaptureDeviceInput,
        videoOutput: AVCaptureVideoDataOutput,
        photoOutput: AVCapturePhotoOutput
    ) throws {
        videoSession.beginConfiguration()

        videoSession.sessionPreset = .high

        do {
            try addVideoInput(videoDeviceInput: videoDeviceInput)
            try addVideoOutput(videoOutput: videoOutput)
            try addPhotoOutput(photoOutput: photoOutput)
        } catch {
            videoSession.commitConfiguration()
            throw error
        }

        videoSession.commitConfiguration()

        videoSession.startRunning()
    }

    func setNewDeviceToSession(
        oldInput: AVCaptureDeviceInput,
        newInput: AVCaptureDeviceInput,
        videoOutput: AVCaptureVideoDataOutput
    ) {
        videoSession.beginConfiguration()

        videoSession.removeInput(oldInput)

        if videoSession.canAddInput(newInput) {
            videoSession.addInput(newInput)
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait

            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .standard
            }
        }

        videoSession.commitConfiguration()
    }

    private func addVideoInput(videoDeviceInput: AVCaptureDeviceInput) throws {
        guard videoSession.canAddInput(videoDeviceInput) else {
            throw SessionError.addVideoInputError
        }
        videoSession.addInput(videoDeviceInput)
    }

    private func addVideoOutput(videoOutput: AVCaptureVideoDataOutput) throws {
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

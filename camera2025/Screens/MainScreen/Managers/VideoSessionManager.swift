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

    func start(videoDeviceInput: AVCaptureDeviceInput) throws {
        videoSession.beginConfiguration()

        videoSession.sessionPreset = .high

        do {
            try addVideoInput(videoDeviceInput: videoDeviceInput)
            try addVideoOutput()
        } catch {
            videoSession.commitConfiguration()
            throw error
        }

        videoSession.commitConfiguration()

        videoSession.startRunning()
    }

    private func addVideoInput(videoDeviceInput: AVCaptureDeviceInput) throws {
        if videoSession.canAddInput(videoDeviceInput) {
            videoSession.addInput(videoDeviceInput)

            
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

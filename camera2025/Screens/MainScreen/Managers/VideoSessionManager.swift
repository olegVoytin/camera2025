//
//  VideoSessionManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation
import UIKit

@MainMediaActor
final class VideoSessionManager {

    private let videoSession: AVCaptureSession

    init(videoSession: AVCaptureSession) {
        self.videoSession = videoSession
    }

    func start(
        videoDeviceInput: AVCaptureDeviceInput,
        videoOutput: AVCaptureVideoDataOutput,
        photoOutput: AVCapturePhotoOutput,
        deviceOrientation: UIDeviceOrientation
    ) throws {
        videoSession.beginConfiguration()

        videoSession.sessionPreset = .high

        do {
            try addVideoInput(videoDeviceInput: videoDeviceInput)
            try addVideoOutput(deviceOrientation: deviceOrientation, videoOutput: videoOutput)
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
        videoOutput: AVCaptureVideoDataOutput,
        deviceOrientation: UIDeviceOrientation
    ) {
        videoSession.beginConfiguration()

        videoSession.removeInput(oldInput)

        if videoSession.canAddInput(newInput) {
            videoSession.addInput(newInput)
        }

        setupOrientation(deviceOrientation: deviceOrientation, videoOutput: videoOutput)

        videoSession.commitConfiguration()
    }

    func setupOrientation(
        deviceOrientation: UIDeviceOrientation,
        videoOutput: AVCaptureVideoDataOutput
    ) {
        if let connection = videoOutput.connection(with: .video) {
            switch deviceOrientation {
            case .portrait:
                connection.videoOrientation = .portrait

            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight

            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft

            default:
                break
            }

            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .standard
            }
        }
    }

    func setupOrientation(
        deviceOrientation: UIDeviceOrientation,
        photoOutput: AVCapturePhotoOutput
    ) {
        if let connection = photoOutput.connection(with: .video) {
            switch deviceOrientation {
            case .portrait:
                connection.videoOrientation = .portrait

            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight

            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft

            default:
                break
            }

            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .standard
            }
        }
    }

    private func addVideoInput(videoDeviceInput: AVCaptureDeviceInput) throws {
        guard videoSession.canAddInput(videoDeviceInput) else {
            throw SessionError.addVideoInputError
        }
        videoSession.addInput(videoDeviceInput)
    }

    private func addVideoOutput(
        deviceOrientation: UIDeviceOrientation,
        videoOutput: AVCaptureVideoDataOutput
    ) throws {
        guard videoSession.canAddOutput(videoOutput) else { throw SessionError.addVideoOutputError }

        videoSession.beginConfiguration()

        videoSession.addOutput(videoOutput)

        setupOrientation(deviceOrientation: deviceOrientation, videoOutput: videoOutput)

        videoSession.commitConfiguration()
    }

    private func addPhotoOutput(photoOutput: AVCapturePhotoOutput) throws {
        guard videoSession.canAddOutput(photoOutput) else { throw SessionError.addPhotoOutputError }
        videoSession.addOutput(photoOutput)
    }
}

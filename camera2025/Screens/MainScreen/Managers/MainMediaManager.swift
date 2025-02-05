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

    func startCapture(photoNotificationsObserver: AVCapturePhotoCaptureDelegate) async throws {
        photoTakingManager.delegate = photoNotificationsObserver

        try deviceManager.start(
            videoBufferDelegate: videoRecordingManager,
            audioBufferDelegate: videoRecordingManager
        )
        let deviceOrientation = await deviceManager.getDeviceOrientation()
        try videoSessionManager.start(
            videoDeviceInput: deviceManager.videoDeviceInput,
            videoOutput: deviceManager.videoOutput,
            photoOutput: photoTakingManager.photoOutput,
            deviceOrientation: deviceOrientation
        )
        try audioSessionManager.start(
            audioInput: deviceManager.audioDeviceInput,
            audioOutput: deviceManager.audioOutput
        )
    }

    func takePhoto() async throws {
        let deviceOrientation = await deviceManager.getDeviceOrientation()
        videoSessionManager.setupOrientation(
            deviceOrientation: deviceOrientation,
            photoOutput: photoTakingManager.photoOutput
        )

        let flashMode = AVCaptureDevice.FlashMode(rawValue: deviceManager.torchMode?.rawValue ?? 0) ?? .off
        try photoTakingManager.takePhoto(flashMode: flashMode)
    }

    func savePhotoInGallery(_ imageData: Data) async throws {
        try await photoTakingManager.savePhotoInGallery(imageData)
    }

    func startVideoRecording() async throws {
        try deviceManager.enableSelectedTorchMode()

        let deviceOrientation = await deviceManager.getDeviceOrientation()
        videoSessionManager.setupOrientation(
            deviceOrientation: deviceOrientation,
            videoOutput: deviceManager.videoOutput
        )

        audioSessionManager.startRunning()

        let cameraResolution = await deviceManager.getCameraResolution()

        do {
            try await videoRecordingManager.startNewRecording(
                captureResolution: cameraResolution,
                recordingDeviceOrientation: deviceOrientation
            )
        } catch {
            await videoRecordingManager.reset()
            throw error
        }
    }

    func stopVideoRecording() async throws {
        audioSessionManager.stopRunning()
        try deviceManager.disableTorch()

        do {
            try await videoRecordingManager.stopRecording()
        } catch {
            await videoRecordingManager.reset()
            throw error
        }
    }

    func changeCameraPosition() async throws {
        await videoRecordingManager.pauseRecordingIfNeeded()

        let recordingDeviceOrientation = await videoRecordingManager.recordingDeviceOrientation
        let deviceOrientation = await deviceManager.getDeviceOrientation()
        let deviceOrientationToUse = recordingDeviceOrientation ?? deviceOrientation
        let (oldInput, newInput) = try deviceManager.setNewInput()
        videoSessionManager.setNewDeviceToSession(
            oldInput: oldInput,
            newInput: newInput,
            videoOutput: deviceManager.videoOutput,
            deviceOrientation: deviceOrientationToUse
        )

        do {
            let cameraResolution = await deviceManager.getCameraResolution()
            try await videoRecordingManager.resumeRecordingIfNeeded(captureResolution: cameraResolution)
        } catch {
            await videoRecordingManager.reset()
            throw error
        }

        let recordingState = await videoRecordingManager.recordingState
        if recordingState == .recording || recordingState == .start {
            try deviceManager.enableSelectedTorchMode()
        }
    }

    func setNewTorchMode(_ newTorchModeRawValue: Int) throws {
        deviceManager.torchMode = AVCaptureDevice.TorchMode(rawValue: newTorchModeRawValue)
    }
}

enum SessionError: Error {
    case addVideoInputError
    case addAudioInputError
    case addVideoOutputError
    case addPhotoOutputError
    case makePhotoError
    case savePhotoToLibraryError
    case saveVideoToLibraryError
    case changeCameraPositionError
    case changeTorchModeError

    var localizedDescription: String {
        switch self {
        case .addVideoInputError:
            return "Could not add video input."

        case .addVideoOutputError:
            return "Could not add video output."

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

        case .changeTorchModeError:
            return "Could not change torch mode."
        }
    }
}

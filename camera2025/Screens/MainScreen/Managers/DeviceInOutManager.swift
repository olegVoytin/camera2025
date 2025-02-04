//
//  DeviceInOutManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@MainMediaActor
final class DeviceInOutManager {
    var videoDeviceInput: AVCaptureDeviceInput
    let videoOutput = AVCaptureVideoDataOutput()

    var audioDeviceInput: AVCaptureDeviceInput
    let audioOutput = AVCaptureAudioDataOutput()

    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
            .builtInWideAngleCamera,
            .builtInDualCamera,
            .builtInTrueDepthCamera
        ],
        mediaType: .video,
        position: .unspecified
    )
    private let bufferQueue = DispatchQueue(label: "com.example.camera2025.bufferQueue")

    init() throws {
        if let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) {
            self.videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        } else {
            throw SessionError.addVideoInputError
        }

        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
        } else {
            throw SessionError.addAudioInputError
        }
    }

    func start(
        videoBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        audioBufferDelegate: AVCaptureAudioDataOutputSampleBufferDelegate
    ) throws {
        try videoDeviceInput.device.lockForConfiguration()
        videoDeviceInput.device.setExposureTargetBias(0, completionHandler: nil)
        videoDeviceInput.device.exposureMode = .continuousAutoExposure
        videoDeviceInput.device.unlockForConfiguration()

        videoOutput.setSampleBufferDelegate(videoBufferDelegate, queue: bufferQueue)
        audioOutput.setSampleBufferDelegate(audioBufferDelegate, queue: bufferQueue)
    }

    func getCameraResolution() -> CGSize {
        let formatDescription = videoDeviceInput.device.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        return CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
    }

    func setNewInput() throws -> (oldInput: AVCaptureDeviceInput, newInput: AVCaptureDeviceInput) {
        let oldInput = videoDeviceInput

        guard let newDevice = getNewDevice() else { throw SessionError.changeCameraPositionError }
        let newInput = try AVCaptureDeviceInput(device: newDevice)
        videoDeviceInput = newInput

        return (oldInput: oldInput, newInput: newInput)
    }

    private func getNewDevice() -> AVCaptureDevice? {
        let currentPosition = videoDeviceInput.device.position

        let preferredPosition: AVCaptureDevice.Position
        let preferredDeviceType: AVCaptureDevice.DeviceType

        switch currentPosition {
        case .unspecified, .front:
            preferredPosition = .back
            preferredDeviceType = .builtInDualCamera

        case .back:
            preferredPosition = .front
            preferredDeviceType = .builtInTrueDepthCamera

        @unknown default:
            print("Unknown capture position. Defaulting to back, dual-camera.")
            preferredPosition = .back
            preferredDeviceType = .builtInDualCamera
        }

        let devices = self.videoDeviceDiscoverySession.devices

        if let device = devices
            .first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
            return device
        } else if let device = devices.first(where: { $0.position == preferredPosition }) {
            return device
        } else {
            return nil
        }
    }
}

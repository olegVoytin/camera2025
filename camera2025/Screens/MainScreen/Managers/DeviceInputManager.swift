//
//  DeviceInputManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@MainMediaActor
final class DeviceInputManager {
    var videoDeviceInput: AVCaptureDeviceInput
    var audioDeviceInput: AVCaptureDeviceInput

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

    func start() throws {
        try videoDeviceInput.device.lockForConfiguration()
        videoDeviceInput.device.setExposureTargetBias(0, completionHandler: nil)
        videoDeviceInput.device.exposureMode = .continuousAutoExposure
        videoDeviceInput.device.unlockForConfiguration()
    }
}

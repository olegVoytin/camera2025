//
//  AudioSessionManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@MainMediaActor
final class AudioSessionManager {

    private let audioSession = AVCaptureSession()
    private let audioOutput: AVCaptureAudioDataOutput

    init(audioOutput: AVCaptureAudioDataOutput) {
        self.audioOutput = audioOutput
    }

    func start(audioInput: AVCaptureDeviceInput) throws {
        audioSession.beginConfiguration()

        guard audioSession.canAddInput(audioInput),
              audioSession.canAddOutput(audioOutput) else {
            audioSession.commitConfiguration()
            throw SessionError.addAudioInputError
        }
        
        audioSession.addInput(audioInput)
        audioSession.addOutput(audioOutput)

        audioSession.commitConfiguration()
    }

    func startRunning() {
        audioSession.startRunning()
    }

    func stopRunning() {
        audioSession.stopRunning()
    }
}

//
//  PhotoManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@CapturingActor
final class PhotoManager {

    private let photoOutput = AVCapturePhotoOutput()
    weak var delegate: AVCapturePhotoCaptureDelegate?

    func makePhoto() throws {
        guard let delegate else { throw SessionError.makePhotoError }
        let settings = makePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    private func makePhotoSettings() -> AVCapturePhotoSettings {
        var photoSettings = AVCapturePhotoSettings()

        if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        }

        photoSettings.isHighResolutionPhotoEnabled = true
        if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
        }
        photoSettings.photoQualityPrioritization = .quality

        return photoSettings
    }
}

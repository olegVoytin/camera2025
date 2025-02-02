//
//  PhotoManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation
import Photos
import UIKit

@CapturingActor
final class PhotoManager {

    let photoOutput = AVCapturePhotoOutput()
    weak var delegate: AVCapturePhotoCaptureDelegate?

    init() {
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.isLivePhotoCaptureEnabled = false
        photoOutput.isDepthDataDeliveryEnabled = false
        photoOutput.maxPhotoQualityPrioritization = .quality
    }

    func takePhoto() throws {
        guard let delegate else { throw SessionError.makePhotoError }
        let settings = makePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    nonisolated func savePhotoInGallery(_ imageData: Data) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            break

        case .notDetermined:
            await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        default:
            throw SessionError.savePhotoToLibraryError
        }

        guard let image = UIImage(data: imageData) else { throw SessionError.savePhotoToLibraryError }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        }
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

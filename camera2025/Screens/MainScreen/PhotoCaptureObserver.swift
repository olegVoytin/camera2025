//
//  PhotoCaptureObserver.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import AVFoundation

@MainMediaActor
protocol PhotoCaptureDelegate: AnyObject {
    func photoWillCaptured()
    func photoDataCreated(data: Data)
    func photoDidCaptured()
}

final class PhotoCaptureObserver: NSObject, AVCapturePhotoCaptureDelegate, Sendable {

    @MainMediaActor weak var delegate: PhotoCaptureDelegate?

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        Task { @MainMediaActor in
            delegate?.photoWillCaptured()
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation() else { return }
        Task { @MainMediaActor in
            delegate?.photoDataCreated(data: data)
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        Task { @MainMediaActor in
            delegate?.photoDidCaptured()
        }
    }
}

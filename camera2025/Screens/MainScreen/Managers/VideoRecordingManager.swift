//
//  VideoRecordingManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

@preconcurrency import AVFoundation
import UIKit
import Photos

@VideoRecordingActor
final class VideoRecordingManager: NSObject {

    private enum RecordingState {
        case idle, start, recording
    }

    private var recordingState: RecordingState = .idle
    private var assetWriter: VideoAssetWriter?

    private var previousVideoOrientation = AVCaptureVideoOrientation.portrait

    @MainMediaActor override init() {}

    func startVideoRecording(captureResolution: CGSize) throws {
        let fileName = UUID().uuidString
        let assetWriter = VideoAssetWriter(fileName: fileName, captureResolution: captureResolution)
        try assetWriter.setupWriter()
        self.assetWriter = assetWriter

        recordingState = .start
    }

    func stopVideoRecording() async throws {
        guard let assetWriter,
              recordingState == .recording else { return }

        recordingState = .idle

        try await assetWriter.finishWriting()

        if let recordedVideoFileURL = assetWriter.recordedVideoFileURL {
            try await saveVideoInGallery(url: recordedVideoFileURL)
        }

        self.assetWriter = nil
    }

    nonisolated private func saveVideoInGallery(url: URL) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            break

        case .notDetermined:
            await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        default:
            throw SessionError.saveVideoToLibraryError
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}

extension VideoRecordingManager: AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        Task { @VideoRecordingActor in
            //обрабатываем захваченные феймы
            switch recordingState {
                //старт записи видео
            case .start:
                setupVideoOutput(sampleBuffer: sampleBuffer)
                setupAudioOutput(sampleBuffer: sampleBuffer)
                await startRecording(sampleBuffer: sampleBuffer)

                //запись видео
            case .recording:
                captureVideoBuffer(sampleBuffer: sampleBuffer)
                captureAudioBuffer(sampleBuffer: sampleBuffer)

            default:
                break
            }
        }
    }

    //установка видео
    private func setupVideoOutput(sampleBuffer: CMSampleBuffer) {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video
        else { return }
        assetWriter.setupVideoInput()
    }

    //установка аудио
    private func setupAudioOutput(sampleBuffer: CMSampleBuffer) {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            let stream = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        else { return }
        assetWriter.setupAudioInput(stream: stream)
    }

    //начать запись видео
    private func startRecording(sampleBuffer: CMSampleBuffer) async {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video
        else { return }

        let currentOrientation = await getDeviceOrientation()
        assetWriter.rotateVideoRelatedOrientation(
            isVideoRecordStartedFromFrontCamera: true,
            previousVideoOrientation: previousVideoOrientation,
            currentOrientation: currentOrientation
        )
        assetWriter.startWriting(buffer: sampleBuffer)

        recordingState = .recording
    }

    //захват видео буфера
    private func captureVideoBuffer(sampleBuffer: CMSampleBuffer) {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video,
            recordingState == .recording
        else { return }
        assetWriter.writeVideo(
            buffer: sampleBuffer,
            currentFrameRate: 60
        )
    }

    //захват аудио буффера
    private func captureAudioBuffer(sampleBuffer: CMSampleBuffer) {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Audio,
            recordingState == .recording
        else { return }
        assetWriter.writeAudio(buffer: sampleBuffer)
    }

    //обработка успешно снятого видео
    private func handleSuccessRecording(outputFileURL: URL?) {
        self.assetWriter = nil
    }

    @MainActor
    private func getDeviceOrientation() -> UIDeviceOrientation {
        UIDevice.current.orientation
    }
}

//
//  VideoRecordingManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

@preconcurrency import AVFoundation
import UIKit

@VideoRecordingActor
final class VideoRecordingManager: NSObject {

    private enum CaptureState {
        case idle, start, capturing
    }

    private var captureState: CaptureState = .idle
    private var assetWriter: VideoAssetWriter?
    private var captureResolution: CGSize?
    private var previousVideoOrientation = AVCaptureVideoOrientation.portrait

    @MainMediaActor override init() {}
}

extension VideoRecordingManager: AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        Task { @VideoRecordingActor in
            //обрабатываем захваченные феймы
            switch captureState {
                //старт записи видео
            case .start:
                setupVideoOutput(sampleBuffer: sampleBuffer)
                setupAudioOutput(sampleBuffer: sampleBuffer)
                await startRecording(sampleBuffer: sampleBuffer)

                //запись видео
            case .capturing:
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
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video,
            let captureResolution
        else { return }
        assetWriter.setupVideoInput(resolution: captureResolution)
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

        captureState = .capturing
    }

    //захват видео буфера
    private func captureVideoBuffer(sampleBuffer: CMSampleBuffer) {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video,
            captureState == .capturing
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
            captureState == .capturing
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

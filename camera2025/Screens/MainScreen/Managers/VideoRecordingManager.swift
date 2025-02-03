//
//  VideoRecordingManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

@preconcurrency import AVFoundation

@VideoRecordingActor
final class VideoRecordingManager: NSObject {

    private enum CaptureState {
        case idle, start, capturing
    }

    private var captureState: CaptureState = .idle
    private var assetWriter: AssetWriter?
    private var captureResolution: CGSize?

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
                await doStartRecording(sampleBuffer: sampleBuffer)

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
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video,
            let captureResolution
        else { return }
        self.assetWriter?.setupVideoInput(resolution: captureResolution)
    }

    //установка аудио
    private func setupAudioOutput(sampleBuffer: CMSampleBuffer) {
        guard
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            let stream = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        else { return }
        self.assetWriter?.setupAudioInput(stream: stream)
    }

    //начать запись видео
    private func doStartRecording(sampleBuffer: CMSampleBuffer) async {
        guard
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video
        else { return }
        await self.assetWriter?.startWriting(
            buffer: sampleBuffer,
            isVideoRecordStartedFromFrontCamera: true,
            previousVideoOrientation: .portrait
        )
        captureState = .capturing
    }

    //захват видео буфера
    private func captureVideoBuffer(sampleBuffer: CMSampleBuffer) {
        guard
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video,
            captureState == .capturing,
            let assetWriter
        else { return }
        assetWriter.writeVideo(
            buffer: sampleBuffer,
            currentFrameRate: 60
        )
    }

    //захват аудио буффера
    private func captureAudioBuffer(sampleBuffer: CMSampleBuffer) {
        guard
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Audio,
            captureState == .capturing,
            let assetWriter
        else { return }
        assetWriter.writeAudio(buffer: sampleBuffer)
    }

    //обработка успешно снятого видео
    private func handleSuccessRecording(outputFileURL: URL?) {
        self.assetWriter = nil
    }
}

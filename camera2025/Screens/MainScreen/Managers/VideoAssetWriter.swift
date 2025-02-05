//
//  VideoAssetWriter.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

@preconcurrency import AVFoundation
import UIKit

@VideoRecordingActor
final class VideoAssetWriter {

    // MARK: - Свойства для записи

    private var videoInput: VideoInput?
    private var audioInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdator: AVAssetWriterInputPixelBufferAdaptor?

    private var isFirstVideoFrameRecieved = false
    private var isInputsSetuped = false

    private var assetWriter: AVAssetWriter
    private let captureResolution: CGSize

    init(captureResolution: CGSize, currentSegmentFilePathURL: URL) throws {
        self.captureResolution = captureResolution
        self.assetWriter = try AVAssetWriter(
            outputURL: currentSegmentFilePathURL,
            fileType: AVFileType.mov
        )
    }

    // MARK: - Настройка записи

    func setupVideoInputIfNeeded() {
        guard self.videoInput == nil else { return }

        let writerOutputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: captureResolution.height,
            AVVideoHeightKey: captureResolution.width
        ] as [String: Any]

        self.videoInput = VideoInput(
            mediaType: AVMediaType.video,
            outputSettings: writerOutputSettings
        )
        self.videoInput?.expectsMediaDataInRealTime = true

        if let videoInput,
           assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
            self.assetWriterInputPixelBufferAdator = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput,
                sourcePixelBufferAttributes: nil
            )
        }
    }

    func setupAudioInputIfNeeded(stream: UnsafePointer<AudioStreamBasicDescription>) {
        guard self.audioInput == nil else { return }
        let audioOutputSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: stream.pointee.mChannelsPerFrame,
            AVSampleRateKey: stream.pointee.mSampleRate,
            AVEncoderBitRateKey: 64_000
        ] as [String: Any]

        self.audioInput = AVAssetWriterInput(
            mediaType: AVMediaType.audio,
            outputSettings: audioOutputSettings
        )
        self.audioInput?.expectsMediaDataInRealTime = true

        if let audioInput,
           assetWriter.canAdd(audioInput) {
            assetWriter.add(audioInput)
        }
    }

    func startWritingIfReady(buffer: CMSampleBuffer) -> Bool {
        guard
            self.audioInput != nil,
            self.videoInput != nil,
            !self.isInputsSetuped
        else { return false }

        self.isInputsSetuped = true

        switch assetWriter.status {
        case .unknown:
            let startTime = CMSampleBufferGetPresentationTimeStamp(buffer)
            let startingTimeDelay = CMTimeMakeWithSeconds(0.7, preferredTimescale: 1_000_000_000)
            let startTimeToUse = CMTimeAdd(startTime, startingTimeDelay)

            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: startTimeToUse)

            return true

        case .failed:
            print("assetWriter статус: failed, ошибка: \(String(describing: assetWriter.error))")
            return false

        default:
            return false
        }
    }

    func rotateVideoRelatedOrientation(
        isVideoRecordStartedFromFrontCamera: Bool,
        previousVideoOrientation: AVCaptureVideoOrientation,
        currentOrientation: UIDeviceOrientation
    ) async {
        guard let videoInput else { return }
        await rotateVideoRelatedOrientation(
            transformableVideoInput: videoInput,
            currentTransform: videoInput.transform,
            isVideoRecordStartedFromFrontCamera: isVideoRecordStartedFromFrontCamera,
            previousVideoOrientation: previousVideoOrientation,
            currentOrientation: currentOrientation
        )
    }

    @MainActor
    private func rotateVideoRelatedOrientation(
        transformableVideoInput: AssetWriterInputTransformable,
        currentTransform: CGAffineTransform,
        isVideoRecordStartedFromFrontCamera: Bool,
        previousVideoOrientation: AVCaptureVideoOrientation,
        currentOrientation: UIDeviceOrientation
    ) {
        let isFrontPortrait = isVideoRecordStartedFromFrontCamera && previousVideoOrientation == .portrait

        let angle: CGFloat
        switch (isFrontPortrait, currentOrientation) {
        case (true, .landscapeLeft), (false, .landscapeRight):
            angle = .pi / 2

        case (true, .landscapeRight), (false, .landscapeLeft):
            angle = -.pi / 2

        default:
            return
        }

        transformableVideoInput.transform(newTransform: currentTransform.rotated(by: angle))
    }

    // MARK: - Методы записи данных
    func writeVideo(buffer: CMSampleBuffer, currentFrameRate: Int) {
        guard
            let assetWriterInputPixelBufferAdator = self.assetWriterInputPixelBufferAdator,
            let assetWriterVideoInput = self.videoInput,
            assetWriterVideoInput.isReadyForMoreMediaData,
            let pixelBuffer = CMSampleBufferGetImageBuffer(buffer)
        else { return }

        let currentPresentationTimestamp = CMSampleBufferGetPresentationTimeStamp(buffer)
        self.isFirstVideoFrameRecieved = true
        assetWriterInputPixelBufferAdator.append(
            pixelBuffer,
            withPresentationTime: currentPresentationTimestamp
        )
    }

    func writeAudio(buffer: CMSampleBuffer) {
        guard
            let audioInput,
            audioInput.isReadyForMoreMediaData,
            self.isFirstVideoFrameRecieved
        else { return }
        audioInput.append(buffer)
    }

    func finishWriting() async {
       await assetWriter.finishWriting()
    }
}

enum AssetWriterError: Error {
    case failedToCreateFileURL
}

@MainActor
private protocol AssetWriterInputTransformable {
    func transform(newTransform: CGAffineTransform)
}

private final class VideoInput: AVAssetWriterInput, AssetWriterInputTransformable {
    func transform(newTransform: CGAffineTransform) {
        self.transform = newTransform
    }
}

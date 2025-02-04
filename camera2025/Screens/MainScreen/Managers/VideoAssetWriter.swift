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

    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdator: AVAssetWriterInputPixelBufferAdaptor?

    private var isFirstVideoFrameRecieved = false
    private var isInputsSetuped = false

    private let assetWriter: AVAssetWriter
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
            AVVideoWidthKey: captureResolution.width,
            AVVideoHeightKey: captureResolution.height
        ] as [String: Any]

        self.videoInput = AVAssetWriterInput(
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

            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: startTime)

            return true

        case .failed:
            print("assetWriter статус: failed, ошибка: \(String(describing: assetWriter.error))")
            return false

        default:
            return false
        }
    }

    func finishWriting() async {
       await assetWriter.finishWriting()
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
}

enum AssetWriterError: Error {
    case failedToCreateFileURL
}

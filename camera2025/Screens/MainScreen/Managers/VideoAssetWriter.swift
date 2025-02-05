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
    private var assetWriter: AVAssetWriter?
    private var videoInput: VideoInput?
    private var audioInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdator: AVAssetWriterInputPixelBufferAdaptor?
    private let captureResolution: CGSize

    private let fileName: String
    var recordedVideoFileURL: URL?

    private var isFirstVideoFrameRecieved = false
    private var isInputsSetuped = false

    // MARK: - Свойства для работы с сегментами (пауза/возобновление)
    /// Храним пути к файлам сегментов
    private var segments: [URL] = []
    /// Индекс текущего сегмента
    private var currentSegmentIndex: Int = 0
    /// Флаг инициализации папки (удаляем старые записи только один раз)
    private var isDirectoryInitialized: Bool = false

    init(fileName: String, captureResolution: CGSize) {
        self.fileName = fileName
        self.captureResolution = captureResolution
    }

    // MARK: - Пути к файлам
    private var videoDirectoryPath: String {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return dir + "/Videos"
    }

    /// Путь к файлу текущего сегмента
    private var currentSegmentFilePathURL: URL {
        let filePath = videoDirectoryPath + "/\(fileName)_segment\(currentSegmentIndex)"
        return URL(fileURLWithPath: filePath).appendingPathExtension("mov")
    }

    /// Путь к итоговому объединённому файлу
    private var finalMergedFileURL: URL {
        let filePath = videoDirectoryPath + "/merged_\(fileName)"
        return URL(fileURLWithPath: filePath).appendingPathExtension("mov")
    }

    // MARK: - Настройка записи
    func setupWriter() throws {
        guard self.assetWriter == nil else { return }

        if !isDirectoryInitialized {
            // Удаляем старую папку с видео (если существует) только один раз
            if FileManager.default.fileExists(atPath: self.videoDirectoryPath) {
                try FileManager.default.removeItem(atPath: self.videoDirectoryPath)
            }
            try FileManager.default.createDirectory(
                atPath: self.videoDirectoryPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            isDirectoryInitialized = true
        }

        self.assetWriter = try AVAssetWriter(
            outputURL: currentSegmentFilePathURL,
            fileType: AVFileType.mov
        )
        // Сбрасываем входы и флаги для нового сегмента
        self.videoInput = nil
        self.audioInput = nil
        self.assetWriterInputPixelBufferAdator = nil
        self.isInputsSetuped = false
        self.isFirstVideoFrameRecieved = false
    }

    func setupVideoInputIfNeeded() {
        guard let assetWriter,
              self.videoInput == nil else { return }

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
        guard let assetWriter,
              self.audioInput == nil else { return }
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
            let assetWriter,
            self.audioInput != nil,
            self.videoInput != nil,
            !self.isInputsSetuped
        else { return false }

        self.isInputsSetuped = true

        switch assetWriter.status {
        case .unknown:
            print("Начало записи сегмента \(currentSegmentIndex)")
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
//        let isFrontPortrait = isVideoRecordStartedFromFrontCamera && previousVideoOrientation == .portrait
//
        let angle: CGFloat
//        switch (isFrontPortrait, currentOrientation) {
//        case (true, .landscapeLeft), (false, .landscapeRight):
            angle = .pi / 2
//
//        case (true, .landscapeRight), (false, .landscapeLeft):
//            angle = -.pi / 2
//
//        default:
//            return
//        }

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

    // MARK: - Поддержка паузы/возобновления
    /// Завершает запись текущего сегмента
    func finishCurrentSegment() async throws {
        guard let assetWriter, assetWriter.status == .writing else {
            return
        }
        await assetWriter.finishWriting()
        // Сохраняем URL сегмента
        segments.append(currentSegmentFilePathURL)
        // Обнуляем assetWriter для следующего сегмента
        self.assetWriter = nil
    }

    /// Метод для постановки записи на паузу: завершает запись текущего сегмента
    func pauseRecording() async throws {
        guard let assetWriter, assetWriter.status == .writing else {
            return
        }
        print("Пауза записи сегмента \(currentSegmentIndex)")
        try await finishCurrentSegment()
    }

    /// Метод для возобновления записи: создаёт новый сегмент
    func resumeRecording() throws {
        // Увеличиваем индекс сегмента
        currentSegmentIndex += 1
        // Создаём новый assetWriter для нового сегмента
        try setupWriter()
        print("Возобновление записи. Новый сегмент \(currentSegmentIndex)")
    }

    // MARK: - Завершение записи и слияние сегментов
    /// Завершает запись (если идёт активная запись) и объединяет все сегменты в один итоговый файл
    func finishRecording() async throws {
        // Если запись текущего сегмента ещё идёт – завершаем его
        if let assetWriter, assetWriter.status == .writing {
            try await finishCurrentSegment()
        }
        // Слияние сегментов в один файл
        try await mergeSegments()
    }

    /// Объединяет записанные сегменты в один файл с помощью AVMutableComposition и AVAssetExportSession
    private func mergeSegments() async throws {
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw AssetWriterError.failedToCreateFileURL
        }
        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        var currentTime = CMTime.zero

        for segmentURL in segments {
            let asset = AVAsset(url: segmentURL)
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)

            // Вставляем видео-трек
            if let assetVideoTrack = asset.tracks(withMediaType: .video).first {
                try compositionVideoTrack.insertTimeRange(
                    timeRange,
                    of: assetVideoTrack,
                    at: currentTime
                )
            }

            // Вставляем аудио-трек (если есть)
            if let assetAudioTrack = asset.tracks(withMediaType: .audio).first,
               let compositionAudioTrack = compositionAudioTrack {
                try compositionAudioTrack.insertTimeRange(
                    timeRange,
                    of: assetAudioTrack,
                    at: currentTime
                )
            }

            currentTime = CMTimeAdd(currentTime, asset.duration)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw AssetWriterError.failedToCreateFileURL
        }

        exportSession.outputURL = finalMergedFileURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                if exportSession.status == .completed {
                    continuation.resume(returning: ())
                } else {
                    let error = exportSession.error ?? NSError(domain: "MergeError", code: -1, userInfo: nil)
                    continuation.resume(throwing: error)
                }
            }
        }

        recordedVideoFileURL = finalMergedFileURL
        print("Сегменты объединены. Итоговый файл: \(finalMergedFileURL)")
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

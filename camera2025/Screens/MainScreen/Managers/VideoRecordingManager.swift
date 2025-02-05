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

    enum RecordingState {
        case idle, start, recording, paused
    }

    var recordingState: RecordingState = .idle
    var recordingDeviceOrientation: UIDeviceOrientation?

    private var assetWriter: VideoAssetWriter?

    // MARK: - Свойства для работы с сегментами (пауза/возобновление)
    /// Храним пути к файлам сегментов
    private var segments: [URL] = []
    /// Индекс текущего сегмента
    private var currentSegmentIndex: Int = 0

    private var fileName: String?
    private var recordedVideoFileURL: URL?

    // MARK: - Пути к файлам
    private var videoDirectoryPath: String {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return dir + "/Videos"
    }

    /// Путь к файлу текущего сегмента
    private var currentSegmentFilePathURL: URL {
        guard let fileName else { return URL(fileURLWithPath: "") }
        let filePath = videoDirectoryPath + "/\(fileName)_segment\(currentSegmentIndex)"
        return URL(fileURLWithPath: filePath).appendingPathExtension("mov")
    }

    /// Путь к итоговому объединённому файлу
    private var finalMergedFileURL: URL {
        guard let fileName else { return URL(fileURLWithPath: "") }
        let filePath = videoDirectoryPath + "/merged_\(fileName)"
        return URL(fileURLWithPath: filePath).appendingPathExtension("mov")
    }

    @MainMediaActor override init() {}

    func startNewRecording(
        captureResolution: CGSize,
        recordingDeviceOrientation: UIDeviceOrientation
    ) throws {
        reset()
        self.recordingDeviceOrientation = recordingDeviceOrientation

        // Удаляем старую папку с видео (если существует) только один раз
        if FileManager.default.fileExists(atPath: videoDirectoryPath) {
            try FileManager.default.removeItem(atPath: videoDirectoryPath)
        }
        try FileManager.default.createDirectory(
            atPath: videoDirectoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        try recordNewSegment(captureResolution: captureResolution)
    }

    func pauseRecordingIfNeeded() async {
        guard let assetWriter,
              recordingState == .recording else { return }

        recordingState = .paused

        await assetWriter.finishWriting()
        segments.append(currentSegmentFilePathURL)

        self.assetWriter = nil
    }

    func resumeRecordingIfNeeded(captureResolution: CGSize) async throws {
        guard recordingState == .paused else { return }

        currentSegmentIndex += 1

        try recordNewSegment(captureResolution: captureResolution)
    }

    func stopRecording() async throws {
        guard let assetWriter,
              recordingState == .recording else { return }

        recordingState = .idle

        await assetWriter.finishWriting()

        segments.append(currentSegmentFilePathURL)

        try await mergeSegments()

        recordedVideoFileURL = finalMergedFileURL

        if let recordedVideoFileURL = recordedVideoFileURL {
            try await saveVideoInGallery(url: recordedVideoFileURL)
        }

        self.assetWriter = nil
        recordingDeviceOrientation = nil
    }

    func reset() {
        segments = []
        currentSegmentIndex = 0
        recordedVideoFileURL = nil
        recordingDeviceOrientation = nil
        assetWriter = nil
        recordingState = .idle
    }

    private func recordNewSegment(captureResolution: CGSize) throws {
        let fileName = UUID().uuidString
        self.fileName = fileName

        let assetWriter = try VideoAssetWriter(
            captureResolution: captureResolution,
            currentSegmentFilePathURL: currentSegmentFilePathURL
        )
        self.assetWriter = assetWriter

        recordingState = .start
    }

    /// Объединяет записанные сегменты в один файл с помощью AVMutableComposition и AVAssetExportSession
    private func mergeSegments() async throws {
        let composition = AVMutableComposition()

        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { throw AssetWriterError.failedToCreateFileURL }

        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        var currentTime = CMTime.zero

        for segmentURL in segments {
            let asset = AVURLAsset(url: segmentURL)
            let duration = try await asset.load(.duration)
            let timeRange = CMTimeRange(start: .zero, duration: duration)

            // Вставляем видео-трек
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            if let assetVideoTrack = videoTracks.first {
                try compositionVideoTrack.insertTimeRange(
                    timeRange,
                    of: assetVideoTrack,
                    at: currentTime
                )
            }

            // Вставляем аудио-трек (если есть)
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            if let assetAudioTrack = audioTracks.first,
               let compositionAudioTrack = compositionAudioTrack {
                try compositionAudioTrack.insertTimeRange(
                    timeRange,
                    of: assetAudioTrack,
                    at: currentTime
                )
            }

            currentTime = CMTimeAdd(currentTime, duration)
        }

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else { throw AssetWriterError.failedToCreateFileURL }

        exportSession.outputURL = finalMergedFileURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        try await exportSession.export(to: finalMergedFileURL, as: .mov)
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
            switch recordingState {
            case .start:
                setupVideoInputIfNeeded(sampleBuffer: sampleBuffer)
                setupAudioInputIfNeeded(sampleBuffer: sampleBuffer)
                await startRecordingIfReady(sampleBuffer: sampleBuffer)

            case .recording:
                captureVideoBuffer(sampleBuffer: sampleBuffer)
                captureAudioBuffer(sampleBuffer: sampleBuffer)

            default:
                break
            }
        }
    }

    private func setupVideoInputIfNeeded(sampleBuffer: CMSampleBuffer) {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video
        else { return }
        assetWriter.setupVideoInputIfNeeded()
    }

    private func setupAudioInputIfNeeded(sampleBuffer: CMSampleBuffer) {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            let stream = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        else { return }
        assetWriter.setupAudioInputIfNeeded(stream: stream)
    }

    private func startRecordingIfReady(sampleBuffer: CMSampleBuffer) async {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Video
        else { return }

        let isWritingStarted = assetWriter.startWritingIfReady(buffer: sampleBuffer)
        if isWritingStarted {
            recordingState = .recording
        }
    }

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

    private func captureAudioBuffer(sampleBuffer: CMSampleBuffer) {
        guard
            let assetWriter,
            let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            CMFormatDescriptionGetMediaType(format) == kCMMediaType_Audio,
            recordingState == .recording
        else { return }
        assetWriter.writeAudio(buffer: sampleBuffer)
    }

    @MainActor
    private func getDeviceOrientation() -> UIDeviceOrientation {
        UIDevice.current.orientation
    }
}

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
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdator: AVAssetWriterInputPixelBufferAdaptor?
    private let captureResolution: CGSize

    private let fileName: String
    var recordedVideoFileURL: URL?

    private var isFirstVideoFrameRecieved = false
    private var isInputsSetuped = false

    init(fileName: String, captureResolution: CGSize) {
        self.fileName = fileName
        self.captureResolution = captureResolution
    }

    private var videoDirectoryPath: String {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return dir + "/Videos"
    }

    private var filePathURL: URL {
        let filePath = videoDirectoryPath + "/\(fileName)"
        return URL(fileURLWithPath: filePath).appendingPathExtension("mov")
    }

    func setupWriter() throws {
        guard self.assetWriter == nil else { return }

        if FileManager.default.fileExists(atPath: self.videoDirectoryPath) {
            try FileManager.default.removeItem(atPath: self.videoDirectoryPath)
        }

        try FileManager.default.createDirectory(
            atPath: self.videoDirectoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        self.assetWriter = try AVAssetWriter(
            outputURL: filePathURL,
            fileType: AVFileType.mov
        )
    }

    func setupVideoInputIfNeeded() {
        guard let assetWriter,
                self.videoInput == nil else { return }

        let writerOutputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: captureResolution.height,
            AVVideoHeightKey: captureResolution.width
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
            print("Start writing")
            let startTime = CMSampleBufferGetPresentationTimeStamp(buffer)
            let startingTimeDelay = CMTimeMakeWithSeconds(0.7, preferredTimescale: 1_000_000_000)
            let startTimeToUse = CMTimeAdd(startTime, startingTimeDelay)

            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: startTimeToUse)

            return true

        case .failed:
            print("assetWriter status: failed error: \(String(describing: assetWriter.error))")
            return false

        default:
            return false
        }
    }

    func rotateVideoRelatedOrientation(
        isVideoRecordStartedFromFrontCamera: Bool,
        previousVideoOrientation: AVCaptureVideoOrientation,
        currentOrientation: UIDeviceOrientation
    ) {
        guard let transform = self.videoInput?.transform else { return }

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

        self.videoInput?.transform = transform.rotated(by: angle)
    }

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

    func finishWriting() async throws {
        guard
            let assetWriter,
            assetWriter.status == .writing
        else { throw AssetWriterError.failedToCreateFileURL }

        await assetWriter.finishWriting()

        recordedVideoFileURL = filePathURL
    }
}

enum AssetWriterError: Error {
    case failedToCreateFileURL
}

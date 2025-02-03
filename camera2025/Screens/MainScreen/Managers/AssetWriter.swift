//
//  AssetWriter.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

@preconcurrency import AVFoundation

@VideoRecordingActor
final class AssetWriter {
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdator: AVAssetWriterInputPixelBufferAdaptor?
    private let fileName: String
    private var isFirstVideoFrameRecieved = false
    private var isInputsSetuped = false

    init(fileName: String) {
        self.fileName = fileName
    }

    private var videoDirectoryPath: String {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return dir + "/Videos"
    }

    private var filePath: String {
        return videoDirectoryPath + "/\(fileName)"
    }

    func setupWriter() throws {
        guard self.assetWriter == nil else { return }
        //создаем директорию для видео
        if FileManager.default.fileExists(atPath: self.videoDirectoryPath) {
            try FileManager.default.removeItem(atPath: self.videoDirectoryPath)
        }

        try FileManager.default.createDirectory(
            atPath: self.videoDirectoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        //инициализируем райтер
        self.assetWriter = try AVAssetWriter(
            outputURL: URL(fileURLWithPath: self.filePath).appendingPathExtension("mov"),
            fileType: AVFileType.mov
        )
    }

    //установка видео инпута
    func setupVideoInput(resolution: CGSize) {
        guard let assetWriter,
                self.videoInput == nil else { return }

        let writerOutputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: resolution.height,
            AVVideoHeightKey: resolution.width
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

    //установка аудио инпута
    func setupAudioInput(stream: UnsafePointer<AudioStreamBasicDescription>) {
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

    //начать запись
    func startWriting(
        buffer: CMSampleBuffer,
        isVideoRecordStartedFromFrontCamera: Bool,
        previousVideoOrientation: AVCaptureVideoOrientation
    ) async {
        guard let assetWriter,
              self.audioInput != nil,
              self.videoInput != nil,
              !self.isInputsSetuped else { return }

        self.isInputsSetuped = true

//        DispatchQueue.main.sync {
//            let orientation = UIDevice.current.orientation
//
//            if isVideoRecordStartedFromFrontCamera && previousVideoOrientation == .portrait {
//                if orientation == .landscapeLeft,
//                   let transform = self.videoInput?.transform.rotated(by: .pi / 2) {
//                    self.videoInput?.transform = transform
//                } else
//                if orientation == .landscapeRight,
//                   let transform = self.videoInput?.transform.rotated(by: .pi / -2) {
//                    self.videoInput?.transform = transform
//                }
//            } else {
//                if orientation == .landscapeLeft,
//                   let transform = self.videoInput?.transform.rotated(by: .pi / -2) {
//                    self.videoInput?.transform = transform
//                } else
//                if orientation == .landscapeRight,
//                   let transform = self.videoInput?.transform.rotated(by: .pi / 2) {
//                    self.videoInput?.transform = transform
//                }
//            }
//        }

        if assetWriter.status == .unknown {
            print("Start writing")
            let startTime = CMSampleBufferGetPresentationTimeStamp(buffer)
            let startingTimeDelay = CMTimeMakeWithSeconds(0.7, preferredTimescale: 1_000_000_000)
            let startTimeToUse = CMTimeAdd(startTime, startingTimeDelay)

            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: startTimeToUse)
        }

        if self.assetWriter?.status == .failed {
            print("assetWriter status: failed error: \(String(describing: self.assetWriter?.error))")
            return
        }
    }

    //записать видео
    func writeVideo(buffer: CMSampleBuffer, currentFrameRate: Int) {
        if let assetWriterInputPixelBufferAdator = self.assetWriterInputPixelBufferAdator,
           let assetWriterVideoInput = self.videoInput,
           assetWriterVideoInput.isReadyForMoreMediaData,
           let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let currentPresentationTimestamp = CMSampleBufferGetPresentationTimeStamp(buffer)
            self.isFirstVideoFrameRecieved = true
            assetWriterInputPixelBufferAdator.append(
                pixelBuffer,
                withPresentationTime: currentPresentationTimestamp
            )
        }
    }

    //записать аудио
    func writeAudio(buffer: CMSampleBuffer) {
        if let audioInput,
           audioInput.isReadyForMoreMediaData,
           self.isFirstVideoFrameRecieved {
            audioInput.append(buffer)
        }
    }

    //остановить запись
    func finishWriting() async -> URL? {
        guard let assetWriter, assetWriter.status == .writing else { return nil }
        await assetWriter.finishWriting()
        return URL(fileURLWithPath: self.filePath).appendingPathExtension("mov")
    }
}

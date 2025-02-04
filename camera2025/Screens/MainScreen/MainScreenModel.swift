//
//  MainScreenModel.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

final class MainScreenModel {
    var isVideoRecordingActive: Bool = false
    let triggerAction: (Action) -> Void

    internal init(triggerAction: @escaping (Action) -> Void) {
        self.triggerAction = triggerAction
    }
}

enum Action {
    case takePhoto
    case startVideoRecording
    case stopVideoRecording
}

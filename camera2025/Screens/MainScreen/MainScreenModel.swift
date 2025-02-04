//
//  MainScreenModel.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import Observation

@Observable
final class MainScreenModel {

    var isTakingPhotoPossible: Bool = true

    var isVideoRecordingActive: Bool = false
    var isVideoRecordingStateChangePossible: Bool = true

    let triggerAction: (Action) -> Void

    init(triggerAction: @escaping (Action) -> Void) {
        self.triggerAction = triggerAction
    }
}

enum Action {
    case takePhoto
    case startVideoRecording
    case stopVideoRecording
    case changeCameraPosition
}

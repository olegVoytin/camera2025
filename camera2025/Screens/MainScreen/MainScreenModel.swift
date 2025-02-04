//
//  MainScreenModel.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

struct MainScreenModel: Sendable {
    let triggerAction: @Sendable (Action) -> Void
}

enum Action {
    case takePhoto
    case startVideoRecording
    case stopVideoRecording
}

//
//  MainScreenActionHandler.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

struct MainScreenActionHandler: Sendable {
    let triggerAction: @Sendable (Action) -> Void
}

enum Action {
    case takePhoto
    case startVideoRecording
}

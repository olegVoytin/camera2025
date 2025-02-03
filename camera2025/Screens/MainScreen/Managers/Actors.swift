//
//  Actors.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

@globalActor
actor MainMediaActor {
    static var shared = MainMediaActor()
    typealias ActorType = MainMediaActor
}

@globalActor
actor VideoRecordingActor {
    static var shared = MainMediaActor()
    typealias ActorType = MainMediaActor
}

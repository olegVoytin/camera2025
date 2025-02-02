//
//  CaptureManager.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

@CapturingActor
final class CaptureManager {

    let sessionsManager = SessionsManager()

    func startCapture() {
        do {
            try sessionsManager.start()
        } catch {
            guard let error = error as? SessionError else {
                return
            }
            print(error.localizedDescription)
        }
    }
}

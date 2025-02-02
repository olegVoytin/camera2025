//
//  CaptureService.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

@CapturingActor
final class CaptureService {

    let sessionsService = SessionsService()

    func startCapture() {
        do {
            try sessionsService.start()
        } catch {
            guard let error = error as? SessionError else {
                return
            }
            print(error.localizedDescription)
        }
    }
}

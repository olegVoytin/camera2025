//
//  camera2025App.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import SwiftUI

@MainActor
final class AppService: ObservableObject {

    var cameraPreviewPresenter: PreviewPresenter?
    @Published var presentCameraPreview: Bool = false

    func startCameraPreview() async {
        let newPreviewPresenter = await PreviewPresenter()
        await newPreviewPresenter.startSession()
        cameraPreviewPresenter = newPreviewPresenter
        presentCameraPreview = true
    }
}

@main
struct camera2025App: App {

    @StateObject private var appService = AppService()

    var body: some Scene {
        WindowGroup {
            InitialView()
                .task {
                    await appService.startCameraPreview()
                }
                .fullScreenCover(isPresented: $appService.presentCameraPreview) {
                    if let previewPresenter = appService.cameraPreviewPresenter {
                        CameraPreview(presenter: previewPresenter)
                    }
                }
        }
    }
}

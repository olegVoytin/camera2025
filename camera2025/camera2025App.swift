//
//  camera2025App.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import SwiftUI
@preconcurrency import AVFoundation

@MainActor
final class AppManager: ObservableObject {

    var mainScreenData: (MainScreenModel, AVCaptureSession)?
    @Published var presentMainScreen: Bool = false

    func startCameraPreview() async {
        do {
            let mainMediaManager = try await MainMediaManager(deviceManager: DeviceManager())
            let mainScreenPresenter = await MainScreenPresenter(mainMediaManager: mainMediaManager)
            try await mainScreenPresenter.startSession()

            let model = mainScreenPresenter.model
            let videoCaptureSession = await mainScreenPresenter.videoCaptureSession
            self.mainScreenData = (model, videoCaptureSession)
            presentMainScreen = true
        } catch {
            fatalError()
        }
    }
}

@main
struct camera2025App: App {

    @StateObject private var appManager = AppManager()

    var body: some Scene {
        WindowGroup {
            InitialView()
                .task {
                    await appManager.startCameraPreview()
                }
                .fullScreenCover(isPresented: $appManager.presentMainScreen) {
                    if let mainScreenData = appManager.mainScreenData {
                        MainScreenView(
                            videoCaptureSession: mainScreenData.1,
                            model: mainScreenData.0
                        )
                    }
                }
        }
    }
}

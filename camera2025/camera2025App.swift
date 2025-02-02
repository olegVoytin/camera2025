//
//  camera2025App.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import SwiftUI
@preconcurrency import AVFoundation

@MainActor
final class AppService: ObservableObject {

    var mainScreenData: (MainScreenActionHandler, AVCaptureSession)?
    @Published var presentMainScreen: Bool = false

    func startCameraPreview() async {
        let mainScreenPresenter = await MainScreenPresenter()
        await mainScreenPresenter.startSession()

        self.mainScreenData = await (
            mainScreenPresenter.createActionHandler(),
            mainScreenPresenter.videoCaptureSession
        )
        presentMainScreen = true
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
                .fullScreenCover(isPresented: $appService.presentMainScreen) {
                    if let mainScreenData = appService.mainScreenData {
                        MainScreenView(
                            videoCaptureSession: mainScreenData.1,
                            actionHandler: mainScreenData.0
                        )
                    }
                }
        }
    }
}

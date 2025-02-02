//
//  camera2025App.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import SwiftUI

@main
struct camera2025App: App {

    @State private var sessionStarted = false
    @State private var presenter: PreviewPresenter?

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                InitialView()
                    .onAppear {
                        Task { @MainActor in
                            let presenter = await PreviewPresenter()
                            await presenter.startSession()
                            sessionStarted = true
                        }
                    }
                    .navigationDestination(isPresented: $sessionStarted) {
                        if let presenter {
                            CameraPreview(presenter: presenter)
                        }
                    }
            }
        }
    }
}

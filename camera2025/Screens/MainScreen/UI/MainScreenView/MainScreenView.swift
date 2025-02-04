//
//  MainScreenView.swift
//  camera2025
//
//  Created by Олег Войтин on 02.02.2025.
//

import SwiftUI
import AVFoundation

struct MainScreenView: View {

    let videoCaptureSession: AVCaptureSession
    let model: MainScreenModel

    var body: some View {
        ZStack {
            PreviewView(videoCaptureSession: videoCaptureSession)

            VStack {
                Spacer()

                HStack(spacing: 30) {
                    Button(
                        action: {
                            model.triggerAction(
                                model.isVideoRecordingActive ? .stopVideoRecording : .startVideoRecording
                            )
                        },
                        label: {
                            Color.red
                                .frame(width: 50, height: 50)
                        }
                    )

                    Button(
                        action: { model.triggerAction(.takePhoto) },
                        label: {
                            Color.white
                                .frame(width: 100, height: 100)
                        }
                    )
                }
                .padding(.bottom, 20)
            }
        }
    }
}

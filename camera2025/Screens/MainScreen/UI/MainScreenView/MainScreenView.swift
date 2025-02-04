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
                    .allowsHitTesting(model.isVideoRecordingPossible)

                    PhotoButton(model: model)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

private struct PhotoButton: View {

    let model: MainScreenModel
    @State private var isPressed: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 80, height: 80)

            Circle()
                .fill(Color.white)
                .frame(width: 70, height: 70)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.interactiveSpring, value: isPressed)
        }
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { pressed in
                isPressed = pressed
            },
            perform: {}
        )
        .allowsHitTesting(model.isTakingPhotoPossible)
    }
}

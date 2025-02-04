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
                    VideoButton(model: model)
                    PhotoButton(model: model)
                    ChangeCameraButton(model: model)
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

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.interactiveSpring, value: isPressed)

                if !model.isTakingPhotoPossible {
                    ProgressView()
                }
            }
        }
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { pressed in
                if !pressed {
                    model.triggerAction(.takePhoto)
                }

                isPressed = pressed
            },
            perform: {}
        )
        .allowsHitTesting(model.isTakingPhotoPossible)
    }
}

private struct VideoButton: View {

    let model: MainScreenModel

    @State private var isPressed: Bool = false

    private var outerSize: CGFloat { model.isVideoRecordingActive ? 80 : 60 }
    private var innerSize: CGFloat { model.isVideoRecordingActive ? 40 : 30 }
    private var innerCornerRadius: CGFloat { model.isVideoRecordingActive ? 10 : innerSize / 2 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: outerSize, height: outerSize)
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .animation(.interactiveSpring, value: isPressed)

            RoundedRectangle(cornerRadius: innerCornerRadius)
                .fill(Color.red)
                .frame(width: innerSize, height: innerSize)
                .animation(.spring, value: model.isVideoRecordingActive)
        }
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { pressed in
                if !pressed {
                    model.triggerAction(
                        model.isVideoRecordingActive ? .stopVideoRecording : .startVideoRecording
                    )
                }

                isPressed = pressed
            },
            perform: {}
        )
        .animation(.spring, value: model.isVideoRecordingActive)
        .allowsHitTesting(model.isVideoRecordingStateChangePossible)
    }
}

private struct ChangeCameraButton: View {

    let model: MainScreenModel
    @State private var isPressed: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 60, height: 60)

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)

                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill")
                    .frame(width: 50, height: 50)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.interactiveSpring, value: isPressed)
        }
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { pressed in
                if !pressed {
                    model.triggerAction(.changeCameraPosition)
                }

                isPressed = pressed
            },
            perform: {}
        )
        .allowsHitTesting(model.isTakingPhotoPossible)
    }
}

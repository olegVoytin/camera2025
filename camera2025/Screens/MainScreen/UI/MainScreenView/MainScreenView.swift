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

    @State private var shutterOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.purple
                .ignoresSafeArea()

            PreviewView(videoCaptureSession: videoCaptureSession)

            topButtons

            bottomButtons

            Color.white
                .opacity(shutterOpacity)
                .ignoresSafeArea()
        }
    }

    private var topButtons: some View {
        HStack {
            Button(
                action: { model.triggerAction(.setNewTorchMode(.off)) },
                label: {
                    Image(systemName: "bolt.slash.fill")
                        .frame(width: 50, height: 50)
                }
            )
            .foregroundStyle(model.selectedTorchMode == .off ? .yellow : .white)

            Button(
                action: { model.triggerAction(.setNewTorchMode(.on)) },
                label: {
                    Image(systemName: "bolt.fill")
                        .frame(width: 50, height: 50)
                }
            )
            .foregroundStyle(model.selectedTorchMode == .on ? .yellow : .white)

            Button(
                action: { model.triggerAction(.setNewTorchMode(.auto)) },
                label: {
                    Image(systemName: "bolt.badge.automatic.fill")
                        .frame(width: 50, height: 50)
                }
            )
            .foregroundStyle(model.selectedTorchMode == .auto ? .yellow : .white)

            Spacer()
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var bottomButtons: some View {
        HStack(spacing: 30) {
            VideoButton(model: model)

            if !model.isVideoRecordingActive {
                PhotoButton(model: model, onTakePhoto: onTakePhoto)
                    .transition(.opacity)
            }

            ChangeCameraButton(model: model)
        }
        .padding(.bottom, 20)
        .animation(.spring, value: model.isVideoRecordingActive)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func onTakePhoto() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        Task { @MainActor in
            withAnimation(.easeIn(duration: 0.1)) {
                shutterOpacity = 0.8
            }

            generator.impactOccurred()

            try? await Task.sleep(nanoseconds: 100_000_000)

            withAnimation(.easeOut(duration: 0.2)) {
                shutterOpacity = 0.0
            }
        }
    }
}

private struct PhotoButton: View {
    let model: MainScreenModel
    let onTakePhoto: () -> Void
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
                    onTakePhoto()
                }
                isPressed = pressed
            },
            perform: {}
        )
        .allowsHitTesting(model.isTakingPhotoPossible)
        .opacity(model.isTakingPhotoPossible ? 1 : 0.3)
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
        .contentShape(
            Circle()
                .inset(by: -20)
        )
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
        .allowsHitTesting(model.isVideoRecordingStateChangePossible)
        .opacity(model.isVideoRecordingStateChangePossible ? 1 : 0.3)
        .animation(.spring, value: model.isVideoRecordingActive)
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

//
//  CameraPreview.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//
import AVFoundation
import SwiftUI


struct CameraPreview: UIViewRepresentable {
    var captureSession: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

//
//  CameraPreview.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewControllerRepresentable {
    var captureSession: AVCaptureSession

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = LandscapeCameraViewController()
        controller.captureSession = captureSession
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let controller = uiViewController as? LandscapeCameraViewController {
            // Asegúrate de que la capa de vista previa ocupe todo el tamaño de la vista
            DispatchQueue.main.async {
                controller.previewLayer?.frame = uiViewController.view.bounds
            }
        }
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer // Save the reference
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer.frame = uiView.bounds // Ensure the layer is resized
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: CameraPreview
        var previewLayer: AVCaptureVideoPreviewLayer!

        init(_ parent: CameraPreview) {
            self.parent = parent
        }
    }
}





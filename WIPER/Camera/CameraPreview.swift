//
//  CameraPreview.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//

import SwiftUI
import AVFoundation

/**
 Componente SwiftUI que proporciona una vista previa de la cámara en modo horizontal.
 Utiliza UIViewControllerRepresentable para integrar un controlador nativo de UIKit
 que garantiza la orientación correcta en modo paisaje.
 */
struct CameraPreview: UIViewControllerRepresentable {
    // MARK: - Propiedades
    
    /// Sesión de captura que proporciona el flujo de video
    var captureSession: AVCaptureSession

    // MARK: - UIViewControllerRepresentable

    /// Crea el controlador de vista que maneja la previsualización de la cámara
    func makeUIViewController(context: Context) -> UIViewController {
        // Crear e inicializar el controlador especializado para orientación horizontal
        let controller = LandscapeCameraViewController()
        controller.captureSession = captureSession
        return controller
    }

    /// Actualiza el controlador de vista cuando hay cambios en los parámetros
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Ajustar el tamaño de la capa de previsualización si es necesario
        if let controller = uiViewController as? LandscapeCameraViewController {
            DispatchQueue.main.async {
                controller.previewLayer?.frame = uiViewController.view.bounds
            }
        }
    }

    /// Crea un coordinador para manejar la comunicación entre SwiftUI y UIKit
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    
    /**
     Clase coordinadora que facilita la comunicación entre SwiftUI y UIKit.
     Actúa como intermediario para eventos y actualizaciones.
     */
    class Coordinator: NSObject {
        /// Referencia a la vista padre
        var parent: CameraPreview

        /// Inicializador que establece la referencia al padre
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
    }
}

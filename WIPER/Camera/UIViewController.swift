//
//  LandscapeCameraViewController.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//

import AVFoundation
import UIKit

/**
 Controlador de vista especializado para mostrar la previsualización de la cámara en orientación horizontal.
 Gestiona la capa de previsualización y se asegura de que la orientación sea correcta independientemente
 de cómo sostenga el usuario el dispositivo.
 */
class LandscapeCameraViewController: UIViewController {
    // MARK: - Propiedades
    
    /// Sesión de captura que proporciona el flujo de video
    var captureSession: AVCaptureSession?
    
    /// Capa de previsualización que muestra el contenido de la cámara
    var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Ciclo de vida
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Verificar que tengamos una sesión válida
        guard let session = captureSession else { return }

        // Configurar la capa de previsualización
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        // Añadir la capa de previsualización a la jerarquía de vistas
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        // Registrar observador para cambios de orientación
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(orientationDidChange),
                                              name: UIDevice.orientationDidChangeNotification,
                                              object: nil)
        
        // Configurar orientación inicial
        updatePreviewLayerOrientation()
    }
    
    /// Limpieza al destruir el controlador
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                 name: UIDevice.orientationDidChangeNotification,
                                                 object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Actualizar el tamaño de la capa cuando cambia el layout
        previewLayer?.frame = view.bounds
    }
    
    // MARK: - Configuración de orientación
    
    /// Especifica que solo se permite orientación horizontal
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    /// Evita rotación automática para mejor control
    override var shouldAutorotate: Bool {
        return false
    }
    
    /// Manejador de cambios de orientación del dispositivo
    @objc func orientationDidChange() {
        updatePreviewLayerOrientation()
    }

    /**
     Actualiza la orientación de la capa de previsualización según la orientación del dispositivo.
     Esto asegura que la imagen de la cámara se muestre correctamente sin importar
     cómo sostenga el usuario el dispositivo.
     */
    private func updatePreviewLayerOrientation() {
        guard let connection = previewLayer?.connection else { return }

        let deviceOrientation = UIDevice.current.orientation

        // Mapear la orientación del dispositivo a la orientación del video
        switch deviceOrientation {
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        case .portrait:
            connection.videoOrientation = .portrait
        default:
            // Valor predeterminado para orientaciones como faceUp, faceDown o desconocidas
            connection.videoOrientation = .landscapeRight
        }
    }
}

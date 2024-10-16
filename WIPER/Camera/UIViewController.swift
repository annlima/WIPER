import AVFoundation
import UIKit

class LandscapeCameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let session = captureSession else { return }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill  // Ajuste para llenar la pantalla
        previewLayer?.frame = view.bounds
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }

        // Observador para detectar cambios de orientación
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)

        // Asegúrate de configurar la orientación correcta en la carga inicial
        updatePreviewLayerOrientation()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape // Fijar en landscape
    }

    override var shouldAutorotate: Bool {
        return false // No permitir la rotación automática
    }

    // Método que se ejecuta cuando cambia la orientación del dispositivo
    @objc func orientationDidChange() {
        updatePreviewLayerOrientation()
    }

    // Ajusta la orientación de la vista previa de la cámara según la orientación del dispositivo
    private func updatePreviewLayerOrientation() {
        guard let connection = previewLayer?.connection else { return }

        let deviceOrientation = UIDevice.current.orientation

        // Ajusta la orientación del video en función de la orientación del dispositivo
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
            connection.videoOrientation = .landscapeRight // Valor predeterminado
        }
    }
}

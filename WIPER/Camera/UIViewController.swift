import AVFoundation
import UIKit

class LandscapeCameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let session = captureSession else { return }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
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
        return .landscape
    }
    override var shouldAutorotate: Bool {
        return false
    }
    @objc func orientationDidChange() {
        updatePreviewLayerOrientation()
    }

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

import AVFoundation
import CoreML
import Vision
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    private var visionModel: VNCoreMLModel?
    public var detectionLayer = CALayer()

    override init() {
        super.init()
        // Cargar el modelo CoreML
        if let model = try? VNCoreMLModel(for: Demo().model) {  // Cambia `Demo` por el nombre de tu modelo CoreML
            self.visionModel = model
        }
    }

    func setUp(cameraViewModel: CameraViewModel, completion: @escaping (Result<Void, Error>) -> Void) {
        // Configuración de la cámara (igual que en tu código)
        AVCaptureDevice.requestAccess(for: .video) { status in
            if status {
                DispatchQueue.main.async {
                    do {
                        self.session.beginConfiguration()
                        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                            completion(.failure(NSError(domain: "Camera Device Error", code: -1, userInfo: nil)))
                            return
                        }
                        guard let cameraInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
                            completion(.failure(NSError(domain: "Camera Input Error", code: -1, userInfo: nil)))
                            return
                        }
                        if self.session.canAddInput(cameraInput) {
                            self.session.addInput(cameraInput)
                        }
                        
                        let videoOutput = AVCaptureVideoDataOutput()
                        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                        if self.session.canAddOutput(videoOutput) {
                            self.session.addOutput(videoOutput)
                        }
                        
                        self.session.commitConfiguration()
                        completion(.success(()))
                    } catch {
                        completion(.failure(error))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.alert = true
                }
            }
        }
    }

    // Procesa cada fotograma capturado y usa el modelo CoreML para hacer predicciones
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let visionModel = visionModel else { return }
        let request = VNCoreMLRequest(model: visionModel) { (request, error) in
            DispatchQueue.main.async {
                guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
                self.drawBoundingBoxes(for: results)
            }
        }
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .left)

        try? handler.perform([request])
    }

    // Dibuja bounding boxes basados en los resultados de detección
    private func drawBoundingBoxes(for observations: [VNRecognizedObjectObservation]) {
        detectionLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        for observation in observations {
            let box = observation.boundingBox
            let boundingBox = CALayer()
            boundingBox.frame = CGRect(
                x: box.minX * detectionLayer.bounds.width,
                y: (1 - box.maxY) * detectionLayer.bounds.height,
                width: box.width * detectionLayer.bounds.width,
                height: box.height * detectionLayer.bounds.height
            )
            boundingBox.borderColor = UIColor.red.cgColor
            boundingBox.borderWidth = 2
            detectionLayer.addSublayer(boundingBox)
        }
    }
}

// Extiende `CameraManager` para que sea delegado de AVCaptureVideoDataOutput
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer)
    }
}

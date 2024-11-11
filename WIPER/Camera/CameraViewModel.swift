import AVFoundation
import Photos
import SwiftUI
import Vision

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureDepthDataOutputDelegate {
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewUrl: URL?
    @Published var showSaveDialog: Bool = false
    @Published var detections: [CGRect] = [] // Almacena las bounding boxes de los objetos detectados
    @Published var detectedDistances: [Double] = []
    
    private var model: VNCoreMLModel
    private var depthOutput = AVCaptureDepthDataOutput()
    
    override init() {
        guard let model = try? VNCoreMLModel(for: demo().model) else {
            fatalError("No se pudo cargar el modelo ML")
        }
        self.model = model
        super.init()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error al finalizar la grabación: \(error.localizedDescription)")
            self.isRecording = false // Actualiza el estado correctamente
            return
        }
        
        print("Video guardado en: \(outputFileURL)")
        self.recordedURLs.append(outputFileURL)
        self.previewUrl = outputFileURL
        self.showSaveDialog = true
        self.isRecording = false // Actualiza el estado correctamente
    }
    
    
    
    func saveVideoToGallery(url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("Video guardado en la galería")
                        } else {
                            print("Error al guardar el video en la galería: \(String(describing: error))")
                        }
                    }
                }
            case .denied, .restricted:
                print("Permiso de acceso a la galería denegado")
            case .notDetermined:
                print("Permiso de acceso a la galería no determinado")
            @unknown default:
                print("Estado de permiso de galería desconocido")
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.handleDetections(results)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func handleDetections(_ results: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            self.detections = results.map { observation in
                // Convertir las coordenadas de la bounding box
                let boundingBox = observation.boundingBox
                let viewWidth = UIScreen.main.bounds.width
                let viewHeight = UIScreen.main.bounds.height
                
                let x = boundingBox.minX * viewWidth
                let y = (1 - boundingBox.maxY) * viewHeight
                let width = boundingBox.width * viewWidth
                let height = boundingBox.height * viewHeight
                
                return CGRect(x: x, y: y, width: width, height: height)
            }
        }
    }
    
    func addDepthOutput(to session: AVCaptureSession){
        if session.canAddOutput(depthOutput) {
            session.canAddOutput(depthOutput)
            depthOutput.isFilteringEnabled = true
            depthOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthQueue"))
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput depthData: AVDepthData, from connection: AVCaptureConnection) {
        let depthMap = depthData.depthDataMap
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) } // Ensure the buffer is unlocked even if an error occurs
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap)?.assumingMemoryBound(to: Float32.self) else {
            print("Error: Could not access base address of depth map")
            return
        }

        DispatchQueue.main.async {
            self.detectedDistances = self.detections.map { detection in
                // Calculate the center point of the detection bounding box
                let centerX = Int((detection.midX / UIScreen.main.bounds.width) * CGFloat(width))
                let centerY = Int((detection.midY / UIScreen.main.bounds.height) * CGFloat(height))

                // Ensure coordinates are within bounds
                guard centerX >= 0, centerX < width, centerY >= 0, centerY < height else {
                    print("Warning: Coordinates out of bounds")
                    return Double.nan // Return NaN for out-of-bounds cases
                }

                let depthIndex = centerY * width + centerX
                let depthValue = Double(baseAddress[depthIndex])

                // Print depth value for debugging
                print("Depth for detected object at (\(centerX), \(centerY)): \(depthValue) meters")

                return depthValue
            }

            // Print all detected distances for verification
            print("Detected distances: \(self.detectedDistances)")

            // Pass distances to the alarm system
            for distance in self.detectedDistances where !distance.isNaN {
                checkAndTriggerAlarm(
                    objectDetected: true,
                    objectDistance: distance,
                    locationManager: LocationManager(), // Assumes LocationManager is set up properly
                    visibility: 90 // Replace with actual visibility data
                )
            }
        }
    }

}

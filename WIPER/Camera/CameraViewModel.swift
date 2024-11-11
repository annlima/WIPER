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
    @ObservedObject var locationManager = LocationManager()
    var visibility: Double = 100.0 // Puedes obtener el valor real utilizando WeatherKit
       
    
    override init() {
        guard let model = try? VNCoreMLModel(for: yolov5s().model) else {
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
            self.detections = results.compactMap { observation in
                guard let label = observation.labels.first?.identifier,
                      ["bus", "train", "car", "truck", "motorcycle", "bicycle", "person", "dog"].contains(label) else {
                    return nil
                }
                
                // Convert bounding box to CGRect
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
        let depthPixelBuffer = depthData.depthDataMap
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(depthPixelBuffer) else { return }

        let floatBuffer = unsafeBitCast(baseAddress, to: UnsafeMutablePointer<Float32>.self)

        DispatchQueue.main.async {
            // Primero, calcula 'detectedDistances'
            self.detectedDistances = self.detections.map { detection in
                // Mapear coordenadas de detección al mapa de profundidad
                let normalizedX = detection.midX / UIScreen.main.bounds.width
                let normalizedY = detection.midY / UIScreen.main.bounds.height
                
                let pixelX = Int(normalizedX * CGFloat(width))
                let pixelY = Int(normalizedY * CGFloat(height))
                
                guard pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height else {
                    return Double.nan
                }
                
                let index = pixelY * width + pixelX
                let depth = Double(floatBuffer[index])
                
                return depth
            }
            
            // Ahora que 'detectedDistances' ha sido calculado, puedes iterar sobre él
            for (index, distance) in self.detectedDistances.enumerated() where !distance.isNaN {
                let objectDetected = true
                checkAndTriggerAlarm(
                    objectDetected: objectDetected,
                    objectDistance: distance,
                    locationManager: self.locationManager,
                    visibility: self.visibility
                )
            }
        }
    }
}

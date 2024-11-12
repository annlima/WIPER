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
    @Published var isTestMode: Bool = true
    
    private var model: VNCoreMLModel
    private var depthOutput = AVCaptureDepthDataOutput()
    @ObservedObject var locationManager = LocationManager()
    var visibility: Double = 100.0 // Puedes obtener el valor real utilizando WeatherKit
    
    private let realObjectHeights: [String: CGFloat] = [
           "person": 1.7, // average human height in meters
           "bus": 3.0,    // approximate height of a bus
           "car": 1.5,    // average car height
           "dog": 0.5,    // average dog height
           "bicycle": 1.0, // average bicycle height
           "truck": 3.0
    ]
    
    func calculateDistance(for detection: CGRect, objectLabel: String) -> Double? {
        // Retrieve the focal length in millimeters from device data
        let focalLengthInMM = DeviceManager.shared.focalLength
        if focalLengthInMM == 0.0 {
            print("Warning: Focal length is zero. Skipping distance calculation for \(objectLabel).")
            return nil
        }
        
        // Real-world object heights (in meters)
        guard let realObjectHeight = realObjectHeights[objectLabel] else {
            print("Real object height for \(objectLabel) not found.")
            return nil
        }
        
        // Detected object height in pixels
        let imageObjectHeightPixels = detection.height
        guard imageObjectHeightPixels > 0 else {
            print("Image object height is zero.")
            return nil
        }
        
        // Ensure focal length is in pixels
        let sensorHeightInMM = 7.0     // Approximate sensor height (adjust as per actual model)
        let sensorHeightInPixels = 3024.0  // Updated value for typical iPhone sensor resolution
        
        // Convert focal length to pixels using sensor data
        let focalLengthInPixels = (focalLengthInMM / sensorHeightInMM) * sensorHeightInPixels
        
        // Calculate the distance in meters
        let distance = (realObjectHeight * focalLengthInPixels) / Double(imageObjectHeightPixels)
        
        // Adjust distance calculation for better accuracy
        let adjustedDistance = distance / 10.0
        
        print("Calculated distance for \(objectLabel): \(adjustedDistance) meters.")
        return adjustedDistance
    }



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

                let detectionRect = CGRect(x: x, y: y, width: width, height: height)
                                
                // Calculate distance
                if let distance = self.calculateDistance(for: detectionRect, objectLabel: label) {
                    self.detectedDistances.append(distance)
                    //print("Detected \(label) at distance: \(distance) meters")
                    
                    // Trigger alarm if needed
                    checkAndTriggerAlarm(
                        objectDetected: true,
                                        objectDistance: distance,
                                        locationManager: self.locationManager,
                                        visibility: self.visibility
                                    )
                    
                } else {
                    print("Failed to calculate distance for \(label)")
                }

                    return detectionRect
                                
              
            }
        }
    }
    
    func addDepthOutput(to session: AVCaptureSession) {
        if session.canAddOutput(depthOutput) {
            session.addOutput(depthOutput)
            depthOutput.isFilteringEnabled = true
            depthOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthQueue"))
            print("Depth output successfully added to session.")
        } else {
            print("Failed to add depth output to session.")
        }
    }


    func simulateDetections() {
        // Simula una detección en el centro de la pantalla
        let simulatedDetection = CGRect(x: UIScreen.main.bounds.width / 2 - 50, y: UIScreen.main.bounds.height / 2 - 50, width: 100, height: 100)
        self.detections = [simulatedDetection]
        
        // Simula una distancia al objeto
        self.detectedDistances = [30.0] // Por ejemplo, 30 metros
    }

    
    func captureOutput(_ output: AVCaptureOutput, didOutput depthData: AVDepthData, from connection: AVCaptureConnection) {
        print("Depth data output received")
        let depthPixelBuffer = depthData.depthDataMap
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthPixelBuffer) else {
            print("Failed to get base address of depth data map.")
            return
        }
        
        let floatBuffer = unsafeBitCast(baseAddress, to: UnsafeMutablePointer<Float32>.self)
        print("Depth map width: \(width), height: \(height)")

        DispatchQueue.main.async {
            self.detectedDistances = self.detections.map { detection in
                let normalizedX = detection.midX / UIScreen.main.bounds.width
                let normalizedY = detection.midY / UIScreen.main.bounds.height
                let pixelX = Int(normalizedX * CGFloat(width))
                let pixelY = Int(normalizedY * CGFloat(height))
                
                guard pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height else {
                    return Double.nan
                }
                
                let index = pixelY * width + pixelX
                let depth = Double(floatBuffer[index])
                print("Depth at (\(pixelX), \(pixelY)): \(depth) meters")
                return depth
            }
            
            // Check alarm logic for each detected distance
            for (index, distance) in self.detectedDistances.enumerated() where !distance.isNaN {
                checkAndTriggerAlarm(
                    objectDetected: true,
                    objectDistance: distance,
                    locationManager: self.locationManager,
                    visibility: self.visibility
                )
                
            }
        }
    }


}

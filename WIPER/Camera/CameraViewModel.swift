import AVFoundation
import Photos
import SwiftUI
import Vision
import WeatherKit
import CoreLocation
import Combine

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureDepthDataOutputDelegate {
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewUrl: URL?
    @Published var showSaveDialog: Bool = false
    @Published var detections: [CGRect] = []
    @Published var detectedDistances: [Double] = []
    private var model: VNCoreMLModel
    private var imageEnhancer = ImageEnhancer()
    @Published var currentWeatherCond: String?
    @ObservedObject var locationManager = LocationManager()
    private let weatherService = WeatherService.shared
    private var cancellables = Set<AnyCancellable>()
    @Published var isTestMode: Bool = true
    private var depthOutput = AVCaptureDepthDataOutput()
    var visibility: Double = 100.0
        
    private var frameCount: Int = 0
    private(set) var frameProcessingInterval: Int = 3
    
    private var lastDetectionTime: Date = Date()
    private var minTimeBetweenDetections: TimeInterval = 0.1
        
    private let realObjectHeights: [String: CGFloat] = [
        "auto rickshaw": 1.5,
        "bicycle": 1.0,
        "bus": 3.2,
        "car": 1.5,
        "motorbike": 1.2,
        "pedestrian": 1.7,
        "person": 1.7,
        "truck": 3.5
    ]
    
    func calculateDistance(for detection: CGRect, objectLabel: String) -> Double? {
        
        let focalLengthInMM = DeviceManager.shared.focalLength
        if focalLengthInMM == 0.0 {
            print("Warning: Focal length is zero. Skipping distance calculation for \(objectLabel).")
            return nil
        }
        
        guard let realObjectHeight = realObjectHeights[objectLabel] else {
            print("Real object height for \(objectLabel) not found.")
            return nil
        }
        
        let imageObjectHeightPixels = detection.height
        guard imageObjectHeightPixels > 0 else {
            print("Image object height is zero.")
            return nil
        }
        
        let sensorHeightInMM = 7.0
        let sensorHeightInPixels = 3024.0
        
        let focalLengthInPixels = (focalLengthInMM / sensorHeightInMM) * sensorHeightInPixels
        
        let distance = (realObjectHeight * focalLengthInPixels) / Double(imageObjectHeightPixels)
        
        let adjustedDistance = distance / 10.0
        
        print("Calculated distance for \(objectLabel): \(adjustedDistance) meters.")
        return adjustedDistance
    }

    func setFrameProcessingInterval(_ interval: Int) {
        self.frameProcessingInterval = max(1, interval)
        print("Configurando intervalo de procesamiento: cada \(frameProcessingInterval) fotogramas")
    }

    override init() {
        guard let model = try? VNCoreMLModel(for: best_yolov5stl().model) else {
            fatalError("No se pudo cargar el modelo ML")
        }
        self.model = model
        super.init()
        observeLocationUpdates()
        adjustProcessingForDevice()
    }
    
    private func adjustProcessingForDevice() {
            let deviceModel = DeviceManager.shared.deviceModel
            
            if deviceModel.contains("iPhone XR") || deviceModel.contains("iPhone 11") || deviceModel.contains("iPhone SE") {
                setFrameProcessingInterval(6)
                minTimeBetweenDetections = 0.2
            } else if deviceModel.contains("iPhone 12") || deviceModel.contains("iPhone 13") {
                setFrameProcessingInterval(4)
                minTimeBetweenDetections = 0.15
            } else if deviceModel.contains("iPhone 14") || deviceModel.contains("iPhone 15") {
                setFrameProcessingInterval(2)
                minTimeBetweenDetections = 0.1
            } else {
                setFrameProcessingInterval(5)
                minTimeBetweenDetections = 0.15
            }
        }
    
    private func observeLocationUpdates() {
        locationManager.$lastLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.fetchCurrentWeather(for: location)
            }
            .store(in: &cancellables)
    }
    
    private func fetchCurrentWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                DispatchQueue.main.async {
                    
                    self.currentWeatherCond = weather.currentWeather.condition.description
                    print("Current Condition: \(self.currentWeatherCond ?? "Unknown")")
                }
            } catch {
                print("Failed to fetch weather data: \(error.localizedDescription)")
            }
        }
    }

    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error al finalizar la grabación: \(error.localizedDescription)")
            self.isRecording = false
            return
        }
        
        print("Video guardado en: \(outputFileURL)")
        self.recordedURLs.append(outputFileURL)
        self.previewUrl = outputFileURL
        self.showSaveDialog = true
        self.isRecording = false
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
        
        frameCount += 1
        if frameCount % frameProcessingInterval != 0 {
            return
        }
        
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastDetectionTime) < minTimeBetweenDetections {
            return
        }
        lastDetectionTime = currentTime
        
        let deviceModel = DeviceManager.shared.deviceModel
        let confidenceThreshold: Float = (deviceModel.contains("iPhone XR") || deviceModel.contains("iPhone 11")) ? 0.5 : 0.3
        
        let request = VNCoreMLRequest(model: model) { [weak self] (request, error) in
            guard let self = self else { return }
            
            if let results = request.results as? [VNRecognizedObjectObservation] {
                
                let filteredResults = results.filter { observation in
                    
                    guard let firstLabel = observation.labels.first else { return false }
                    return firstLabel.confidence >= confidenceThreshold
                }
                
                self.handleDetections(filteredResults)
            }
        }

        request.imageCropAndScaleOption = .scaleFill

        if let condition = currentWeatherCond, !condition.isEmpty {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let uiImage = UIImage(ciImage: ciImage)
            
            let preprocessedImage: UIImage?
            switch condition.lowercased() {
            case "sunny":
                preprocessedImage = imageEnhancer.applyCLAHE(to: uiImage)
            case "fog":
                preprocessedImage = imageEnhancer.applyDehaze(to: uiImage)
            case "rain":
                preprocessedImage = imageEnhancer.applyRainRemoval(to: uiImage)
            case "night":
                preprocessedImage = imageEnhancer.applyNightEnhancement(to: uiImage)
            default:
                preprocessedImage = uiImage
            }
            
            guard let finalImage = preprocessedImage, let cgImage = finalImage.cgImage else {
                print("Error: No se pudo obtener cgImage de la imagen preprocesada")
                return
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        } else {
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }

    

    private func handleDetections(_ results: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            self.detections = results.compactMap { observation in
                guard let label = observation.labels.first?.identifier,
                      ["bus", "train", "car", "truck", "motorcycle", "bicycle", "person", "dog"].contains(label) else {
                    return nil
                }
                
                let boundingBox = observation.boundingBox
                let viewWidth = UIScreen.main.bounds.width
                let viewHeight = UIScreen.main.bounds.height

                let x = boundingBox.minX * viewWidth
                let y = (1 - boundingBox.maxY) * viewHeight
                let width = boundingBox.width * viewWidth
                let height = boundingBox.height * viewHeight

                let detectionRect = CGRect(x: x, y: y, width: width, height: height)
                                
                
                if let distance = self.calculateDistance(for: detectionRect, objectLabel: label) {
                    self.detectedDistances.append(distance)
                    
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

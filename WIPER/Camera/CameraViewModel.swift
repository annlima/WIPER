//
//  CameraViewModel.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//

import AVFoundation
import Photos
import SwiftUI
import Vision
import WeatherKit
import CoreLocation
import Combine
import MapKit

struct SimpleMovingAverage {
    private var values: [Double] = []
    private let windowSize: Int
    private let nonFiniteReplacement: Double = 150.0

    init(windowSize: Int) {
        self.windowSize = max(1, windowSize)
    }

    mutating func add(value: Double) -> Double {
        let valueToAdd: Double
        if value.isFinite {
            valueToAdd = value
        } else {
            valueToAdd = nonFiniteReplacement
        }
        
        values.append(valueToAdd)
        if values.count > windowSize {
            values.removeFirst()
        }
        if values.isEmpty { return nonFiniteReplacement }
        
        return values.reduce(0, +) / Double(values.count)
    }

    mutating func reset() {
        values.removeAll()
    }
    
    func hasEnoughData() -> Bool {
        return values.count >= windowSize
    }
}

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureDepthDataOutputDelegate {
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewUrl: URL?
    @Published var showSaveDialog: Bool = false
    @Published var detections: [CGRect] = []
    @Published var detectedDistances: [Double] = []
    @Published var currentWeatherCond: String?
    @Published var isTestMode: Bool = false
    
    @Published var currentInstruction: String = "Iniciando navegación..."
    @Published var distanceToNextManeuver: CLLocationDistance = .infinity
    @Published private(set) var currentRoute: MKRoute?
    @Published private(set) var currentRouteStepIndex: Int = 0
    
    let CALIBRATED_FOCAL_LENGTH_PIXELS: CGFloat = 1685.38 
    private let ciContext = CIContext()
    private var model: VNCoreMLModel
    private var imageEnhancer = ImageEnhancer()
    @ObservedObject var locationManager = LocationManager()
    private let weatherService = WeatherService.shared
    private var cancellables = Set<AnyCancellable>()
    private var depthOutput = AVCaptureDepthDataOutput()
    
    var visibility: Double = 500.0
    
    private var frameCount: Int = 0
    private(set) var frameProcessingInterval: Int
    private var lastDetectionTime: Date = Date()
    private var minTimeBetweenDetections: TimeInterval

    private let realObjectHeights: [String: CGFloat] = [
        "auto rickshaw": 1.5, "bicycle": 1.0, "bus": 3.2, "car": 1.45,
        "motorbike": 1.2, "pedestrian": 1.7, "person": 1.7, "truck": 3.5
    ]
    
    @Published private var isProximityAlarmCurrentlyActive: Bool = false
    private var distanceSmoother = SimpleMovingAverage(windowSize: 3)

    init(route: MKRoute? = nil) {
        guard let loadedModel = try? VNCoreMLModel(for: best_yolov5s().model) else {
            fatalError("No se pudo cargar el modelo ML")
        }
        self.model = loadedModel
        self.currentRoute = route
        
        let initialDeviceModel = DeviceManager.shared.deviceModel
        if initialDeviceModel.contains("iPhone XR") || initialDeviceModel.contains("iPhone 11") || initialDeviceModel.contains("iPhone SE") {
            self.frameProcessingInterval = 5; self.minTimeBetweenDetections = 0.18
        } else if initialDeviceModel.contains("iPhone 12") || initialDeviceModel.contains("iPhone 13") {
            self.frameProcessingInterval = 4; self.minTimeBetweenDetections = 0.15
        } else {
            self.frameProcessingInterval = 3; self.minTimeBetweenDetections = 0.1
        }
        
        super.init()
        
        print("WIPER LOG: ViewModel init. CALIBRATED_F_PIXELS=\(CALIBRATED_FOCAL_LENGTH_PIXELS). IntervaloFrames=\(frameProcessingInterval), MinTiempoEntreDetecciones=\(minTimeBetweenDetections)")
        
        observeLocationUpdates()
        
        if let initialRoute = route, !initialRoute.steps.isEmpty {
            updateNavigationInstruction(stepIndex: 0)
        } else {
            self.currentInstruction = ""; self.distanceToNextManeuver = .infinity
        }
    }

    private func observeLocationUpdates() {
        locationManager.$lastLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self else { return }
                self.fetchCurrentWeather(for: location)
                self.updateNavigationProgress(userLocation: location)
            }
            .store(in: &cancellables)
    }
    
    private func updateNavigationProgress(userLocation: CLLocation) {
        guard let route = currentRoute, !route.steps.isEmpty else {
            DispatchQueue.main.async {
                if self.currentRoute == nil { self.currentInstruction = "" }
                else { self.currentInstruction = "Ruta no válida o sin pasos." }
                self.distanceToNextManeuver = .infinity
            }
            return
        }
        if currentRouteStepIndex >= route.steps.count {
            DispatchQueue.main.async {
                if self.currentInstruction != "Has llegado a tu destino." {
                     self.currentInstruction = "Has llegado a tu destino."; self.distanceToNextManeuver = 0
                }
            }
            return
        }
        let currentStep = route.steps[currentRouteStepIndex]
        var distanceToCurrentStepEnd: CLLocationDistance = .infinity
        if currentStep.polyline.pointCount > 0 {
            let endMapPoint = currentStep.polyline.points()[currentStep.polyline.pointCount - 1]
            let endStepLocation = CLLocation(latitude: endMapPoint.coordinate.latitude, longitude: endMapPoint.coordinate.longitude)
            distanceToCurrentStepEnd = userLocation.distance(from: endStepLocation)
        }
        DispatchQueue.main.async { self.distanceToNextManeuver = distanceToCurrentStepEnd }
        let stepCompletionThreshold: CLLocationDistance = 30.0
        if distanceToCurrentStepEnd < stepCompletionThreshold {
            if currentRouteStepIndex < route.steps.count - 1 {
                DispatchQueue.main.async { self.advanceToNextStep() }
            } else {
                DispatchQueue.main.async {
                    self.currentInstruction = "Has llegado a tu destino."; self.distanceToNextManeuver = 0
                    if self.currentRouteStepIndex == route.steps.count - 1 { self.currentRouteStepIndex += 1 }
                }
            }
        }
    }

    private func advanceToNextStep() {
        guard let route = currentRoute, currentRouteStepIndex + 1 < route.steps.count else { return }
        currentRouteStepIndex += 1
        updateNavigationInstruction(stepIndex: currentRouteStepIndex)
    }

    private func updateNavigationInstruction(stepIndex: Int) {
        guard let route = currentRoute else {
            DispatchQueue.main.async { self.currentInstruction = "" }; return
        }
        guard stepIndex < route.steps.count else {
            if !route.steps.isEmpty && stepIndex >= route.steps.count {
                 DispatchQueue.main.async { self.currentInstruction = "Has llegado a tu destino."; self.distanceToNextManeuver = 0 }
            } else if route.steps.isEmpty {
                DispatchQueue.main.async { self.currentInstruction = "Ruta no válida."; self.distanceToNextManeuver = .infinity }
            }
            return
        }
        let step = route.steps[stepIndex]
        DispatchQueue.main.async {
             self.currentInstruction = step.instructions.isEmpty ? "Continúa recto" : step.instructions
        }
    }
    
    private func fetchCurrentWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                let conditionDescription = weather.currentWeather.condition.description
                let currentVisibilityMeters = weather.currentWeather.visibility.converted(to: .meters).value
                
                DispatchQueue.main.async {
                    self.currentWeatherCond = conditionDescription
                    self.visibility = currentVisibilityMeters
                }
            } catch {
                 DispatchQueue.main.async {
                    if self.currentWeatherCond != "No disponible (error WeatherKit)" {
                        self.currentWeatherCond = "No disponible (error WeatherKit)"
                        print("WIPER LOG: Error WeatherKit. Usando visibilidad actual/default: \(self.visibility)m")
                    }
                 }
            }
        }
    }

    func calculateDistance(for detection: CGRect, objectLabel: String, currentFramePixelHeight: CGFloat) -> Double? {
        guard let realObjectHeight_m = realObjectHeights[objectLabel] else { return nil }
        let imageObjectHeight_px = detection.height
        
        let estimatedDistanceWithCurrentF = (realObjectHeight_m * CALIBRATED_FOCAL_LENGTH_PIXELS) / imageObjectHeight_px
        print("LOG CALIBRACIÓN ('\(objectLabel)'): H_real=\(realObjectHeight_m)m, h_px=\(String(format: "%.2f", imageObjectHeight_px))px -> d_est=\(String(format: "%.2f",estimatedDistanceWithCurrentF))m (usando f_pixels=\(CALIBRATED_FOCAL_LENGTH_PIXELS))")

        guard imageObjectHeight_px > CGFloat.ulpOfOne else { return nil }
        
        if estimatedDistanceWithCurrentF.isFinite && estimatedDistanceWithCurrentF > 0.1 && estimatedDistanceWithCurrentF < 150 {
            return Double(estimatedDistanceWithCurrentF)
        }
        return nil
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            frameCount += 1; if frameCount % frameProcessingInterval != 0 { return }
            let currentTime = Date(); if currentTime.timeIntervalSince(lastDetectionTime) < minTimeBetweenDetections { return }; lastDetectionTime = currentTime
            
            let currentFrameActualHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
            let confidenceThreshold: Float = 0.40

            let capturedWeatherCond = self.currentWeatherCond

            let request = VNCoreMLRequest(model: model) { [weak self] (request, error) in
                guard let self = self else { return }
                if let results = request.results as? [VNRecognizedObjectObservation] {
                    let filteredResults = results.filter { obs in
                        guard let firstLabel = obs.labels.first else { return false }
                        return firstLabel.confidence >= confidenceThreshold && self.realObjectHeights[firstLabel.identifier] != nil
                    }
                    self.handleDetections(filteredResults, framePixelHeight: currentFrameActualHeight)
                } else if let e = error { print("WIPER LOG ML Error: \(e.localizedDescription)") }
            }
            request.imageCropAndScaleOption = .scaleFill

            var imageToProcessCG: CGImage?
            let ciImageInput = CIImage(cvPixelBuffer: pixelBuffer)

            if let condition = capturedWeatherCond?.lowercased(), !condition.contains("desconocido"), !condition.contains("no disponible") {
                let uiImageInput = UIImage(ciImage: ciImageInput)
                var processedUIImage: UIImage? = uiImageInput
                if condition.contains("fog") { processedUIImage = imageEnhancer.applyDehaze(to: uiImageInput) }
                else if condition.contains("rain") { processedUIImage = imageEnhancer.applyRainRemoval(to: uiImageInput) }
                else if condition.contains("night") ||
                         ((condition.contains("clear") || condition.contains("cloudy")) &&
                          Calendar.current.component(.hour, from: Date()) > 19 &&
                          Calendar.current.component(.hour, from: Date()) < 6) {
                    processedUIImage = imageEnhancer.applyNightEnhancement(to: uiImageInput)
                }
                imageToProcessCG = processedUIImage?.cgImage
            }
            
            if imageToProcessCG == nil {
                imageToProcessCG = self.ciContext.createCGImage(ciImageInput, from: ciImageInput.extent)
            }
            
            guard let finalCGImage = imageToProcessCG else {
                print("WIPER LOG: No se pudo obtener finalCGImage para ML.")
                return
            }
            
            do {
                try VNImageRequestHandler(cgImage: finalCGImage, options: [:]).perform([request])
            } catch {
                print("WIPER LOG: Error al realizar VNImageRequestHandler.perform: \(error.localizedDescription)")
            }
        }

        private func handleDetections(_ results: [VNRecognizedObjectObservation], framePixelHeight: CGFloat) {
            var currentFrameDetectionRects: [CGRect] = []
            var closestRelevantObjectInfo: (rawDistance: Double, label: String, rect: CGRect)? = nil
            let viewWidth = UIScreen.main.bounds.width; let viewHeight = UIScreen.main.bounds.height
            let roiRect = CGRect(x: viewWidth * 0.20, y: viewHeight * 0.50, width: viewWidth * 0.60, height: viewHeight * 0.50)

            for observation in results {
                guard let label = observation.labels.first?.identifier,
                      ["bus", "car", "truck", "motorbike", "bicycle", "person", "pedestrian"].contains(label) else { continue }
                
                let boundingBox = observation.boundingBox
                let uiRect = CGRect(x: boundingBox.minX * viewWidth, y: (1 - boundingBox.maxY) * viewHeight, width: boundingBox.width * viewWidth, height: boundingBox.height * viewHeight)
                
                let objectBaseCenterInROI = roiRect.contains(CGPoint(x: uiRect.midX, y: uiRect.maxY ))
                // if !objectBaseCenterInROI && !(label == "person" || label == "pedestrian") { /* continue */ } // ROI Descomentar para activar
                currentFrameDetectionRects.append(uiRect)

                let detectionHeightInFramePixels = boundingBox.height * framePixelHeight
                let detectionForDistance = CGRect(x: 0, y: 0, width: 0, height: detectionHeightInFramePixels)

                if let rawDistance = calculateDistance(for: detectionForDistance, objectLabel: label, currentFramePixelHeight: framePixelHeight) {
                    if closestRelevantObjectInfo == nil || rawDistance < closestRelevantObjectInfo!.rawDistance {
                        closestRelevantObjectInfo = (rawDistance: rawDistance, label: label, rect: uiRect)
                    }
                }
            }
            
            let finalDetections = currentFrameDetectionRects
            var finalDistanceToShow: [Double] = []
            var alarmCheckParameters: (objectDistance: Double, visibility: Double)? = nil

            if var objectToProcess = closestRelevantObjectInfo {
                var distanceForAlarm = objectToProcess.rawDistance
                if objectToProcess.rawDistance.isFinite {
                     distanceForAlarm = self.distanceSmoother.add(value: objectToProcess.rawDistance)
                }
                finalDistanceToShow = [distanceForAlarm]
                alarmCheckParameters = (objectDistance: distanceForAlarm, visibility: self.visibility)
            } else {
                self.distanceSmoother.reset()
                // isProximityAlarmCurrentlyActive se manejará en main si no hay objetos
            }

            DispatchQueue.main.async {
                self.detections = finalDetections
                self.detectedDistances = finalDistanceToShow

                if let params = alarmCheckParameters {
                    self.checkAndTriggerAlarm(objectDetected: true, objectDistance: params.objectDistance, locationManager: self.locationManager, visibility: params.visibility)
                } else {
                    if self.isProximityAlarmCurrentlyActive {
                        self.isProximityAlarmCurrentlyActive = false
                    }
                }
            }
        }
        
    
    func checkAndTriggerAlarm(objectDetected: Bool, objectDistance: Double, locationManager: LocationManager, visibility: Double) {
        let actualVisibility = max(1.0, visibility)
        let speedKmh = locationManager.speed

        guard objectDetected, objectDistance.isFinite, objectDistance > 0 else {
            if isProximityAlarmCurrentlyActive {
                DispatchQueue.main.async { self.isProximityAlarmCurrentlyActive = false }
            }
            return
        }

        let alarmSystem = AlarmSystem(objectDetected: true, objectDistance: objectDistance, currentSpeed: speedKmh, visibility: actualVisibility)
        let roundedSpeed = Int((speedKmh / 10).rounded() * 10)
        let roadCondition = (actualVisibility < alarmSystem.visibilityThreshold) ? "wet" : "dry"
        
        guard let closestSpeedKey = alarmSystem.getClosestSpeedKey(forSpeed: roundedSpeed),
              let stoppingDist = alarmSystem.getStoppingDistance(forSpeed: closestSpeedKey, condition: roadCondition) else {
            return
        }

        let activationDistance = stoppingDist * 0.95
        let deactivationDistance = stoppingDist * 1.15
        var shouldEmitSoundNow = false

        if isProximityAlarmCurrentlyActive {
            if objectDistance > deactivationDistance || speedKmh < 15.0 {
                DispatchQueue.main.async { self.isProximityAlarmCurrentlyActive = false }
            } else if alarmSystem.shouldTriggerAlarm() {
                shouldEmitSoundNow = true
            }
        } else {
            if objectDistance <= activationDistance && alarmSystem.shouldTriggerAlarm() {
                DispatchQueue.main.async { self.isProximityAlarmCurrentlyActive = true }
                shouldEmitSoundNow = true
            }
        }
        
        if shouldEmitSoundNow {
             print(">>>> ALARMA SONANDO: DistObj: \(String(format: "%.1f", objectDistance))m (\(isProximityAlarmCurrentlyActive ? "ACTVA":"NVA")) Vel: \(String(format: "%.1f", speedKmh))km/h, Cond: \(roadCondition), DistFreno: \(String(format: "%.1f", stoppingDist))m <<<<")
            // configureAudioSessionForPlayback()
            AlarmManager.shared.emitAlarmSound()
        }
    }

    func addDepthOutput(to session: AVCaptureSession) -> Bool {
        guard depthOutput.delegate == nil else { return session.outputs.contains(depthOutput) }
        if session.canAddOutput(depthOutput) {
            session.addOutput(depthOutput); depthOutput.isFilteringEnabled = true
            depthOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthQueue"))
            if let connection = depthOutput.connection(with: .depthData) {
                connection.isEnabled = true
            } else { return false }
            return true
        }
        return false
    }
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {}
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            if let err = error { self.isRecording = false; return }
            self.recordedURLs.append(outputFileURL); self.previewUrl = outputFileURL
            self.isRecording = false; self.showSaveDialog = true
        }
    }
    func saveVideoToGallery(url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }) { _, _ in }
                }
            }
        }
    }
}

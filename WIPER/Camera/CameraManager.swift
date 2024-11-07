// CameraManager.swift
import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    var videoDataOutput = AVCaptureVideoDataOutput()
    var output = AVCaptureMovieFileOutput()
    @Published var isSessionRunning = false
    private var isConfigured = false
    
    func startRecording(cameraViewModel: CameraViewModel) {
        guard session.isRunning else {
            print("La sesión no está activa")
            return
        }
        
        if output.isRecording {
            print("Ya está grabando")
            return
        }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).mov")
        print("Intentando iniciar la grabación en: \(tempURL)")
        output.startRecording(to: tempURL, recordingDelegate: cameraViewModel)
        cameraViewModel.isRecording = true
        print("Iniciando grabación en: \(tempURL)")
    }
    
    
    func stopRecording(cameraViewModel: CameraViewModel) {
        guard output.isRecording else {
            print("No hay ninguna grabación en curso para detener.")
            return
        }
        
        output.stopRecording()
        cameraViewModel.isRecording = false
        print("Grabación detenida.")
    }
    
    func setUp(cameraViewModel: CameraViewModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isConfigured else {
            completion(.success(()))
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { status in
            if status {
                DispatchQueue.main.async {
                    do {
                        self.session.beginConfiguration()
                        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                              let cameraInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
                            completion(.failure(NSError(domain: "Camera Device Error", code: -1, userInfo: nil)))
                            return
                        }
                        
                        if self.session.canAddInput(cameraInput) {
                            self.session.addInput(cameraInput)
                        }
                        
                        // Configurar y agregar videoDataOutput si es necesario
                        self.videoDataOutput.setSampleBufferDelegate(cameraViewModel, queue: DispatchQueue(label: "videoQueue"))
                        if self.session.canAddOutput(self.videoDataOutput) {
                            self.session.addOutput(self.videoDataOutput)
                        } else {
                            print("No se pudo agregar 'videoDataOutput' a la sesión")
                        }
                        
                        if self.session.canAddOutput(self.output) {
                            self.session.addOutput(self.output)
                        } else {
                            print("No se pudo agregar 'output' a la sesión")
                        }
                        
                        self.session.commitConfiguration()
                        self.isConfigured = true
                        
                        // Iniciar la sesión en un hilo de fondo
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.session.startRunning()
                            
                            // Actualizar isSessionRunning en el hilo principal
                            DispatchQueue.main.async {
                                self.isSessionRunning = true
                                completion(.success(()))
                            }
                        }
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
}

import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    var videoDataOutput = AVCaptureVideoDataOutput()
    var output = AVCaptureMovieFileOutput() // Salida de video para grabación
    
    func setUp(cameraViewModel: CameraViewModel, completion: @escaping (Result<Void, Error>) -> Void) {
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

                        self.videoDataOutput.setSampleBufferDelegate(cameraViewModel, queue: DispatchQueue(label: "videoQueue"))
                        if self.session.canAddOutput(self.videoDataOutput) {
                            self.session.addOutput(self.videoDataOutput)
                        }
                        
                        if self.session.canAddOutput(self.output) {
                            self.session.addOutput(self.output)
                        }

                        self.session.commitConfiguration()
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.session.startRunning()
                        }
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
        output.startRecording(to: tempURL, recordingDelegate: cameraViewModel)
        cameraViewModel.isRecording = true
    }
    
    func stopRecording(cameraViewModel: CameraViewModel) {
        guard output.isRecording else {
            print("No hay ninguna grabación en curso")
            return
        }
        
        output.stopRecording()
        cameraViewModel.isRecording = false
    }
}

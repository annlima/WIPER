import AVFoundation
import SwiftUI


class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    var videoOutput = AVCaptureVideoDataOutput()

    // Set up the camera without audio
    func setUp(cameraViewModel: CameraViewModel, completion: @escaping (Result<Void, Error>) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { status in
            if status {
                do {
                    self.session.beginConfiguration()

                    // Configure the camera
                    guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                        completion(.failure(NSError(domain: "Camera Device Error", code: -1, userInfo: nil)))
                        return
                    }

                    guard let cameraInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
                        completion(.failure(NSError(domain: "Camera Input Error", code: -1, userInfo: nil)))
                        return
                    }

                    // Add camera input (without audio input)
                    if self.session.canAddInput(cameraInput) {
                        self.session.addInput(cameraInput)
                    }

                    // Set up video output
                    self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                    self.videoOutput.setSampleBufferDelegate(cameraViewModel, queue: DispatchQueue(label: "cameraFrameProcessingQueue"))
                                        if self.session.canAddOutput(self.videoOutput) {
                                            self.session.addOutput(self.videoOutput)
                                        }

                    self.session.commitConfiguration()
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            } else {
                DispatchQueue.main.async {
                    self.alert = true
                }
            }
        }
    }
}

//
//  CameraManager.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 22/09/24.
//

import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    
    // Configura la cámara y el micrófono
    func setUp(completion: @escaping (Result<Void, Error>) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { status in
            if status {
                DispatchQueue.main.async {
                    do {
                        self.session.beginConfiguration()
                        
                        // Configura la cámara
                        let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                        guard let cameraInput = try? AVCaptureDeviceInput(device: cameraDevice!) else {
                            completion(.failure(NSError(domain: "Camera Input Error", code: -1, userInfo: nil)))
                            return
                        }
                        
                        // Configura el micrófono
                        let audioDevice = AVCaptureDevice.default(for: .audio)
                        guard let audioInput = try? AVCaptureDeviceInput(device: audioDevice!) else {
                            completion(.failure(NSError(domain: "Audio Input Error", code: -1, userInfo: nil)))
                            return
                        }
                        
                        // Añade los inputs
                        if self.session.canAddInput(cameraInput) && self.session.canAddInput(audioInput) {
                            self.session.addInput(cameraInput)
                            self.session.addInput(audioInput)
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
}

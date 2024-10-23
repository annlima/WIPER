import AVFoundation
import Photos
import SwiftUI

class CameraViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var output = AVCaptureMovieFileOutput()
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewUrl: URL?
    @Published var showSaveDialog: Bool = false

    func startRecording(session: AVCaptureSession) {
        guard session.isRunning else {
            print("La sesión no está activa")
            return
        }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).mov")
        if !session.outputs.contains(output) {
            session.addOutput(output)
        }
        output.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        output.stopRecording()
        isRecording = false
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }

        print("Video saved at: \(outputFileURL)")
        self.recordedURLs.append(outputFileURL)
        self.previewUrl = outputFileURL
        self.showSaveDialog = true
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
                            print("Video saved to gallery")
                        } else {
                            print("Error saving video to gallery: \(String(describing: error))")
                        }
                    }
                }
            case .denied, .restricted:
                print("Gallery access permission denied")
            case .notDetermined:
                print("Gallery access permission not determined")
            @unknown default:
                print("Unknown gallery access status")
            }
        }
    }
}

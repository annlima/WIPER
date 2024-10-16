import AVFoundation
import Photos
import SwiftUI

class CameraViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var output = AVCaptureMovieFileOutput()
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewUrl: URL?
    @Published var showPreview: Bool = false
    @Published var showSaveDialog: Bool = false

    // Start Recording
    func startRecording(session: AVCaptureSession) {
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        if !session.outputs.contains(output) {  // Asegúrate de no añadir el output dos veces
            session.addOutput(output)
        }
        output.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        isRecording = true
    }

    // Stop Recording
    func stopRecording() {
        output.stopRecording()
        isRecording = false
    }

    // Delegate method to handle recording finished
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

    // Save video to gallery
    func saveVideoToGallery(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    if success {
                        print("Video saved to gallery")
                    } else {
                        print("Error saving video to gallery: \(String(describing: error))")
                    }
                }
            } else {
                print("Gallery access permission denied")
            }
        }
    }
}

import AVFoundation
import Photos
import Vision
import SwiftUI
import CoreML

class CameraViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var output = AVCaptureMovieFileOutput()
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewUrl: URL?
    @Published var showPreview: Bool = false
    @Published var showSaveDialog: Bool = false
    @Published var detectedObjects: [DetectedObject] = [] // Detected objects

    var yoloModel: VNCoreMLModel?


    // Start Recording
    func startRecording(session: AVCaptureSession) {
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        output.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        session.addOutput(output)
        isRecording = true
    }

    // Stop Recording
    func stopRecording() {
        output.stopRecording()
        isRecording = false
    }

    // Process each frame from the camera
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Run YOLO on the pixel buffer
        detectObjects(in: pixelBuffer)
    }

    // Perform object detection using YOLO
    func detectObjects(in pixelBuffer: CVPixelBuffer) {
        guard let yoloModel = yoloModel else { return }

        let request = VNCoreMLRequest(model: yoloModel) { [weak self] request, error in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                DispatchQueue.main.async {
                    // Map the results to your DetectedObject model and update the UI
                    self?.detectedObjects = results.map {
                        DetectedObject(identifier: $0.labels.first?.identifier ?? "",
                                       confidence: $0.confidence,
                                       boundingBox: $0.boundingBox)
                    }
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform detection: \(error.localizedDescription)")
        }
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

// Model for detected objects
struct DetectedObject: Identifiable {
    let id = UUID()
    let identifier: String
    let confidence: VNConfidence
    let boundingBox: CGRect
}

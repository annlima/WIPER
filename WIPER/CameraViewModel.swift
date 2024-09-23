//
//  CameraViewModel.swift
//  CameraWiper
//
//  Created by Andrea Lima Blanca on 04/06/23.
//

import AVFoundation
import SwiftUI

class CameraViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var output = AVCaptureMovieFileOutput()
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewUrl: URL?
    @Published var showPreview: Bool = false
    @Published var recordedDuration: CGFloat = 0
    @Published var maxDuration: CGFloat = 3600

    // Inicia la grabación
    func startRecording(session: AVCaptureSession) {
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        output.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        session.addOutput(output) // Añade el output a la sesión
        isRecording = true
    }
    
    // Detiene la grabación
    func stopRecording() {
        output.stopRecording()
        isRecording = false
    }
    
    // Delegate para capturar el evento de finalización de grabación
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        print("Video guardado en: \(outputFileURL)")
        self.recordedURLs.append(outputFileURL)
        if self.recordedURLs.count == 1 {
            self.previewUrl = outputFileURL
        } else {
            let assets = recordedURLs.compactMap { AVURLAsset(url: $0) }
            mergeVideos(assets: assets) { exporter in
                exporter.exportAsynchronously {
                    if exporter.status == .failed {
                        print(exporter.error!)
                    } else if let finalURL = exporter.outputURL {
                        DispatchQueue.main.async {
                            self.previewUrl = finalURL
                        }
                    }
                }
            }
        }
    }
    
    // Fusión de videos
    func mergeVideos(assets: [AVURLAsset], completion: @escaping (_ exporter: AVAssetExportSession) -> ()) {
        let composition = AVMutableComposition()
        var lastTime: CMTime = .zero
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        
        for asset in assets {
            do {
                try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: lastTime)
                if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
                    try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioAssetTrack, at: lastTime)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            lastTime = CMTimeAdd(lastTime, asset.duration)
        }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "MergedVideo-\(Date()).mp4")
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        completion(exporter)
    }
}

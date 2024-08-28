//
//  videoHelper.swift
//  JoinVideo
//
//  Created by Saboor on 29/08/2024.
//

import AVFoundation


func swapAudioAndMergeVideos(video1URL: URL, video2URL: URL, completion: @escaping (URL?) -> Void) {
    let composition = AVMutableComposition()
    
    let video1Asset = AVURLAsset(url: video1URL)
    let video2Asset = AVURLAsset(url: video2URL)
    
    guard let video1Track = video1Asset.tracks(withMediaType: .video).first,
          let audio2Track = video2Asset.tracks(withMediaType: .audio).first else {
        print("Failed to find video or audio tracks")
        completion(nil)
        return
    }
    
    let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    do {
        try videoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: video1Asset.duration), of: video1Track, at: .zero)
        try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: video2Asset.duration), of: audio2Track, at: .zero)
        
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("mergedVideo.mov")
        
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mov
        
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    DispatchQueue.main.async {
                        completion(outputURL)
                    }
                } else {
                    print("Output file does not exist at path: \(outputURL.path)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            case .failed:
                print("Export failed: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
            case .cancelled:
                print("Export cancelled")
                DispatchQueue.main.async {
                    completion(nil)
                }
            default:
                print("Export status: \(String(describing: exportSession?.status))")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    } catch {
        print("Error processing videos: \(error)")
        completion(nil)
    }
}

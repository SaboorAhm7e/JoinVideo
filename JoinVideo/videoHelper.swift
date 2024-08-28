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
          let audio1Track = video1Asset.tracks(withMediaType: .audio).first,
          let video2Track = video2Asset.tracks(withMediaType: .video).first,
          let audio2Track = video2Asset.tracks(withMediaType: .audio).first else {
        print("Failed to find video or audio tracks")
        completion(nil)
        return
    }
    
    // Create video and audio tracks for the composition
    let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    let audioTrack2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    do {
        let video1Duration = video1Asset.duration
        let video2Duration = video2Asset.duration
        
        // Insert video1 with audio from video2
        try videoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: video1Duration), of: video1Track, at: .zero)
        try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: video1Duration), of: audio2Track, at: .zero)
        
        // Insert video2 with audio from video1
        try videoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: video2Duration), of: video2Track, at: video1Duration)
        try audioTrack2?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: video2Duration), of: audio1Track, at: video1Duration)
        
        // Export the final video
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        
        // Define a writable directory
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("mergedVideo.mov")
        print("Output file path: \(outputURL.path)")
        
        // Remove any existing file at the outputURL
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch {
                print("Failed to remove existing file: \(error.localizedDescription)")
            }
        }
        
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mov
        exportSession?.shouldOptimizeForNetworkUse = true
        
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                print("Export completed successfully")
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
                if let error = exportSession?.error {
                    print("Export failed with error: \(error.localizedDescription)")
                    if let detailedError = error as NSError? {
                        print("Detailed error: \(detailedError.userInfo)")
                    }
                } else {
                    print("Export failed with unknown error")
                }
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
        print("Error processing videos: \(error.localizedDescription)")
        completion(nil)
    }
}

//
//  ContentView.swift
//  JoinVideo
//
//  Created by Saboor on 29/08/2024.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var isProcessing: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isProcessing {
                Text("Processing...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .padding()
            } else if let videoURL = videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height:200)
                    .onAppear {
                        // No action needed here; VideoPlayer handles video playback.
                    }
            }
        }
        .onAppear {
            // Call the function to process videos
          
            guard let video1URL = Bundle.main.url(forResource: "video1", withExtension: "mov"),
                  let video2URL = Bundle.main.url(forResource: "video2", withExtension: "mov") else {
                print("Failed to find video files")
                self.errorMessage = "Failed to find video files"
                self.isProcessing = false
                return
            }
            
            swapAudioAndMergeVideos(video1URL: video1URL, video2URL: video2URL) { url in
                if let url = url {
                    self.videoURL = url
                } else {
                    self.errorMessage = "Failed to process videos"
                }
                self.isProcessing = false
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  NativeVideoPickerSwiftUI
//
//  Created by Yunus Emre Taşdemir on 27.06.2023.
//

import SwiftUI
import PhotosUI
// For Native Video Player
import AVKit

struct ContentView: View {
    // View Properties
    @State private var showVideoPicker: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isVideoProcessing: Bool = false
    // Picked Video URL
    @State private var pickedVideoURL: URL?
    var body: some View {
        VStack {
            ZStack {
                if let pickedVideoURL {
                    VideoPlayer(player: .init(url: pickedVideoURL))
                }
                
                if isVideoProcessing {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            
            Button("Pick Video") {
                showVideoPicker.toggle()
            }
        }
        .photosPicker(isPresented: $showVideoPicker, selection: $selectedItem, matching: .videos)
        .padding()
        // Extracting Video From PhotosItem
        .onChange(of: selectedItem) { newValue in
            if let newValue {
                Task {
                    do {
                        isVideoProcessing = true
                        // Extracting Video URL
                        let pickedMovie = try await newValue.loadTransferable(type: VideoPickerTransferable.self)
                        isVideoProcessing = false
                        pickedVideoURL = pickedMovie?.videoURL
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Custom Transferable for Video Picker
struct VideoPickerTransferable: Transferable {
    // Video URL
    let videoURL: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.videoURL)
        } importing: { ReceivedTransferredFile in
            let originalfile = ReceivedTransferredFile.file
            let copiedFile = URL.documentsDirectory.appending(path: "videoPicker.mov")
            // Checking if already file Exists at the Path
            if FileManager.default.fileExists(atPath: copiedFile.path()) {
                // Deleting Old File
                try FileManager.default.removeItem(at: copiedFile)
            }
            // Copying File
            try FileManager.default.copyItem(at: originalfile, to: copiedFile)
            // Passing the Copied File Path
            return .init(videoURL: copiedFile)
        }
    }
}

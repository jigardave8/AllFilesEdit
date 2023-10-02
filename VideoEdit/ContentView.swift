//
//  ContentView.swift
//  VideoEdit
//
//  Created by Jigar on 02/10/23.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import AVFoundation

struct ContentView: View {
    @State private var selectedURL: URL?
    @State private var isDocumentPickerPresented: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                if let selectedURL = selectedURL {
                    FileViewer(url: selectedURL)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Cancel") {
                                    self.selectedURL = nil
                                }
                            }
                        }
                } else {
                    Button("Select Photo or File") {
                        isDocumentPickerPresented.toggle()
                    }
                    .padding()
                    .fileImporter(
                        isPresented: $isDocumentPickerPresented,
                        allowedContentTypes: [UTType.audio],
                        onCompletion: { result in
                            do {
                                selectedURL = try result.get()
                            } catch {
                                print("Error importing document: \(error)")
                            }
                        }
                    )
                }
            }
            .navigationTitle("File Viewer")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct FileViewer: View {
    let url: URL
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        VStack {
            if UTType(url.pathExtension)?.conforms(to: .audio) == true {
                HStack {
                    Button("Play") {
                        playAudio()
                    }

                    Button("Pause") {
                        audioPlayer?.pause()
                    }

                    Button("Stop") {
                        stopAudio()
                    }
                }
                .padding()

                if let audioPlayer = audioPlayer {
                    Text("Duration: \(audioPlayer.duration)")
                    Text("Current Time: \(audioPlayer.currentTime)")
                }
            } else {
                // Display other file types
                QuickLookView(url: url)
            }
        }
    }

    private func playAudio() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error)")
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<QuickLookView>) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: UIViewControllerRepresentableContext<QuickLookView>) {
        // Update the view controller
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var parent: QuickLookView

        init(_ parent: QuickLookView) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
    }
}

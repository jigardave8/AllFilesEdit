//
//  ContentView1.swift
//  VideoEdit
//
//  Created by Jigar on 02/10/23.
//


import SwiftUI
import MediaPlayer
import AVFoundation

class LibraryViewModel: ObservableObject {
    @Published var songs: [MPMediaItem] = []
    @Published var selectedSong: MPMediaItem?

    func fetchSongs() {
        let query = MPMediaQuery.songs()
        if let items = query.items {
            songs = items
        }
    }
}

class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()
    
    private var audioPlayer: AVAudioPlayer?

    @Published var isPlaying: Bool = false

    func play(song: MPMediaItem) {
        guard let url = song.assetURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }

    func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}

struct LibraryView: View {
    @ObservedObject var libraryViewModel = LibraryViewModel()
    @ObservedObject var audioPlayerManager = AudioPlayerManager()

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                List(libraryViewModel.songs, id: \.persistentID) { song in
                    Button(action: {
                        libraryViewModel.selectedSong = song
                        audioPlayerManager.play(song: song)
                    }) {
                        Text(song.title ?? "Unknown Title")
                    }
                }
                .frame(width: 200)
                .onAppear {
                    libraryViewModel.fetchSongs()
                }
                .navigationBarTitle("Music Library")

                // Fancy media control view
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            audioPlayerManager.togglePlayPause()
                        }) {
                            Image(systemName: audioPlayerManager.isPlaying ? "pause.circle" : "play.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                }
                .padding()
            }
        }
    }
}

struct ContentView1: View {
    var body: some View {
        LibraryView()
    }
}


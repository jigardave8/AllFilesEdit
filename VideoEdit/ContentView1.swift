//
//  ContentView1.swift
//  VideoEdit
//
//  Created by Jigar on 02/10/23.
//


import SwiftUI
import MediaPlayer
import AVFoundation
import Combine

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

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerManager()

    @Published var isPlaying: Bool = false
    @Published var audioLevels: Float = 0.0
    var audioPlayer: AVAudioPlayer?

    func play(song: MPMediaItem) {
        guard let url = song.assetURL else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.prepareToPlay()
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

    func stop() {
        if isPlaying {
            audioPlayer?.stop()
            audioPlayer = nil
            isPlaying.toggle()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }

    func updateAudioLevels() {
        guard let audioPlayer = audioPlayer else {
            return
        }

        audioPlayer.updateMeters()
        audioLevels = audioPlayer.averagePower(forChannel: 0) / -160.0
    }
}

struct ContentView1: View {
    @ObservedObject var libraryViewModel = LibraryViewModel()
    @ObservedObject var audioPlayerManager = AudioPlayerManager()

    var body: some View {
        NavigationView {
            VStack {
                // Top half for music player controls
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // Shuffle action
                        }) {
                            Image(systemName: "shuffle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        Spacer()
                        Button(action: {
                            audioPlayerManager.togglePlayPause()
                        }) {
                            Image(systemName: audioPlayerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 70, height: 70)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(35)
                        }
                        Spacer()
                        Button(action: {
                            // Stop action
                            audioPlayerManager.stop()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        Spacer()
                    }
                    Spacer()
                }

                // Bottom half for user's media library
                List {
                    ForEach(libraryViewModel.songs, id: \.persistentID) { song in
                        Button(action: {
                            libraryViewModel.selectedSong = song
                            audioPlayerManager.play(song: song)
                        }) {
                            HStack {
                                Text(song.title ?? "Unknown Title")
                                    .foregroundColor(song == libraryViewModel.selectedSong ? .blue : .black)
                                Spacer()
                                if song == libraryViewModel.selectedSong && audioPlayerManager.isPlaying {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(8)
                        }
                    }
                }
                .onAppear {
                    _ = libraryViewModel.$songs
                        .sink { _ in
                            // Handle songs change
                        }

                    // Fetch songs
                    libraryViewModel.fetchSongs()
                }
                .background(Color.red) // Add background color

                // Waveform view
                WaveformView(audioPlayerManager: audioPlayerManager)
            }
            .navigationBarItems(trailing:
                HStack {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .padding()
                    }
                    Button(action: {
                        // Funky button action
                    }) {
                        Image(systemName: "star.fill")
                            .padding()
                    }
                }
            )
        }
        .onAppear {
            // Set the audio player manager as the delegate
            audioPlayerManager.audioPlayer?.delegate = audioPlayerManager
        }
    }
}

struct SettingsView: View {
    var body: some View {
        // Add settings content here
        Text("Settings View")
            .navigationBarTitle("Settings")
    }
}

struct WaveformView: View {
    @ObservedObject var audioPlayerManager: AudioPlayerManager

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<10) { _ in
                Rectangle()
                    .frame(width: 10, height: CGFloat(audioPlayerManager.audioLevels * 100))
                    .foregroundColor(.red)
            }
        }
    }
}


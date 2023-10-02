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
    static let shared = LibraryViewModel()

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
    @Published var showSettings: Bool = false
    var audioPlayer: AVAudioPlayer?
    var currentIndex: Int = 0

    // Equalizer settings
    enum EqualizerSetting: String, CaseIterable {
        
        case normal = "Normal"
        case rock = "Rock"
        case pop = "Pop"
        case jazz = "Jazz"
        case bass = "Bass"
        case treble = "Treble"
        case bassAndTreble = "Bass & Treble"
        case classical = "Classical"
        case hipHop = "Hip-Hop"
        case reset = "Reset"
    }

    @Published var currentEqualizerSetting: EqualizerSetting = .normal {
        didSet {
            applyEqualizerSetting()
        }
    }

    func play(song: MPMediaItem) {
        guard let url = song.assetURL else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true

            // Set selected song index
            currentIndex = LibraryViewModel.shared.songs.firstIndex(of: song) ?? 0

            // Apply equalizer settings when a new song starts playing
            applyEqualizerSetting()
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
        playNext()
    }

    func updateAudioLevels() {
        guard let audioPlayer = audioPlayer else {
            return
        }

        audioPlayer.updateMeters()
        audioLevels = audioPlayer.averagePower(forChannel: 0) / -160.0
    }

    func playNext() {
        if LibraryViewModel.shared.songs.isEmpty {
            return
        }

        currentIndex = (currentIndex + 1) % LibraryViewModel.shared.songs.count
        play(song: LibraryViewModel.shared.songs[currentIndex])
    }

    func playPrevious() {
        if LibraryViewModel.shared.songs.isEmpty {
            return
        }

        currentIndex = (currentIndex - 1 + LibraryViewModel.shared.songs.count) % LibraryViewModel.shared.songs.count
        play(song: LibraryViewModel.shared.songs[currentIndex])
    }

    func shuffle() {
        LibraryViewModel.shared.songs.shuffle()
        currentIndex = 0
        play(song: LibraryViewModel.shared.songs[currentIndex])
    }

    private func applyEqualizerSetting() {
        guard let audioPlayer = audioPlayer else { return }

        // Reset equalizer settings
        audioPlayer.updateMeters()
        audioPlayer.enableRate = false
        audioPlayer.rate = 1.0

        switch currentEqualizerSetting {
        case .normal:
            // Apply normal equalizer settings
            break
        case .rock:
            // Apply rock equalizer settings
            audioPlayer.enableRate = true
            audioPlayer.rate = 1.1
        case .pop:
            // Apply pop equalizer settings
            audioPlayer.enableRate = true
            audioPlayer.rate = 1.2
        case .jazz:
            // Apply jazz equalizer settings
            audioPlayer.enableRate = true
            audioPlayer.rate = 1.3
        case .bass:
            // Apply bass equalizer settings
            audioPlayer.enableRate = true
            audioPlayer.rate = 1.2
        case .treble:
            // Apply treble equalizer settings
            audioPlayer.enableRate = true
            audioPlayer.rate = 0.8
        case .bassAndTreble:
            // Apply bass and treble equalizer settings
            audioPlayer.enableRate = true
            audioPlayer.rate = 1.5
        case .classical:
            // Apply classical equalizer settings
            break
        case .hipHop:
            // Apply hip-hop equalizer settings
            break
        case .reset:
            // Reset equalizer settings
            audioPlayer.enableRate = false
            audioPlayer.rate = 1.0
        }
    }
}

struct ContentView1: View {
    @ObservedObject var libraryViewModel = LibraryViewModel.shared
    @ObservedObject var audioPlayerManager = AudioPlayerManager.shared

    var body: some View {
        NavigationView {
            VStack {
                // panel for user's media library
                VStack {
                    Text("Media Library")
                        .font(.headline)
                        .padding()
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
                                .padding(2)
                                .background(song == libraryViewModel.selectedSong && audioPlayerManager.isPlaying ? Color.yellow : Color.white)
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
                }

                // music player controls
                VStack {
                    HStack {
                        Button(action: {
                            audioPlayerManager.shuffle()
                        }) {
                            Image(systemName: "shuffle")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        Spacer()
                        Button(action: {
                            audioPlayerManager.playPrevious()
                        }) {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
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
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(35)
                        }
                        Spacer()
                        Button(action: {
                            audioPlayerManager.playNext()
                        }) {
                            Image(systemName: "forward.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        Spacer()
                        Button(action: {
                            audioPlayerManager.stop()
                        }) {
                            Image(systemName: "stop.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                    }
                }
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
            // Set up the audio session for background playing
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to configure audio session:", error.localizedDescription)
            }

            // Set the audio player manager as the delegate
            audioPlayerManager.audioPlayer?.delegate = audioPlayerManager
        }
        .sheet(isPresented: $audioPlayerManager.showSettings) {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @ObservedObject var audioPlayerManager = AudioPlayerManager.shared

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Equalizer Settings")) {
                    ForEach(AudioPlayerManager.EqualizerSetting.allCases, id: \.self) { option in
                        Button(action: {
                            audioPlayerManager.currentEqualizerSetting = option
                        }) {
                            HStack {
                                Text(option.rawValue)
                                Spacer()
                                if audioPlayerManager.currentEqualizerSetting == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}


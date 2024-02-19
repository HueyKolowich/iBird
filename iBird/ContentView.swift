//
//  ContentView.swift
//  iBird
//
//  Created by Huey Kolowich on 11/25/23.
//

import SwiftUI

struct ContentView: View {
    @State private var isRecording = false
    @State private var birdAudioClassifier = BirdAudioClassifier()
    @State private var observations = Set<Observation>()
    @State private var vocalization = " "
    @State private var lyricTask: Task<Void, Never>?
    @State private var streamTask: Task<Void, Never>?
    
    let birdData = BirdData.data
    
    var body: some View {
        VStack {
            if isRecording {
                Group {
                    Text("Sing the following")
                        .font(.title)
                    Text("(to the tune of Bob Marley's \"Three Little Birds\")")
                        .font(.footnote)
                    Text(vocalization)
                        .onChange(of: vocalization ) {
                            if $1.localizedStandardContains("message") {
                                Task {
                                    try? await Task.sleep(nanoseconds: 1_000_000_000 * 1)
                                    
                                    Task { @MainActor in
                                        if isRecording {
                                            withAnimation {
                                                isRecording.toggle()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                }
            }
            
            Toggle(isRecording ? "Stop" : "Record",
                   systemImage: "mic",
                   isOn: $isRecording.animation())
                .toggleStyle(.button)
            
            List {
                ForEach(observations.sorted(by: { $0.lastSeen > $1.lastSeen })) { observation in
                    if let bird = birdData[observation.id] {
                        NavigationLink(value: bird) {
                            HStack {
                                Text(bird.species)
                                Spacer()
                                Text(observation.confidence, format: .percent.precision(.fractionLength(0)))
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: BirdData.self, destination: { bird in
                BirdView(bird: bird)
            })
        }
        .padding()
        .onChange(of: isRecording) {
            if isRecording {
                lyricTask?.cancel()
                lyricTask = Task {
                    let vocalizations = [
                        "Rise up this morning",
                        "Smile with the rising sun",
                        "Three little birds",
                        "Pitch by my doorstep",
                        "Singing sweet songs",
                        "Of melodies pure and true",
                        "Saying this is my message to you",
                        " "
                    ]
                    
                    for lyric in vocalizations {
                        try? await Task.sleep(nanoseconds: 1_000_000_000 * 3)
                        guard Task.isCancelled == false else { return }
                        Task { @MainActor in
                            withAnimation{
                                vocalization = lyric
                            }
                        }
                    }
                }
                
                observations.removeAll()
                let stream = birdAudioClassifier.start()
                
                streamTask?.cancel()
                streamTask = Task {
                    for await classification in stream {
                        Task { @MainActor in 
                            withAnimation {
                                guard var observation = observations.first(where: {
                                    $0.id == classification.identifier
                                }) else {
                                    let observation = Observation(classification: classification)
                                    observations.insert(observation)
                                    return
                                }
        
                                observation.add(classification)
                                observations.update(with: observation)
                            }
                        }
                    }
                }
            } else {
                birdAudioClassifier.stop()
                streamTask?.cancel()
                lyricTask?.cancel()
            }
        }
        .onDisappear {
            if isRecording {
                isRecording.toggle()
                birdAudioClassifier.stop()
            }
        }
    }
    
    func startRecording() {
        
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}

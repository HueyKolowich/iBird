//
//  iBird
//
//  Created by Huey Kolowich on 11/25/23.
//

import SwiftUI
import AVFoundation

struct BirdView: View {
    let bird: BirdData
    @State var player: AVAudioPlayer?
    
    var body: some View {
        VStack {
            Text(bird.species)
                .font(.title)
            
            Text(bird.sciName)
                .font(.footnote)
            
            Button(action: {
                guard let url = bird.url else { return }
                
                player?.stop()
                
                do {
                    player = try AVAudioPlayer(contentsOf: url)
                    player?.play()
                } catch {
                    print(error)
                }
            }) {
                Label("Listen", systemImage: "play")
            }
            
        }
        .padding()
        .onDisappear(perform: {
            player?.stop()
        })
    }
}

#Preview {
    BirdView(bird: BirdData(id: "aldfly", species: "Alder Flycatcher", sciName: "Empidonax alnorum", audioFileName: "XC381873.mp3"))
}

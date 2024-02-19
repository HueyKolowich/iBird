//
//  BirdData.swift
//  iBird
//
//  Created by Huey Kolowich on 12/18/23.
//

import Foundation

struct BirdData: Hashable {
    let id: String
    let species: String
    let sciName: String
    private let audioFileName: String
    
    init(id: String, species: String, sciName: String, audioFileName: String) {
        self.id = id
        self.species = species
        self.sciName = sciName
        self.audioFileName = audioFileName
    }
    
    static var data: [String: BirdData] {
        let url = Bundle.main.url(forResource: "birds", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let intermediateData = try! JSONDecoder().decode([String: [String]].self, from: data)
        
        return intermediateData.mapValues { strings in
            return BirdData(id: strings[3], species: strings[0], sciName: strings[1], audioFileName: strings[2])
        }
    }
    
    var url: URL? {
        guard let index = audioFileName.lastIndex(of: ".") else { return nil }
        return Bundle.main.url(forResource: String(audioFileName.prefix(upTo: index)), withExtension: ".mp3", subdirectory: "audio")
    }
}

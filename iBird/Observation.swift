//
//  Observation.swift
//  iBird
//
//  Created by Huey Kolowich on 12/18/23.
//

import SoundAnalysis

struct Observation: Identifiable, Hashable, Equatable {
    var classifications: [SNClassification]
    var count = 0
    var lastSeen: Date = .now
    
    var id: String { classifications.first?.identifier ?? "" }
    
    init(classification: SNClassification, count: Int = 1, lastSeen: Date = .now) {
        self.classifications = [classification]
        self.count = count
        self.lastSeen = lastSeen
    }
    
    mutating func add(_ classification: SNClassification) {
        count += 1
        lastSeen = .now
        classifications.append(classification)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (observation1: Observation, observation2: Observation) -> Bool {
        return observation1.id == observation2.id
    }
    
    var confidence: Double {
        return classifications.last?.confidence ?? 0
    }
}

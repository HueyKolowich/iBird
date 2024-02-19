//
//  BirdAudioClassifier.swift
//  iBird
//
//  Created by Huey Kolowich on 11/25/23.
//

import Foundation
import SoundAnalysis

class AsyncResultsStream: NSObject, SNResultsObserving {
    var classifier: BirdAudioClassifier?
    var continuation: AsyncStream<SNClassification>.Continuation?
    
    func start() -> AsyncStream<SNClassification> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    init(classifier: BirdAudioClassifier) {
        self.classifier = classifier
    }
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        guard let first = result.classifications.first(where: { $0.confidence > 0.3 })  else { return }
        
//        print("\(first.identifier) with confidence \(first.confidence)")
        
        continuation?.yield(first)
    }
    
    func requestDidComplete(_ request: SNRequest) {
        classifier?.stop()
        continuation?.finish()
        continuation = nil
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print(error)
    }
}

class BirdAudioClassifier: NSObject {
    private var audioEngine: AVAudioEngine?
    private var analyzer: SNAudioStreamAnalyzer?
    private var resultStream: AsyncResultsStream?
    
    func start() -> AsyncStream<SNClassification> {
        stop()
        
        if resultStream == nil { resultStream = AsyncResultsStream(classifier: self) }
        guard let resultStream else { fatalError("This was probably Dad's fault!") }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            try ensureMicrophoneAccess()
            
            let newAudioEngine = AVAudioEngine()
            audioEngine = newAudioEngine

            let busIndex = AVAudioNodeBus(0)
            let bufferSize = AVAudioFrameCount(4096)
            let audioFormat = newAudioEngine.inputNode.outputFormat(forBus: busIndex)
            
            let newAnalyzer = SNAudioStreamAnalyzer(format: audioFormat)
            analyzer = newAnalyzer
            
            let inferenceWindowSize = Double(0.975) //Old: 1.5
            let overlapFactor = Double(0.5) //Old 0.9
//            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            let model = try BirdClassifier.init().model
            let request = try SNClassifySoundRequest(mlModel: model)
            request.windowDuration = CMTimeMakeWithSeconds(inferenceWindowSize, preferredTimescale: 48_000)
            request.overlapFactor = overlapFactor
            
            try newAnalyzer.add(request, withObserver: resultStream)
            
            newAudioEngine.inputNode.installTap(
              onBus: busIndex,
              bufferSize: bufferSize,
              format: audioFormat,
              block: { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                  Task {
                      newAnalyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
                  }
              })

            try newAudioEngine.start()
        } catch {
            stop()
            print(error)
        }
        
        return resultStream.start()
    }
    
    func stop() {
        print("Stopping")
        try? AVAudioSession.sharedInstance().setActive(false)
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        if let analyzer = analyzer {
            analyzer.removeAllRequests()
        }

        analyzer = nil
        audioEngine = nil
        resultStream?.continuation?.finish()
    }
    
    private func ensureMicrophoneAccess() throws {
        var hasMicrophoneAccess = false
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            let sem = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { success in
                hasMicrophoneAccess = success
                sem.signal()
            })
            _ = sem.wait(timeout: DispatchTime.distantFuture)
        case .denied, .restricted:
            break
        case .authorized:
            hasMicrophoneAccess = true
        @unknown default:
            fatalError("unknown authorization status for microphone access")
        }

        if !hasMicrophoneAccess {
            fatalError("no microphone access")
        }
    }
}

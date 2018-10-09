//
//  GoogleSpeechRecognizer.swift
//  SpokeStack
//
//  Created by Cory D. Wiles on 9/28/18.
//  Copyright © 2018 Pylon AI, Inc. All rights reserved.
//

import Foundation
import googleapis

public class GoogleSpeechRecognizer: SpeechRecognizerService {

    // MARK: Public (properties)
    
    static let sharedInstance: GoogleSpeechRecognizer = GoogleSpeechRecognizer()
    
    // MARK: SpeechRecognizerService (properties)
    
    public var configuration: RecognizerConfiguration = StandardGoogleRecognitionConfiguration()
    
    public weak var delegate: SpeechRecognizer?
    
    // MARK: Private (properties)
    
    private var streaming: Bool = false
    
    private var audioData: NSMutableData!
    
    private var client: Speech!
    
    private var writer: GRXBufferedPipe!
    
    private var call: GRPCProtoCall!
    
    private var googleConfiguration: GoogleRecognizerConfiguration {
        return self.configuration as! GoogleRecognizerConfiguration
    }
    
    lazy private var recognitionConfig: RecognitionConfig = {

        let config: RecognitionConfig = RecognitionConfig()
        
        config.encoding =  .linear16
        config.sampleRateHertz = Int32(AudioController.shared.sampleRate)
        config.languageCode = self.googleConfiguration.languageLocale
        config.maxAlternatives = self.googleConfiguration.maxAlternatives
        config.enableWordTimeOffsets = self.googleConfiguration.enableWordTimeOffsets
        
        return config
    }()
    
    lazy private var streamingRecognitionConfig: StreamingRecognitionConfig = {
       
        let config: StreamingRecognitionConfig = StreamingRecognitionConfig()
        
        config.config = self.recognitionConfig
        config.singleUtterance = self.googleConfiguration.singleUtterance
        config.interimResults = self.googleConfiguration.interimResults
        
        return config
    }()
    
    lazy private var streamingRecognizerRequest: StreamingRecognizeRequest = {
       
        let recognizer: StreamingRecognizeRequest = StreamingRecognizeRequest()
        recognizer.streamingConfig = self.streamingRecognitionConfig
        
        return recognizer
    }()
    
    // MARK: Initializers
    
    public init() {
        AudioController.shared.delegate = self
    }
    
    // MARK: SpeechRecognizerService
    
    public func startStreaming() -> Void {

        self.audioData = NSMutableData()
        AudioController.shared.startStreaming()
        self.delegate?.didStart()
    }
    
    public func stopStreaming() -> Void {
        
        AudioController.shared.stopStreaming()
        
        if !self.streaming {
            return
        }
        
        self.writer.finishWithError(nil)
        self.streaming = false
    }
    
    // MARK: Private (methods)
    
    private func analyzeAudioData(_ audioData: NSData) -> Void {
        
        if !self.streaming {
        
            self.delegate?.didHaveConfiguration(self.googleConfiguration)
            self.client = Speech(host: self.googleConfiguration.host)
            self.writer = GRXBufferedPipe()
            self.call = self.client.rpcToStreamingRecognize(withRequestsWriter: self.writer,
                                                            eventHandler: {[weak self] done, response, error in
                                                                print("what is the response \(String(describing: response))")
                                                                guard let strongSelf = self, error == nil else {
                                                                    self?.delegate?.didFindResults("failed at guard \(String(describing: error?.localizedDescription))")
                                                                    self?.delegate?.didFinish()
                                                                    return
                                                                }
                                                                
                                                                let debug: String = "done \(done) response \(String(describing: response)) and error \(String(describing: error))"
                                                                
                                                                strongSelf.delegate?.didFindResults(debug)
                
                                                                var finished = false
                                                                let result: StreamingRecognitionResult = response!.resultsArray!.firstObject as! StreamingRecognitionResult
                                                                let alt: SpeechRecognitionAlternative = result.alternativesArray!.firstObject as! SpeechRecognitionAlternative
                                                                
                                                                if result.isFinal {
                                                                    finished = true
                                                                }
                                                                
                                                                if finished {

                                                                    //                    print("result \(result) and isFinished \(result.isFinal)")

                                                                    let context: SPSpeechContext = SPSpeechContext(transcript: alt.transcript, confidence: alt.confidence)
                                                    //                print("alt \(alt.confidence) and \(alt.transcript)")
                                                                    strongSelf.delegate?.didRecognize(context)
                                                                    strongSelf.stopStreaming()
                                                                    
                                                                } else {
                                                                    
                                                                    strongSelf.delegate?.didFindResultsButNotFinal()
                                                                }
            })
            
            /// authenticate using an API key obtained from the Google Cloud Console
            
            self.call.requestHeaders.setObject(NSString(string: self.googleConfiguration.apiKey),
                                               forKey:NSString(string:"X-Goog-Api-Key"))
            
            /// if the API key has a bundle ID restriction, specify the bundle ID like this
            
            self.call.requestHeaders.setObject(NSString(string:Bundle.main.bundleIdentifier!),
                                               forKey:NSString(string:"X-Ios-Bundle-Identifier"))
            
            self.delegate?.didFindResults("\(String(describing: self.call.requestHeaders))")
            
            self.call.start()
            self.streaming = true
            
            self.delegate?.streamingDidStart()
            
            /// send an initial request message to configure the service

            self.delegate?.didWriteInital(self.streamingRecognizerRequest)
            self.writer.writeValue(self.streamingRecognizerRequest)
        }
        
        /// send a request message containing the audio data
        
        let streamingRecognizeRequest: StreamingRecognizeRequest = StreamingRecognizeRequest()
        streamingRecognizeRequest.audioContent = audioData as Data
        
        self.delegate?.didWriteSteamingAudioContent(streamingRecognizeRequest)
        self.writer.writeValue(streamingRecognizeRequest)
        
        let dataCount = streamingRecognizeRequest.audioContent.count
        let bcf = ByteCountFormatter()

        bcf.countStyle = .file

        let string = bcf.string(fromByteCount: Int64(dataCount))
        print("did write more audio 2222 \(string)")
    }
}

extension GoogleSpeechRecognizer: AudioControllerDelegate {
    
    func setupFailed(_ error: String) {
        
        self.streaming = false
        self.delegate?.setupFailed()
    }
    
    func processSampleData(_ data: Data) -> Void {

        /// Convert to model and pass back to delegate
        
        self.audioData.append(data)
        
        /// We recommend sending samples in 100ms chunks
        
        let chunkSize: Int = Int(0.1 * Double(AudioController.shared.sampleRate) * 2)
        
        print("what is the chunk size \(chunkSize)")
        
        if self.audioData.length > chunkSize {
            
            self.delegate?.beginAnalyzing()
            self.analyzeAudioData(self.audioData)
            self.audioData = NSMutableData()
        }
    }
}

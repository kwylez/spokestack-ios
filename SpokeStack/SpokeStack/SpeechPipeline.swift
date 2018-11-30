//
//  SpeechPipeline.swift
//  SpokeStack
//
//  Created by Cory D. Wiles on 10/2/18.
//  Copyright © 2018 Pylon AI, Inc. All rights reserved.
//

import Foundation

@objc public final class SpeechPipeline: NSObject {
    
    // MARK: Public (properties)
    
    public private (set) var service: RecognizerService
    
    public private (set) var configuration: RecognizerConfiguration
    
    public weak var delegate: SpeechRecognizer?
    
    // MARK: Private (properties)
    
    private var speechRecognizerService: SpeechRecognizerService = GoogleSpeechRecognizer.sharedInstance
    
    // MARK: Initializers
    
    deinit {
        speechRecognizerService.delegate = nil
    }
    
    @objc public init (_ service: RecognizerService, configuration: RecognizerConfiguration, delegate: SpeechRecognizer?) throws {
        
        func didInitialize() -> Bool {
            
            var didInitialize: Bool = false
            
            switch service {
            case .google where configuration is GoogleRecognizerConfiguration:

                self.speechRecognizerService.configuration = configuration
                
                didInitialize = true
                break
            default: break
            }
            
            return didInitialize
        }
        
        self.speechRecognizerService = service.speechRecognizerService
        self.speechRecognizerService.delegate = self.delegate
        
        self.service = service
        self.configuration = configuration
        self.delegate = delegate
        
        super.init()
        
        if !didInitialize() {
            
            let errorMessage: String = """
            The service must be google and your configuration must conform to GoogleRecognizerConfiguration.
            Future release will support other services.
            """
            throw SpeechPipleError.invalidInitialzation(errorMessage)
        }
    }
    
    @objc public func start() -> Void {
        self.speechRecognizerService.startStreaming()
    }
    
    @objc public func stop() -> Void {
        self.speechRecognizerService.stopStreaming()
    }
}


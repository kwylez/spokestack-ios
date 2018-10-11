//
//  GoogleRecognizerConfiguration.swift
//  SpokeStack
//
//  Created by Cory D. Wiles on 9/28/18.
//  Copyright © 2018 Pylon AI, Inc. All rights reserved.
//

import Foundation

public protocol GoogleRecognizerConfiguration: RecognizerConfiguration {
    
    var host: String { get set }
    var apiKey: String { get set }
}


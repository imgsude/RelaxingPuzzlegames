//
//  Item.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

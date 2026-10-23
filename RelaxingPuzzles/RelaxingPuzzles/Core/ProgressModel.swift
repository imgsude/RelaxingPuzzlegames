//
//  ProgressModel.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//import SwiftData

import SwiftData
import Foundation

@Model
class ProgressModel {
    var currentLevel: Int
    var lastPlayedDay: Date

    init(currentLevel: Int = 0, lastPlayedDay: Date = Date()) {
        self.currentLevel = currentLevel
        self.lastPlayedDay = lastPlayedDay
    }
}

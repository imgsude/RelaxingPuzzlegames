//
//  LevelData.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//

import Foundation

struct LevelData {
    static func generate() -> [PuzzleModel] {
        var levels: [PuzzleModel] = []

        for i in 0..<LevelFactory.totalLevels {   // 100
            levels.append(PuzzleModel(
                type: PuzzleType.allCases[i % 4],
                difficulty: i / 4                  // 0...24
            ))
        }
        return levels
    }
}

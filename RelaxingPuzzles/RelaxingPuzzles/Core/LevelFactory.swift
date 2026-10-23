//
//  LevelFactory.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 19.10.2026.
//
import SpriteKit

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum LevelFactory {
    static let totalLevels = 100

    static func makeScene(level: Int, gameManager: GameManager) -> BasePuzzleScene {
        let l = min(max(level, 1), totalLevels)
        switch (l - 1) % 4 {
        case 0:  return ShapePlaceScene(gameManager: gameManager, level: l)
        case 1:  return LineConnectScene(gameManager: gameManager, level: l)
        case 2:  return FlowWaterScene(gameManager: gameManager, level: l)
        default: return BalanceScene(gameManager: gameManager, level: l)
        }
    }
}

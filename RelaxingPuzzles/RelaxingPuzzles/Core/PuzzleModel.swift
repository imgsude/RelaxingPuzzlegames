//
//  PuzzleModel.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//
import Foundation

struct PuzzleModel: Identifiable {
    let id = UUID()
    let type: PuzzleType
    let difficulty: Int
}

//
//  GameManager.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//

import SwiftUI
import SwiftData

@MainActor
final class GameManager: ObservableObject {

    @Published var currentIndex: Int = 0
    @Published var isFinished: Bool = false
    @Published var completionTick: Int = 0       // level bitince artar (sıfırlamada artmaz)
    let levels: [PuzzleModel]

    private let modelContext: ModelContext
    private var progress: ProgressModel

    init(context: ModelContext) {
        self.modelContext = context
        self.levels = LevelData.generate()

        if let saved = try? context.fetch(FetchDescriptor<ProgressModel>()).first {
            self.progress = saved
            self.currentIndex = min(max(saved.currentLevel, 0), levels.count - 1)
        } else {
            let new = ProgressModel(currentLevel: 0)
            context.insert(new)
            self.progress = new
        }
    }

    var currentPuzzle: PuzzleModel { levels[currentIndex] }

    /// Sahnelere giden level numarası (1...100)
    var currentLevel: Int { currentIndex + 1 }

    /// Daha önce ilerleme var mı? (Continue butonu için)
    var hasProgress: Bool { currentIndex > 0 }

    func completeCurrentPuzzle() {
        if currentIndex < levels.count - 1 {
            currentIndex += 1
            progress.currentLevel = currentIndex
            try? modelContext.save()
            completionTick += 1
        } else {
            isFinished = true
        }
    }

    /// Yeni oyun: ilerlemeyi sıfırlar
    func startNewGame() {
        isFinished = false
        currentIndex = 0
        progress.currentLevel = 0
        try? modelContext.save()
    }
}

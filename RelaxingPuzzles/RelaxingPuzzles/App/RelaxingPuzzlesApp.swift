//
//  RelaxingPuzzlesApp.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//
import SwiftUI
import SwiftData

@main
struct RelaxingPuzzlesApp: App {

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: [ProgressModel.self])
    }
}

// MARK: - Root
struct AppRootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        GameManagerLoader(context: context)
    }
}

struct GameManagerLoader: View {
    @StateObject private var gameManager: GameManager

    init(context: ModelContext) {
        _gameManager = StateObject(wrappedValue: GameManager(context: context))
    }

    var body: some View {
        HomeView()
            .environmentObject(gameManager)
    }
}

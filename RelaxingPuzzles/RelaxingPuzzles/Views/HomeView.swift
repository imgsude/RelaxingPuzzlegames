//
//  ContentView.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//
import SwiftUI
import SwiftData

struct HomeView: View {

    @EnvironmentObject var gameManager: GameManager
    @State private var showPuzzle = false
    @State private var showEnd = false
    @State private var showFinished = false
    @State private var confirmNewGame = false

    var body: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 24) {
                Text("Level \(gameManager.currentLevel)")
                    .font(.title2)
                    .fontWeight(.medium)

                Text(gameManager.currentPuzzle.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                ZenButton(title: gameManager.hasProgress ? "Continue" : "Play") {
                    showPuzzle = true
                }

                if gameManager.hasProgress {
                    ZenButton(title: "New Game") {
                        confirmNewGame = true
                    }
                }
            }

            if showPuzzle {
                PuzzleContainerView()
                    .ignoresSafeArea()
                    .environmentObject(gameManager)
                    .transition(.opacity)
            }

            if showEnd {
                EndTransition {
                    withAnimation { showEnd = false }
                }
                .transition(.opacity)
            }

            if showFinished {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()

                    VStack(spacing: 20) {
                        Text("🏆 All 100 levels complete 🏆")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text("You finished every puzzle.\nTake a deep breath.")
                            .multilineTextAlignment(.center)
                            .opacity(0.8)

                        ZenButton(title: "Play Again") {
                            gameManager.startNewGame()
                            withAnimation { showFinished = false }
                        }
                    }
                    .padding(30)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
                    .padding(24)
                }
                .transition(.opacity)
            }
        }
        .confirmationDialog(
            "Start a new game?",
            isPresented: $confirmNewGame,
            titleVisibility: .visible
        ) {
            Button("Reset progress", role: .destructive) {
                gameManager.startNewGame()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your progress will be erased and you'll start from Level 1.")
        }
        // Level 1-99 bitince
        .onChange(of: gameManager.completionTick) { _, _ in
            withAnimation {
                showPuzzle = false
                showEnd = true
            }
        }
        // 100. level bitince
        .onChange(of: gameManager.isFinished) { _, finished in
            guard finished else { return }
            withAnimation {
                showPuzzle = false
                showEnd = false
                showFinished = true
            }
        }
    }
}

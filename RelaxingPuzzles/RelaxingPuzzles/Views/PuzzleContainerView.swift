//
//  PuzzleContainerView.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//
import SwiftUI
import SpriteKit

struct PuzzleContainerView: View {

    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        ZStack {
            // Level değişince host tamamen yenilenir → yeni sahne
            SceneHost()
                .id(gameManager.currentLevel)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Text("Level \(gameManager.currentLevel)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                Spacer()
            }
        }
    }
}

private struct SceneHost: View {

    @EnvironmentObject var gameManager: GameManager
    @State private var scene: SKScene?

    var body: some View {
        Group {
            if let scene {
                SpriteView(scene: scene)
            } else {
                Color.clear
            }
        }
        .onAppear {
            if scene == nil { scene = makeScene() }   // sadece bir kez
        }
    }

    private func makeScene() -> SKScene {
        let level = gameManager.currentLevel

        switch gameManager.currentPuzzle.type {
        case .shapePlace:
            return ShapePlaceScene(gameManager: gameManager, level: level)
        case .lineConnect:
            return LineConnectScene(gameManager: gameManager, level: level)
        case .flowWater:
            return FlowWaterScene(gameManager: gameManager, level: level)
        case .balance:
            return BalanceScene(gameManager: gameManager, level: level)
        }
    }
}

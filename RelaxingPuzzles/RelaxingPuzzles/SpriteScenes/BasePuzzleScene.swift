//
//  BasePuzzleScene.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//

import SpriteKit

class BasePuzzleScene: SKScene {

    let gameManager: GameManager
    let level: Int
    var rng: SeededRNG

    /// 0...24 (her puzzle türü için kendi basamağı)
    var tier: Int { (level - 1) / 4 }
    /// 0...1 (zorluk 14. basamakta zirveye ulaşır)
    var progress: CGFloat { min(1, CGFloat(tier) / 14) }

    /// Kolay (a) → zor (b) değer
    func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * progress }

    init(gameManager: GameManager, level: Int) {
        let lv = max(1, min(level, 100))
        self.gameManager = gameManager
        self.level = lv
        self.rng = SeededRNG(seed: UInt64(lv) &* 7919)
        super.init(size: UIScreen.main.bounds.size)
        print("🎮 \(type(of: self)) | level \(lv) | tier \((lv - 1) / 4)")
        scaleMode = .resizeFill
        backgroundColor = .systemBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func completePuzzle() {
        isUserInteractionEnabled = false
        run(
            SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.run { [weak self] in
                    guard let self else { return }
                    Task { @MainActor in
                        self.gameManager.completeCurrentPuzzle()
                    }
                }
            ])
        )
    }

    func shake(_ node: SKNode) {
        node.run(.sequence([
            .moveBy(x: -8, y: 0, duration: 0.05),
            .moveBy(x: 16, y: 0, duration: 0.10),
            .moveBy(x: -8, y: 0, duration: 0.05)
        ]))
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

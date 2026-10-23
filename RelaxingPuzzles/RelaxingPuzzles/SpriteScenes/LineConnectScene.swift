//
//  LineConnectScene.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//
import SpriteKit

final class LineConnectScene: BasePuzzleScene {

    private var dots: [SKShapeNode] = []
    private var decoys: [SKShapeNode] = []
    private var labels: [SKLabelNode] = []
    private var currentIndex = 0
    private var active = false
    private var isDemo = false
    private var path = CGMutablePath()
    private var lineNode: SKShapeNode!

    private var dotCount: Int { min(12, 3 + tier * 2 / 5) }
    private var decoyCount: Int { tier >= 12 ? min(4, (tier - 10) / 3) : 0 }
    private var useSequence: Bool { tier >= 10 }              // sayı yerine yanıp sönme
    private var revealTime: TimeInterval { max(1.0, 4.0 - Double(tier) * 0.25) }
    private var flashTime: TimeInterval { max(0.22, 0.6 - Double(tier - 10) * 0.025) }
    private var radius: CGFloat { lerp(28, 19) }

    override func didMove(to view: SKView) {
        backgroundColor = .systemBackground

        lineNode = SKShapeNode()
        lineNode.strokeColor = .systemBlue
        lineNode.lineWidth = 6
        lineNode.lineCap = .round
        lineNode.lineJoin = .round
        addChild(lineNode)

        let positions = randomPositions(dotCount + decoyCount)
        for (i, pos) in positions.enumerated() {
            let dot = SKShapeNode(circleOfRadius: radius)
            dot.fillColor = .systemGray
            dot.strokeColor = .clear
            dot.position = pos
            dot.zPosition = 1
            addChild(dot)

            if i < dotCount {
                dots.append(dot)
                let label = SKLabelNode(text: "\(i + 1)")
                label.fontName = "AvenirNext-Bold"
                label.fontSize = 22
                label.fontColor = .white
                label.verticalAlignmentMode = .center
                label.alpha = 0
                dot.addChild(label)
                labels.append(label)
            } else {
                decoys.append(dot)
            }
        }

        replayHint(first: true)
    }

    private func randomPositions(_ n: Int) -> [CGPoint] {
        var minDist = lerp(115, 78)
        while true {
            var result: [CGPoint] = []
            var attempts = 0
            while result.count < n && attempts < 800 {
                attempts += 1
                let p = CGPoint(
                    x: CGFloat.random(in: 50...(size.width - 50), using: &rng),
                    y: CGFloat.random(in: (size.height * 0.2)...(size.height * 0.8), using: &rng)
                )
                if result.allSatisfy({ hypot($0.x - p.x, $0.y - p.y) > minDist }) {
                    result.append(p)
                }
            }
            if result.count == n || minDist < 50 { return result }
            minDist -= 8
        }
    }

    // MARK: - İpucu

    private func replayHint(first: Bool) {
        if useSequence {
            playSequence()
        } else {
            for l in labels {
                l.removeAllActions()
                l.run(.sequence([
                    .fadeIn(withDuration: 0.2),
                    .wait(forDuration: first ? revealTime : 1.5),
                    .fadeOut(withDuration: 0.5)
                ]))
            }
        }
    }

    private func playSequence() {
        isDemo = true
        var actions: [SKAction] = [.wait(forDuration: 0.6)]
        for d in dots {
            actions.append(.run { d.fillColor = .systemYellow })
            actions.append(.wait(forDuration: flashTime))
            actions.append(.run { d.fillColor = .systemGray })
            actions.append(.wait(forDuration: 0.12))
        }
        actions.append(.run { [weak self] in self?.isDemo = false })
        run(.sequence(actions), withKey: "demo")
    }

    // MARK: - Mantık

    private func dotIndex(at p: CGPoint, radius: CGFloat) -> Int? {
        dots.firstIndex { hypot($0.position.x - p.x, $0.position.y - p.y) < radius }
    }

    private func connect(_ i: Int) {
        let pos = dots[i].position
        if i == 0 { path.move(to: pos) } else { path.addLine(to: pos) }
        lineNode.path = path

        dots[i].fillColor = .systemBlue
        dots[i].run(.sequence([.scale(to: 1.2, duration: 0.1), .scale(to: 1.0, duration: 0.1)]))
        haptic(.light)

        currentIndex = i + 1
        if currentIndex == dots.count {
            active = false
            completePuzzle()
        }
    }

    private func wrong() {
        removeAction(forKey: "demo")
        active = false
        haptic(.medium)
        (dots + decoys).forEach { shake($0); $0.fillColor = .systemGray }
        path = CGMutablePath()
        lineNode.path = nil
        currentIndex = 0
        replayHint(first: false)
    }

    // MARK: - Dokunma

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isDemo, let touch = touches.first, currentIndex < dots.count else { return }
        guard let idx = dotIndex(at: touch.location(in: self), radius: radius + 10) else { return }

        if currentIndex == 0 && idx == 0 {
            connect(0)
            active = true
        } else if currentIndex > 0 && idx == currentIndex - 1 {
            active = true
        } else if idx >= currentIndex {
            wrong()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard active, let touch = touches.first else { return }
        let loc = touch.location(in: self)

        let temp = CGMutablePath()
        temp.addPath(path)
        temp.addLine(to: loc)
        lineNode.path = temp

        if let idx = dotIndex(at: loc, radius: radius + 8), idx == currentIndex {
            connect(idx)
        } else if let idx = dotIndex(at: loc, radius: radius - 4), idx > currentIndex {
            wrong()
        } else if decoys.contains(where: { hypot($0.position.x - loc.x, $0.position.y - loc.y) < radius - 4 }) {
            wrong()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard active else { return }
        active = false
        lineNode.path = path
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

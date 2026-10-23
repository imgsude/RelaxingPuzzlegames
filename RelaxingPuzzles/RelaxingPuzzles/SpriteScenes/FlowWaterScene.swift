//
//  FlowWaterScene.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//

import SpriteKit

final class FlowWaterScene: BasePuzzleScene {

    private struct Bar {
        let node: SKNode
        let rects: [CGRect]      // sahne koordinatında (x kayması node.position.x ile eklenir)
    }

    private var bars: [Bar] = []
    private var path = CGMutablePath()
    private var pathNode: SKShapeNode!
    private var inkBar: SKShapeNode!
    private var endDot: SKShapeNode!

    private var startPoint = CGPoint.zero
    private var endPoint = CGPoint.zero
    private var lastPoint = CGPoint.zero

    private var inkUsed: CGFloat = 0
    private var maxInk: CGFloat = 0
    private var drawing = false
    private var completed = false

    override func didMove(to view: SKView) {
        backgroundColor = .systemBackground
        let w = size.width, h = size.height

        let barCount = min(8, 2 + tier / 3)
        let gapW = lerp(170, 66)
        let thick: CGFloat = 20
        let amp: CGFloat = tier >= 8 ? 20 + CGFloat(tier - 8) * 2.5 : 0

        startPoint = CGPoint(x: CGFloat.random(in: (w * 0.15)...(w * 0.85), using: &rng), y: h * 0.86)
        endPoint = CGPoint(x: CGFloat.random(in: (w * 0.15)...(w * 0.85), using: &rng), y: h * 0.12)

        let topY = h * 0.72, bottomY = h * 0.26
        let step = (topY - bottomY) / CGFloat(max(1, barCount - 1))
        let margin = gapW / 2 + 20 + amp

        var route: [CGPoint] = [startPoint]
        var prevX = startPoint.x
        var barNodes: [SKNode] = []

        for i in 0..<barCount {
            let y = barCount == 1 ? (topY + bottomY) / 2 : topY - CGFloat(i) * step

            var gx = CGFloat.random(in: margin...(w - margin), using: &rng)
            for _ in 0..<20 {
                if abs(gx - prevX) > w * 0.3 { break }
                gx = CGFloat.random(in: margin...(w - margin), using: &rng)
            }
            prevX = gx
            route.append(CGPoint(x: gx, y: y))

            let gl = gx - gapW / 2, gr = gx + gapW / 2
            let left = CGRect(x: -200, y: -thick / 2, width: gl + 200, height: thick)
            let right = CGRect(x: gr, y: -thick / 2, width: (w + 200) - gr, height: thick)

            let container = SKNode()
            container.position = CGPoint(x: 0, y: y)
            for r in [left, right] {
                let n = SKShapeNode(rect: r, cornerRadius: thick / 2)
                n.fillColor = .systemGray5
                n.strokeColor = .clear
                container.addChild(n)
            }
            addChild(container)
            barNodes.append(container)
            bars.append(Bar(node: container, rects: [left, right].map { $0.offsetBy(dx: 0, dy: y) }))
        }
        route.append(endPoint)

        // Hareketli duvarlar
        if amp > 0 {
            let movingCount = max(1, Int(CGFloat(barCount) * lerp(0.3, 0.9)))
            let period = Double(lerp(3.2, 1.8))
            for node in barNodes.shuffled(using: &rng).prefix(movingCount) {
                let dir: CGFloat = Bool.random(using: &rng) ? 1 : -1
                let a = SKAction.moveBy(x: amp * dir, y: 0, duration: period / 2)
                let b = SKAction.moveBy(x: -2 * amp * dir, y: 0, duration: period)
                let c = SKAction.moveBy(x: amp * dir, y: 0, duration: period / 2)
                [a, b, c].forEach { $0.timingMode = .easeInEaseOut }
                node.run(.sequence([
                    .wait(forDuration: Double.random(in: 0...period, using: &rng)),
                    .repeatForever(.sequence([a, b, c]))
                ]))
            }
        }

        // Mürekkep limiti
        var minLen: CGFloat = 0
        for i in 1..<route.count {
            minLen += hypot(route[i].x - route[i - 1].x, route[i].y - route[i - 1].y)
        }
        maxInk = minLen * lerp(1.75, 1.3)

        // Çizim
        pathNode = SKShapeNode()
        pathNode.strokeColor = .systemTeal
        pathNode.lineWidth = 8
        pathNode.lineCap = .round
        pathNode.lineJoin = .round
        pathNode.zPosition = 1
        addChild(pathNode)

        let startDot = SKShapeNode(circleOfRadius: 14)
        startDot.fillColor = .systemTeal
        startDot.strokeColor = .clear
        startDot.position = startPoint
        startDot.zPosition = 2
        addChild(startDot)

        endDot = SKShapeNode(circleOfRadius: 16)
        endDot.fillColor = .systemBlue
        endDot.strokeColor = .systemTeal
        endDot.lineWidth = 3
        endDot.position = endPoint
        endDot.zPosition = 2
        addChild(endDot)

        // Mürekkep barı
        let barW = w * 0.6
        let track = SKShapeNode(rect: CGRect(x: -barW / 2, y: -3, width: barW, height: 6), cornerRadius: 3)
        track.fillColor = .systemGray5
        track.strokeColor = .clear
        track.position = CGPoint(x: w / 2, y: h - 70)
        addChild(track)

        inkBar = SKShapeNode(rect: CGRect(x: 0, y: -3, width: barW, height: 6), cornerRadius: 3)
        inkBar.fillColor = .systemTeal
        inkBar.strokeColor = .clear
        inkBar.position = CGPoint(x: w / 2 - barW / 2, y: h - 70)
        inkBar.zPosition = 1
        addChild(inkBar)
    }

    // MARK: - Yardımcılar

    private func isBlocked(_ p: CGPoint) -> Bool {
        for bar in bars {
            let dx = bar.node.position.x
            for r in bar.rects where r.offsetBy(dx: dx, dy: 0).insetBy(dx: -5, dy: -5).contains(p) {
                return true
            }
        }
        return false
    }

    private func updateBar() {
        let ratio = min(1, inkUsed / maxInk)
        inkBar.xScale = max(0.001, 1 - ratio)
        inkBar.fillColor = ratio > 0.85 ? .systemOrange : .systemTeal
    }

    private func resetInk() {
        path = CGMutablePath()
        pathNode.path = nil
        inkUsed = 0
        updateBar()
    }

    private func fail() {
        drawing = false
        haptic(.soft)
        pathNode.run(.sequence([
            .fadeOut(withDuration: 0.3),
            .run { [weak self] in self?.resetInk() },
            .fadeIn(withDuration: 0)
        ]))
    }

    private func succeed() {
        completed = true
        drawing = false
        haptic(.medium)
        endDot.run(.sequence([
            .scale(to: 1.5, duration: 0.15),
            .scale(to: 1.0, duration: 0.15),
            .run { [weak self] in self?.completePuzzle() }
        ]))
    }

    // MARK: - Dokunma

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !completed, !drawing, !pathNode.hasActions(),
              let touch = touches.first else { return }
        let loc = touch.location(in: self)
        guard hypot(loc.x - startPoint.x, loc.y - startPoint.y) < 50 else { return }

        resetInk()
        path.move(to: startPoint)
        lastPoint = startPoint
        drawing = true
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard drawing, !completed, let touch = touches.first else { return }
        let loc = touch.location(in: self)

        let dx = loc.x - lastPoint.x
        let dy = loc.y - lastPoint.y
        let dist = hypot(dx, dy)
        guard dist > 0 else { return }

        let steps = max(1, Int(dist / 6))
        let stepLen = dist / CGFloat(steps)

        for i in 1...steps {
            let f = CGFloat(i) / CGFloat(steps)
            let p = CGPoint(x: lastPoint.x + dx * f, y: lastPoint.y + dy * f)

            if isBlocked(p) { fail(); return }

            inkUsed += stepLen
            if inkUsed > maxInk { fail(); return }

            path.addLine(to: p)

            if hypot(p.x - endPoint.x, p.y - endPoint.y) < 26 {
                pathNode.path = path
                updateBar()
                succeed()
                return
            }
        }

        lastPoint = loc
        pathNode.path = path
        updateBar()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if drawing && !completed { fail() }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if drawing && !completed { fail() }
    }
}

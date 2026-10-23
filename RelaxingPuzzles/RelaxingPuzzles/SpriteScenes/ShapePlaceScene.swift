//
//  ShapePlacesScene.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//

import SpriteKit

private enum ShapeKind: CaseIterable {
    case triangle, rectangle, lShape, jShape, tShape, zShape, sShape, plus

    var path: CGPath {
        let p = CGMutablePath()
        switch self {
        case .triangle:
            p.move(to: CGPoint(x: -40, y: -30))
            p.addLine(to: CGPoint(x: 40, y: -30))
            p.addLine(to: CGPoint(x: 0, y: 40))
            p.closeSubpath()
        case .rectangle:
            p.addRoundedRect(in: CGRect(x: -50, y: -25, width: 100, height: 50),
                             cornerWidth: 6, cornerHeight: 6)
        case .lShape:
            p.move(to: CGPoint(x: -35, y: -35))
            p.addLine(to: CGPoint(x: 35, y: -35))
            p.addLine(to: CGPoint(x: 35, y: -10))
            p.addLine(to: CGPoint(x: -10, y: -10))
            p.addLine(to: CGPoint(x: -10, y: 35))
            p.addLine(to: CGPoint(x: -35, y: 35))
            p.closeSubpath()
        case .jShape:
            var t = CGAffineTransform(scaleX: -1, y: 1)
            return ShapeKind.lShape.path.copy(using: &t) ?? ShapeKind.lShape.path
        case .tShape:
            p.move(to: CGPoint(x: -40, y: 35))
            p.addLine(to: CGPoint(x: 40, y: 35))
            p.addLine(to: CGPoint(x: 40, y: 10))
            p.addLine(to: CGPoint(x: 15, y: 10))
            p.addLine(to: CGPoint(x: 15, y: -35))
            p.addLine(to: CGPoint(x: -15, y: -35))
            p.addLine(to: CGPoint(x: -15, y: 10))
            p.addLine(to: CGPoint(x: -40, y: 10))
            p.closeSubpath()
        case .zShape:
            p.move(to: CGPoint(x: -45, y: 35))
            p.addLine(to: CGPoint(x: 5, y: 35))
            p.addLine(to: CGPoint(x: 5, y: 5))
            p.addLine(to: CGPoint(x: 45, y: 5))
            p.addLine(to: CGPoint(x: 45, y: -35))
            p.addLine(to: CGPoint(x: -5, y: -35))
            p.addLine(to: CGPoint(x: -5, y: -5))
            p.addLine(to: CGPoint(x: -45, y: -5))
            p.closeSubpath()
        case .sShape:
            var t = CGAffineTransform(scaleX: -1, y: 1)
            return ShapeKind.zShape.path.copy(using: &t) ?? ShapeKind.zShape.path
        case .plus:
            let pts: [(CGFloat, CGFloat)] = [
                (-15, 40), (15, 40), (15, 15), (40, 15), (40, -15), (15, -15),
                (15, -40), (-15, -40), (-15, -15), (-40, -15), (-40, 15), (-15, 15)
            ]
            p.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
            for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
            p.closeSubpath()
        }
        return p
    }

    /// Kaç çeyrek dönüşte kendine benziyor
    var symmetry: Int {
        switch self {
        case .rectangle, .zShape, .sShape: return 2
        case .plus: return 1
        default: return 4
        }
    }

    var color: UIColor {
        switch self {
        case .triangle:  return .systemOrange
        case .rectangle: return .systemBlue
        case .lShape:    return .systemPink
        case .jShape:    return .systemPurple
        case .tShape:    return .systemGreen
        case .zShape:    return .systemTeal
        case .sShape:    return .systemIndigo
        case .plus:      return .systemYellow
        }
    }
}

private final class Piece: SKShapeNode {
    var kind: ShapeKind = .triangle
    var quarter = 0
    var locked = false
}

final class ShapePlaceScene: BasePuzzleScene {

    private var targets: [Piece] = []
    private var pieces: [Piece] = []
    private var pieceScale: CGFloat = 1

    private var selected: Piece?
    private var grabOffset = CGPoint.zero
    private var startLocation = CGPoint.zero
    private var moved = false
    private var placedCount = 0

    private func availableKinds() -> [ShapeKind] {
        if tier < 4  { return [.triangle, .rectangle, .lShape, .tShape] }
        if tier < 10 { return [.triangle, .rectangle, .lShape, .tShape, .plus, .zShape] }
        return ShapeKind.allCases   // J ve S ayna görüntüleri devreye girer
    }

    private func makePiece(kind: ShapeKind) -> Piece {
        let p = Piece()
        p.kind = kind
        p.path = kind.path
        p.setScale(pieceScale)
        return p
    }

    override func didMove(to view: SKView) {
        backgroundColor = .systemBackground

        let avail = availableKinds()
        let count = min(avail.count, 2 + tier / 4)            // 2...8
        let kinds = Array(avail.shuffled(using: &rng).prefix(count))

        pieceScale = count > 6 ? 0.85 : 1.0
        let cols = count <= 4 ? 2 : 3
        let colW = size.width / CGFloat(cols)
        let rowH: CGFloat = 100 * pieceScale

        func position(_ i: Int, topY: CGFloat) -> CGPoint {
            CGPoint(x: colW * (CGFloat(i % cols) + 0.5),
                    y: topY - CGFloat(i / cols) * rowH)
        }

        let targetAlpha = lerp(1.0, 0.45)

        // Hedefler
        for (i, kind) in kinds.enumerated() {
            let t = makePiece(kind: kind)
            t.fillColor = .clear
            t.strokeColor = .systemGray2
            t.alpha = targetAlpha
            t.lineWidth = 3
            if kind.symmetry > 1 {
                let range = tier < 8 ? 1..<kind.symmetry : 0..<kind.symmetry
                t.quarter = Int.random(in: range, using: &rng)
            }
            t.zRotation = CGFloat(t.quarter) * .pi / 2
            t.position = position(i, topY: size.height * 0.86)
            addChild(t)
            targets.append(t)
        }

        // Parçalar (karışık sırada)
        for (i, kind) in kinds.shuffled(using: &rng).enumerated() {
            let p = makePiece(kind: kind)
            p.fillColor = kind.color
            p.strokeColor = .clear
            if tier >= 5 {
                p.quarter = Int.random(in: 0..<4, using: &rng)
                p.zRotation = CGFloat(p.quarter) * .pi / 2
            }
            p.position = position(i, topY: size.height * 0.36)
            p.zPosition = 1
            addChild(p)
            pieces.append(p)
        }
    }

    // MARK: - Dokunma

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)

        selected = pieces
            .filter { !$0.locked && hypot($0.position.x - loc.x, $0.position.y - loc.y) < 60 * pieceScale }
            .min { hypot($0.position.x - loc.x, $0.position.y - loc.y)
                 < hypot($1.position.x - loc.x, $1.position.y - loc.y) }

        guard let p = selected else { return }
        grabOffset = CGPoint(x: p.position.x - loc.x, y: p.position.y - loc.y)
        startLocation = loc
        moved = false
        p.zPosition = 5
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = selected, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        if hypot(loc.x - startLocation.x, loc.y - startLocation.y) > 10 { moved = true }
        if moved {
            p.position = CGPoint(x: loc.x + grabOffset.x, y: loc.y + grabOffset.y)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = selected else { return }
        selected = nil
        p.zPosition = 1

        if !moved {
            p.quarter = (p.quarter + 1) % 4
            p.run(.rotate(byAngle: .pi / 2, duration: 0.15))
            haptic(.light)
            return
        }

        let snap = lerp(60, 40) * pieceScale
        for t in targets where !t.locked && t.kind == p.kind {
            let d = hypot(p.position.x - t.position.x, p.position.y - t.position.y)
            guard d < snap else { continue }

            let diff = ((p.quarter - t.quarter) % 4 + 4) % 4
            if diff % p.kind.symmetry == 0 {
                lock(p, into: t)
            } else {
                shake(p)
                haptic(.soft)
            }
            break
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        selected?.zPosition = 1
        selected = nil
    }

    private func lock(_ p: Piece, into t: Piece) {
        p.locked = true
        t.locked = true
        placedCount += 1
        haptic(.medium)

        p.run(.sequence([
            .move(to: t.position, duration: 0.12),
            .scale(to: pieceScale * 1.1, duration: 0.1),
            .scale(to: pieceScale, duration: 0.1)
        ]))

        if placedCount == targets.count {
            run(.sequence([
                .wait(forDuration: 0.5),
                .run { [weak self] in self?.completePuzzle() }
            ]))
        }
    }
}

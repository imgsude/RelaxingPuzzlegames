//
//  BalanceScene.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//
import SpriteKit

final class BalanceScene: BasePuzzleScene {

    private let half = 4                       // slotlar: -4...4
    private var beamWidth: CGFloat = 340
    private var slotW: CGFloat { beamWidth / 9 }
    private let beamH: CGFloat = 14

    private var beam: SKShapeNode!
    private var dragging: SKShapeNode?
    private var homes: [ObjectIdentifier: CGPoint] = [:]
    private var fixedBlocks: [(w: Int, slot: Int)] = []
    private var movable: [Int] = []
    private var completed = false

    private let palette: [UIColor] = [.systemTeal, .systemOrange, .systemPink,
                                      .systemPurple, .systemYellow, .systemRed]

    private func blockHeight(_ w: Int) -> CGFloat { 18 + CGFloat(w) * 7 }
    private func slotOf(_ n: SKNode) -> Int? { n.userData?["slot"] as? Int }
    private func weightOf(_ n: SKNode) -> Int { n.userData?["weight"] as? Int ?? 0 }

    // MARK: - Level üretimi (çözülebilirlik garantili)

    private func countSolutions(fixed: [(w: Int, slot: Int)], mov: [Int], limit: Int) -> Int {
        var used = Set(fixed.map { $0.slot })
        let base = fixed.reduce(0) { $0 + $1.w * $1.slot }
        var count = 0
        func dfs(_ i: Int, _ torque: Int) {
            if count >= limit { return }
            if i == mov.count {
                if torque == 0 { count += 1 }
                return
            }
            for s in -4...4 where !used.contains(s) {
                used.insert(s)
                dfs(i + 1, torque + mov[i] * s)
                used.remove(s)
            }
        }
        dfs(0, base)
        return count
    }

    private func generate() {
        let fixedCount = tier < 6 ? 1 : (tier < 14 ? 2 : 3)
        let movCount = min(5, 2 + tier / 6)
        let maxW = min(6, 3 + tier / 8)
        let cap = Int(lerp(120, 3))          // ileride çözüm sayısı azalır → zorlaşır

        var best: (fixed: [(w: Int, slot: Int)], mov: [Int])?
        for _ in 0..<400 {
            var slots = Array(-4...4).shuffled(using: &rng)
            let fixed = (0..<fixedCount).map { _ in
                (w: Int.random(in: 1...maxW, using: &rng), slot: slots.removeFirst())
            }
            let mov = (0..<movCount).map { _ in Int.random(in: 1...maxW, using: &rng) }
            let n = countSolutions(fixed: fixed, mov: mov, limit: cap + 1)
            if n >= 1 {
                best = (fixed, mov)
                if n <= cap { break }
            }
        }
        let result = best ?? (fixed: [(w: 2, slot: -2)], mov: [1, 2])
        fixedBlocks = result.fixed
        movable = result.mov
    }

    // MARK: - Kurulum

    private func makeBlock(weight: Int, color: UIColor) -> SKShapeNode {
        let b = SKShapeNode(rectOf: CGSize(width: slotW - 6, height: blockHeight(weight)), cornerRadius: 8)
        b.fillColor = color
        b.strokeColor = .clear
        b.userData = ["weight": weight]

        let label = SKLabelNode(text: "\(weight)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        b.addChild(label)
        return b
    }

    override func didMove(to view: SKView) {
        backgroundColor = .systemBackground
        beamWidth = min(size.width - 30, 400)
        generate()

        let pivot = CGPoint(x: size.width / 2, y: size.height * 0.55)

        let tri = CGMutablePath()
        tri.move(to: CGPoint(x: -34, y: -70))
        tri.addLine(to: CGPoint(x: 34, y: -70))
        tri.addLine(to: .zero)
        tri.closeSubpath()
        let stand = SKShapeNode(path: tri)
        stand.fillColor = .systemGray3
        stand.strokeColor = .clear
        stand.position = pivot
        addChild(stand)

        beam = SKShapeNode(rectOf: CGSize(width: beamWidth, height: beamH), cornerRadius: 7)
        beam.position = pivot
        beam.fillColor = .systemGray
        beam.strokeColor = .clear
        beam.zPosition = 1
        addChild(beam)

        // Slot işaretleri
        for s in -half...half {
            let tick = SKShapeNode(rectOf: CGSize(width: 2, height: 8))
            tick.fillColor = .systemGray2
            tick.strokeColor = .clear
            tick.position = CGPoint(x: CGFloat(s) * slotW, y: -beamH / 2 - 6)
            beam.addChild(tick)
        }

        // Sabit ağırlıklar
        for f in fixedBlocks {
            let b = makeBlock(weight: f.w, color: .systemIndigo)
            b.name = "fixed"
            b.userData?["slot"] = f.slot
            b.position = CGPoint(x: CGFloat(f.slot) * slotW, y: beamH / 2 + blockHeight(f.w) / 2)
            beam.addChild(b)
        }

        // Sürüklenebilir bloklar
        for (i, w) in movable.enumerated() {
            let b = makeBlock(weight: w, color: palette[(w - 1) % palette.count])
            b.name = "block"
            let home = CGPoint(x: size.width * CGFloat(i + 1) / CGFloat(movable.count + 1),
                               y: size.height * 0.2)
            b.position = home
            b.zPosition = 2
            homes[ObjectIdentifier(b)] = home
            addChild(b)
        }
    }

    // MARK: - Dokunma

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !completed, let touch = touches.first else { return }
        let loc = touch.location(in: self)

        let hit = nodes(at: loc).compactMap { n -> SKShapeNode? in
            if n.name == "block" { return n as? SKShapeNode }
            if n.parent?.name == "block" { return n.parent as? SKShapeNode }
            return nil
        }.first
        guard let block = hit else { return }

        block.removeAllActions()
        if block.parent === beam {
            block.userData?.removeObject(forKey: "slot")
            block.move(toParent: self)
            block.zRotation = 0
        }
        block.zPosition = 10
        block.setScale(1.08)
        dragging = block
        updateBeam()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let block = dragging, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        block.position = CGPoint(x: loc.x, y: loc.y + 40)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let block = dragging else { return }
        dragging = nil
        block.setScale(1)
        block.zPosition = 2

        let w = weightOf(block)
        let local = convert(block.position, to: beam)
        let slot = Int((local.x / slotW).rounded())
        let targetY = beamH / 2 + blockHeight(w) / 2
        let occupied = Set(beam.children.compactMap { slotOf($0) })

        if abs(slot) <= half && abs(local.y - targetY) < 90 && !occupied.contains(slot) {
            block.move(toParent: beam)
            block.zRotation = 0
            block.userData?["slot"] = slot
            block.run(.move(to: CGPoint(x: CGFloat(slot) * slotW, y: targetY), duration: 0.1))
            haptic(.light)
        } else {
            if abs(slot) <= half && occupied.contains(slot) { haptic(.soft) }
            if let home = homes[ObjectIdentifier(block)] {
                block.run(.move(to: home, duration: 0.3))
            }
        }
        updateBeam()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Tork

    private func updateBeam() {
        var torque = 0
        var placedMovable = 0
        for n in beam.children {
            guard let s = slotOf(n) else { continue }
            torque += weightOf(n) * s
            if n.name == "block" { placedMovable += 1 }
        }

        // Son basamaklarda eğimin miktarı gizlenir, sadece yönü görünür
        let hideMagnitude = tier >= 16
        let angle: CGFloat = hideMagnitude
            ? -CGFloat(torque.signum()) * 0.1
            : max(-0.3, min(0.3, -CGFloat(torque) * 0.015))

        beam.removeAction(forKey: "tilt")
        beam.run(.rotate(toAngle: angle, duration: 0.5), withKey: "tilt")

        let balanced = placedMovable == movable.count && torque == 0
        beam.removeAction(forKey: "hold")
        beam.fillColor = balanced ? .systemGreen : .systemGray

        if balanced {
            beam.run(.sequence([
                .wait(forDuration: 0.8),
                .run { [weak self] in self?.finish() }
            ]), withKey: "hold")
        }
    }

    private func finish() {
        guard !completed else { return }
        completed = true
        haptic(.medium)
        completePuzzle()
    }
}

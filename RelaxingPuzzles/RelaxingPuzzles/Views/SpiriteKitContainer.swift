//
//  SpiritKitContainer.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//import SwiftUI
import SpriteKit
import SwiftUI

struct SpriteKitContainer: UIViewRepresentable {
    var scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}
}

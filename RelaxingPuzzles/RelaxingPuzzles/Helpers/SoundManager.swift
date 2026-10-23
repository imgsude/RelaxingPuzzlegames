//
//  SoundManager.swift
//  RelaxingPuzzles
//
//  Created by gulsum sude korkmaz on 5.02.2026.
//

import AVFoundation

final class SoundManager {

    static let shared = SoundManager()
    private var player: AVAudioPlayer?

    func play(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}

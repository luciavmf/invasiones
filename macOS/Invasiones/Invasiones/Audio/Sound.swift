//
//  Sound.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Sonido.cs — playback of sound effects and background music.
//  SDL_mixer replaced by AVFoundation.
//

import AVFoundation
import Foundation

class Sound {

    // MARK: - Singleton
    static let shared = Sound()

    // MARK: - Declarations
    private var sfxPlayers: [AVAudioPlayer?] = Array(repeating: nil, count: Res.SFX_COUNT)
    private var musicPlayer: AVAudioPlayer?
    private var currentMusic: Int = -1
#if DEBUG
    private(set) var isMuted = true
#else
    private(set) var isMuted = false
#endif

    private init() { }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        let volume: Float = muted ? 0 : 1
        sfxPlayers.compactMap { $0 }.forEach { $0.volume = volume }
        musicPlayer?.volume = volume
    }

    // MARK: - Methods

    func loadAllSounds() {
        let paths = ResourceManager.shared.soundPaths

        // First Res.SND_COUNT entries are background music (= 0 in this game).
        // Next Res.SFX_COUNT entries are sound effects.
        for i in 0..<Res.SFX_COUNT {
            let pathIdx = Res.SND_COUNT + i
            guard pathIdx < paths.count, let path = paths[pathIdx] else { continue }
            do {
                let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                player.prepareToPlay()
                player.volume = isMuted ? 0 : 1
                sfxPlayers[i] = player
            } catch {
                Log.shared.error("Sound: failed to load \(path): \(error)")
            }
        }
    }

    @discardableResult
    func play(id: Int, loop: Int) -> Bool {
        guard id >= 0, id < Res.SND_COUNT + Res.SFX_COUNT else {
            Log.shared.warn("Sound: cannot play \(id): not found.")
            return false
        }

        if id >= Res.SND_COUNT {
            let idx = id - Res.SND_COUNT
            guard let player = sfxPlayers[idx] else { return false }
            if player.isPlaying { return false }
            player.volume = isMuted ? 0 : 1
            player.numberOfLoops = loop < -1 ? 0 : loop
            player.play()
        }
        // No background music (SND_COUNT = 0).
        return true
    }

    func stop(_ id: Int) {
        guard id >= -1, id < Res.SND_COUNT + Res.SFX_COUNT else { return }
        if id == -1 {
            sfxPlayers.compactMap { $0 }.forEach {
                $0.stop()
                $0.currentTime = 0
            }
            musicPlayer?.stop()
            musicPlayer?.currentTime = 0
            currentMusic = -1
            return
        }

        if id >= Res.SND_COUNT {
            let p = sfxPlayers[id - Res.SND_COUNT]
            p?.stop()
            p?.currentTime = 0
        } else {
            musicPlayer?.stop()
            musicPlayer?.currentTime = 0
            currentMusic = -1
        }
    }

}

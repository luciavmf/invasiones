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

    private init() {}

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
                sfxPlayers[i] = player
            } catch {
                Log.shared.error("No se pudo load el sonido \(path): \(error)")
            }
        }
    }

    @discardableResult
    func play(_ id: Int, _ loop: Int) -> Bool {
        guard id >= 0, id < Res.SND_COUNT + Res.SFX_COUNT else {
            Log.shared.warn("No se puede play el sonido \(id): no existe.")
            return false
        }

        if id >= Res.SND_COUNT {
            let idx = id - Res.SND_COUNT
            guard let player = sfxPlayers[idx] else { return false }
            if player.isPlaying { return false }
            player.numberOfLoops = loop < -1 ? 0 : loop
            player.play()
        }
        // No background music (SND_COUNT = 0).
        return true
    }

    func stop(_ id: Int) {
        guard id >= -1, id < Res.SND_COUNT + Res.SFX_COUNT else { return }
        if id == -1 {
            sfxPlayers.compactMap { $0 }.forEach { $0.stop(); $0.currentTime = 0 }
            musicPlayer?.stop(); musicPlayer?.currentTime = 0; currentMusic = -1
            return
        }
        if id >= Res.SND_COUNT {
            let p = sfxPlayers[id - Res.SND_COUNT]
            p?.stop(); p?.currentTime = 0
        } else {
            musicPlayer?.stop(); musicPlayer?.currentTime = 0; currentMusic = -1
        }
    }

    func pause(_ id: Int) {
        if id == -1 {
            sfxPlayers.compactMap { $0 }.forEach { $0.pause() }
            musicPlayer?.pause(); return
        }
        if id >= Res.SND_COUNT { sfxPlayers[id - Res.SND_COUNT]?.pause() }
        else { musicPlayer?.pause() }
    }

    func resume(_ id: Int) {
        if id == -1 {
            sfxPlayers.compactMap { $0 }.forEach { $0.play() }
            musicPlayer?.play(); return
        }
        if id >= Res.SND_COUNT { sfxPlayers[id - Res.SND_COUNT]?.play() }
        else { musicPlayer?.play() }
    }

    func stopBackgroundMusic() {
        musicPlayer?.stop(); currentMusic = -1
    }

    func setVolume(_ id: Int, _ volume: Int) {
        let v = Float(max(0, min(volume, 128))) / 128.0
        if id == -1 {
            sfxPlayers.compactMap { $0 }.forEach { $0.volume = v }
            musicPlayer?.volume = v
        } else if id >= Res.SND_COUNT {
            sfxPlayers[id - Res.SND_COUNT]?.volume = v
        } else {
            musicPlayer?.volume = v
        }
    }
}

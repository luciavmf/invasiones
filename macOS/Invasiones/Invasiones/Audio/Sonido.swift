// Audio/Sonido.swift
// Puerto de Sonido.cs — reproducción de efectos especiales y música de fondo.
// SDL_mixer reemplazado por AVFoundation.

import AVFoundation
import Foundation

class Sonido {

    // MARK: - Singleton
    private static var s_instancia: Sonido?

    static var Instancia: Sonido {
        if s_instancia == nil { s_instancia = Sonido() }
        return s_instancia!
    }

    // MARK: - Declaraciones
    private var m_sfxPlayers: [AVAudioPlayer?] = Array(repeating: nil, count: Res.SFX_COUNT)
    private var m_musicPlayer: AVAudioPlayer?
    private var m_musicActual: Int = -1

    private init() {}

    // MARK: - Métodos

    func inicializar() {
        // AVFoundation no requiere inicialización explícita.
    }

    func cargarTodosLosSonidos() {
        let paths = AdministradorDeRecursos.Instancia.pathsSonidos

        // Primeros Res.SND_COUNT son música de fondo (= 0 en este juego).
        // Siguientes Res.SFX_COUNT son efectos especiales.
        for i in 0..<Res.SFX_COUNT {
            let pathIdx = Res.SND_COUNT + i
            guard pathIdx < paths.count, let path = paths[pathIdx] else { continue }
            do {
                let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                player.prepareToPlay()
                m_sfxPlayers[i] = player
            } catch {
                Log.Instancia.error("No se pudo cargar el sonido \(path): \(error)")
            }
        }
    }

    @discardableResult
    func reproducir(_ id: Int, _ loop: Int) -> Bool {
        guard id >= 0, id < Res.SND_COUNT + Res.SFX_COUNT else {
            Log.Instancia.advertir("No se puede reproducir el sonido \(id): no existe.")
            return false
        }

        if id >= Res.SND_COUNT {
            let idx = id - Res.SND_COUNT
            guard let player = m_sfxPlayers[idx] else { return false }
            if player.isPlaying { return false }
            player.numberOfLoops = loop < -1 ? 0 : loop
            player.play()
        }
        // Sin música de fondo (SND_COUNT = 0).
        return true
    }

    func parar(_ id: Int) {
        guard id >= -1, id < Res.SND_COUNT + Res.SFX_COUNT else { return }
        if id == -1 {
            m_sfxPlayers.compactMap { $0 }.forEach { $0.stop() }
            m_musicPlayer?.stop(); m_musicActual = -1
            return
        }
        if id >= Res.SND_COUNT {
            m_sfxPlayers[id - Res.SND_COUNT]?.stop()
        } else {
            m_musicPlayer?.stop(); m_musicActual = -1
        }
    }

    func pausar(_ id: Int) {
        if id == -1 {
            m_sfxPlayers.compactMap { $0 }.forEach { $0.pause() }
            m_musicPlayer?.pause(); return
        }
        if id >= Res.SND_COUNT { m_sfxPlayers[id - Res.SND_COUNT]?.pause() }
        else { m_musicPlayer?.pause() }
    }

    func reanudar(_ id: Int) {
        if id == -1 {
            m_sfxPlayers.compactMap { $0 }.forEach { $0.play() }
            m_musicPlayer?.play(); return
        }
        if id >= Res.SND_COUNT { m_sfxPlayers[id - Res.SND_COUNT]?.play() }
        else { m_musicPlayer?.play() }
    }

    func pararMusicaDeFondo() {
        m_musicPlayer?.stop(); m_musicActual = -1
    }

    func setearVolumen(_ id: Int, _ volume: Int) {
        let v = Float(max(0, min(volume, 128))) / 128.0
        if id == -1 {
            m_sfxPlayers.compactMap { $0 }.forEach { $0.volume = v }
            m_musicPlayer?.volume = v
        } else if id >= Res.SND_COUNT {
            m_sfxPlayers[id - Res.SND_COUNT]?.volume = v
        } else {
            m_musicPlayer?.volume = v
        }
    }
}

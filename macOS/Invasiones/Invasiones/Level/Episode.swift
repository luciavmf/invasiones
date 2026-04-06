//
//  Episode.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Episodio.cs + Episode.EstadoCargando.cs + Episode.EstadoJugando.cs
//  + Episode.EstadoMostrarIntroduccion.cs — active game session.
//

import Foundation
internal import CoreGraphics

class Episode {

    // MARK: - Enums
    enum BANDO { case ENEMY, ARGENTINE }

    enum STATE: Int {
        case END = -1, LOADING, PLAYING, SHOW_INTRO, SHOW_OBJECTIVES, WON, LOST
    }

    // MARK: - Constants
    private static let COUNT_TO_ASK_RESTART = 50
    private static let OBJECTIVES_BOX_WIDTH             = 600
    private static let OBJECTIVES_BOX_HEIGHT              = 270
    private static let OBJECTIVES_BOX_BUTTON_Y    = 70

    // MARK: - Declarations
    private var m_button:        Button?
    private var m_acceptButton: Button?
    private var m_obstacles:   [Obstacle] = []
    private var m_currentLevel:  Level?
    private var m_levelIndex:     Int = 0
    private var m_objectsToDraw = ObjectTable([[]])
    private var m_camera:       Camera?
    private var m_objective:     Objective?
    private var m_enemy:      EnemyTeam?
    private var m_player:      ArgentineTeam?
    private var m_map:         Map?
    private var m_state:       STATE = .LOADING
    private var m_hud:          Hud?
    private var m_count:       Int = 0
    private var m_showObjectivePopup:        Bool = false
    private var m_showObjectiveReminder: Bool = false
    private var m_objectiveShowCount:       Int = 0
    private var m_currentPage:                Int = 0
    private var m_gameOverMenu: ConfirmationMenu

    // Cheats
    private var m_cheatGanarIndice:   Int = 0
    private var m_cheatPerderIndice:  Int = 0
    private var m_cheatObjetivoIndice:Int = 0

    // MARK: - Properties
    var state: STATE { m_state }

    // MARK: - Initializer
    init() {
        m_gameOverMenu = ConfirmationMenu(Res.STR_CONTINUARJUEGO, Res.STR_NO, Res.STR_SI)
        m_gameOverMenu.setPosition(0, 0, Surface.centerVertical | Surface.centerHorizontal)
    }

    deinit { dispose() }

    func dispose() {
        m_map = nil
    }

    // MARK: - Public control

    func start() {
        setState(.LOADING)
    }

    func save() -> Bool { false }

    func exit() {}

    // MARK: - Update

    @discardableResult
    func update() -> Bool {
        switch m_state {
        case .LOADING:              updateLoadingState()
        case .SHOW_INTRO:  updateShowIntroState()
        case .SHOW_OBJECTIVES:     updateShowObjectiveState()
        case .PLAYING:               updatePlayingState()
        case .WON:                  updateWonState()
        case .LOST:                updateLostState()
        case .END:                   break
        }
        return false
    }

    // MARK: - Draw

    func draw(_ g: Video) {
        switch m_state {
        case .LOADING:             drawLoadingState(g)
        case .SHOW_OBJECTIVES:    drawShowObjectiveState(g)
        case .PLAYING:              drawPlayingState(g)
        case .SHOW_INTRO: drawShowIntroState(g)
        case .WON:                 drawWonState(g)
        case .LOST:               drawLostState(g)
        case .END:                  break
        }
        g.setColor(Definitions.COLOR_WHITE)
    }

    // MARK: - LOADING state

    private func updateLoadingState() {
        if loadLevel(0) {
            updatePlayingState()
            setNewObjective()
            Sound.shared.stop(Res.SFX_SPLASH)
            Sound.shared.play(Res.SFX_BATALLA, -1)
            setState(.SHOW_INTRO)
        }
    }

    private func drawLoadingState(_ g: Video) {
        g.fillRect(0)
        g.setColor(Definitions.COLOR_TITLE)
        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                       Definitions.COLOR_TITLE)
        g.write(Res.STR_CARGANDO, 0, Definitions.LOADING_Y, Surface.centerHorizontal)
    }

    private func loadSprites() {
        let sprs = ResourceManager.shared.sprites
        if Res.SPR_PATRICIO < sprs.count { sprs[Res.SPR_PATRICIO]?.load() }
        if Res.SPR_INGLES   < sprs.count { sprs[Res.SPR_INGLES]?.load()   }
    }

    private func loadPaintObjects() -> Bool {
        guard let map = m_map else { return false }

        m_objectsToDraw.tabla = Array(repeating: Array(repeating: nil, count: map.physicalMapWidth),
                                       count: map.physicalMapHeight)
        m_obstacles = []

        for i in 0..<map.height {
            for j in 0..<map.width {
                let tileId = Int(map.obstaclesLayer[i][j])
                guard tileId != 0 else { continue }
                guard let ts = map.getTileset(tileId) else { continue }

                let localId = tileId - Int(ts.firstGid)
                let obs = Obstacle(index: localId, i: i * 2, j: j * 2, tileset: ts)
                m_obstacles.append(obs)

                let fi = i * 2, fj = j * 2
                if fi < m_objectsToDraw.tabla.count, fj < m_objectsToDraw.tabla[fi].count {
                    m_objectsToDraw.tabla[fi][fj] = obs
                }
            }
        }
        return true
    }

    private func loadLevel(_ levelIndex: Int) -> Bool {
        if m_count == 0 {
            m_levelIndex = levelIndex
            m_hud      = Hud()
            let hudAlto = m_hud?.height ?? 0
            m_camera   = Camera(x: 0, y: 0, height: Video.height - hudAlto)
            m_map     = Map(camera: m_camera!)

        } else if m_count == 1 {
            guard let map = m_map else { m_count += 1; return false }
            if !map.load(Res.MAP_NIVEL1 + m_levelIndex) { return false }

            MapObject.map   = map
            MapObject.camera = m_camera

            let level = Level()
            level.load(m_levelIndex)
            m_currentLevel = level

        } else if m_count == 2 {
            loadSprites()

        } else if m_count == 3 {
            m_button       = Button(label: Res.STR_SIGUIENTE, font: nil)
            m_acceptButton = Button(label: Res.STR_ACEPTAR, font: nil)
            ResourceManager.shared.loadUnitTypes()

        } else if m_count == 4 {
            if !loadPaintObjects() { return false }

        } else if m_count == 5 {
            guard let map = m_map, let camera = m_camera, let hud = m_hud else {
                m_count += 1; return false
            }
            m_player = ArgentineTeam(map: map, camera: camera,
                                       objectsToDraw: m_objectsToDraw, hud: hud)
            m_enemy = EnemyTeam(map: map, camera: camera,
                                     objectsToDraw: m_objectsToDraw, hud: hud)

        } else if m_count == 6 {
            if !(m_player?.loadUnits(m_levelIndex) ?? true) { return false }

        } else if m_count == 10 {
            if !(m_enemy?.loadUnits(m_levelIndex) ?? true) { return false }
            m_count += 1
            return true
        }

        m_count += 1
        return false
    }

    // MARK: - SHOW INTRODUCTION state

    private func updateShowIntroState() {
        if m_count == 0 {
            m_button?.setPosition(0, Definitions.OBJECTIVES_BUTTON_Y, Surface.centerHorizontal)
        }
        m_count += 1
        if m_button?.update() != 0 {
            m_currentPage += 1
            if m_currentPage == Definitions.PAGES_PER_INTRO - 1 {
                setState(.PLAYING)
            }
        }
    }

    private func setNewObjective() {
        Log.shared.debug("Le seteo un nuevo objetivo.........")
        m_showObjectivePopup = true
        let currentBattle = m_currentLevel?.currentBattleIndex ?? 0
        m_objective = m_currentLevel?.nextObjective()

        if (m_currentLevel?.currentBattleIndex ?? 0) != currentBattle {
            Log.shared.debug("Pase del nivelllllllll")
            setState(.SHOW_INTRO)
        }
        m_showObjectivePopup  = true
        m_objectiveShowCount = 0

        m_player?.setObjective(m_objective)

        if m_objective == nil {
            setState(.WON)
        }
    }

    private func drawShowIntroState(_ g: Video) {
        drawPlayingState(g)

        g.setColor(Definitions.COLOR_OBJECTIVES)
        let hudAlto = m_hud?.height ?? 0
        g.fillRect(0, -(hudAlto >> 1),
                           Video.width - (Definitions.OBJECTIVES_BORDER << 1),
                           Video.height  - (Definitions.OBJECTIVES_BORDER << 1) - hudAlto,
                           Definitions.OBJECTIVES_ALPHA,
                           Surface.centerVertical | Surface.centerHorizontal)

        if m_currentPage == 0 {
            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_OBJECTIVES_TITLE],
                           Definitions.GUI_COLOR_TEXT)
        } else {
            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_OBJECTIVES],
                           Definitions.GUI_COLOR_TEXT)
        }

        let strIdx = Res.STR_PRIMER_BATALLA + m_currentPage +
                     ((m_currentLevel?.currentBattleIndex ?? 0) * Definitions.PAGES_PER_INTRO)
        g.write(strIdx, 0, -(hudAlto >> 1), Surface.centerVertical | Surface.centerHorizontal)
        m_button?.draw(g)
    }

    // MARK: - SHOW OBJECTIVES state

    private func updateShowObjectiveState() {
        if m_count == 0 {
            m_acceptButton?.setPosition(0, Episode.OBJECTIVES_BOX_BUTTON_Y,
                                           Surface.centerHorizontal | Surface.centerVertical)
        }
        m_count += 1
        if m_acceptButton?.update() != 0 {
            m_currentPage += 1
            if m_currentPage == Definitions.PAGES_PER_INTRO {
                setState(.PLAYING)
                m_showObjectivePopup        = false
                m_showObjectiveReminder = true
            }
        }
    }

    private func drawShowObjectiveState(_ g: Video) {
        drawPlayingState(g)

        let hudAlto = m_hud?.height ?? 0
        g.setColor(Definitions.COLOR_OBJECTIVES)
        g.fillRect(0, -(hudAlto / 2),
                           Episode.OBJECTIVES_BOX_WIDTH, Episode.OBJECTIVES_BOX_HEIGHT,
                           Definitions.OBJECTIVES_ALPHA,
                           Surface.centerVertical | Surface.centerHorizontal)

        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                       Definitions.GUI_COLOR_TEXT)
        g.write(Res.STR_OBJETIVOS, 0,
                   -(hudAlto / 2) - Episode.OBJECTIVES_BOX_HEIGHT / 2 + 50,
                   Surface.centerVertical | Surface.centerHorizontal)

        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_OBJECTIVES],
                       Definitions.GUI_COLOR_TEXT)
        let strIdx = Res.STR_PRIMER_BATALLA + m_currentPage +
                     ((m_currentLevel?.currentBattleIndex ?? 0) * Definitions.PAGES_PER_INTRO)
        g.write(strIdx, 0, -(hudAlto >> 1) + 30, Surface.centerVertical | Surface.centerHorizontal)

        m_acceptButton?.draw(g)
    }

    // MARK: - PLAYING state

    private func updatePlayingState() {
        if m_showObjectivePopup { m_objectiveShowCount += 1 }

        if Definitions.CHEATS_ENABLED { checkCheats() }

        m_map?.update()

        // Reset visibility layer
        if let map = m_map {
            map.visibleTilesLayer = Array(repeating: Array(repeating: 0, count: map.physicalMapWidth),
                                           count: map.physicalMapHeight)
        }

        m_player?.update()
        m_enemy?.update()

        m_hud?.argentineCount = m_player?.unitCount ?? 0
        m_hud?.enemyCount   = m_enemy?.unitCount ?? 0

        checkGameOver()

        m_hud?.update()
        updateOrders()

        m_obstacles.forEach { $0.update() }
    }

    private func checkGameOver() {
        if (m_player?.unitCount ?? 1) == 0 {
            setState(.LOST)
        }
    }

    private func updateOrders() {
        if m_player?.completedObjective() == true {
            Log.shared.debug("Felicitaciones!! cumpliste el objetivo.....")
            setNewObjective()
        }
    }

    private func drawPlayingState(_ g: Video) {
        g.fillRect(Definitions.COLOR_BLACK)

        if let map = m_map { m_map?.drawLayer(g, map.TERRAIN_LAYER) }

        dibujarObjetos(g)

        drawSemiTransparentLayer(g)

        m_hud?.draw(g)

        m_player?.drawOrientationArrow(g)

        if m_showObjectivePopup &&
           m_objectiveShowCount > Definitions.OBJECTIVE_SHOW_START_COUNT {
            setState(.SHOW_OBJECTIVES)
        } else if m_showObjectiveReminder &&
                  m_objectiveShowCount > Definitions.OBJECTIVE_SHOW_START_COUNT {
            let hudAlto = m_hud?.height ?? 0
            let camAlto = m_camera?.height ?? Video.height
            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_OBJECTIVES_REMINDER],
                           Definitions.COLOR_OBJECTIVES_FONT)
            g.write(Res.STR_OBJETIVOS,
                       Definitions.OBJECTIVES_OFFSET << 1,
                       camAlto - (Definitions.OBJECTIVES_HEIGHT + Definitions.OBJECTIVES_OFFSET * 2) - 10, 0)
            let strIdx = Res.STR_OBJETIVO_BATALLA_1_1 + (m_currentLevel?.completedObjectiveCount ?? 0)
            g.write(strIdx,
                       Definitions.OBJECTIVES_OFFSET << 1,
                       camAlto - (Definitions.OBJECTIVES_HEIGHT + Definitions.OBJECTIVES_OFFSET * 2) + 5, 0)
            _ = hudAlto  // suppress warning
        }

        if Mouse.shared.isDragging() {
            g.setColor(Definitions.COLOR_GREEN)
            let r = Mouse.shared.dragRect
            g.drawRect(Int(r.minX), Int(r.minY), Int(r.width), Int(r.height), 0)
        }
    }

    private func drawSemiTransparentLayer(_ g: Video) {
        guard let map = m_map, let camera = m_camera, let player = m_player else { return }

        let oldClip = g.getClip()
        g.setClip(camera.startX, camera.startY, camera.width, camera.height)

        let rect = player.getPaintCoordinates()
        var XX   = rect.x
        var YY   = rect.y
        let endI = rect.w
        let endJ = rect.h

        var tileY = 0
        var toggle = true

        while tileY <= endJ {
            var tileX = 0
            var i = XX, j = YY
            while tileX <= endI && j >= 0 {
                if i >= 0 && i < map.physicalMapHeight && j < map.physicalMapWidth {
                    if map.visibleTilesLayer[i][j] == 0 {
                        map.drawSmallTile(g, i, j, true)
                    }
                }
                tileX += 1; i += 1; j -= 1
            }
            tileY += 1
            if toggle { XX += 1; toggle = false }
            else       { YY += 1; toggle = true  }
        }

        g.setClip(oldClip.x, oldClip.y, oldClip.w, oldClip.h)
    }

    private func dibujarObjetos(_ g: Video) {
        guard let map = m_map, let camera = m_camera, let player = m_player else { return }

        let oldClip = g.getClip()
        g.setClip(camera.startX, camera.startY, camera.width, camera.height)

        let rect = player.getPaintCoordinates()
        var XX   = rect.x
        var YY   = rect.y
        let endI = rect.w
        let endJ = rect.h

        var tileY = 0
        var toggle = true

        while tileY <= endJ {
            var tileX = 0
            var i = XX, j = YY
            while tileX <= endI && j >= 0 {
                if i >= 0 && i < map.physicalMapHeight && j < map.physicalMapWidth {
                    if let obj = m_objectsToDraw.tabla[i][j] {
                        if let uni = obj as? Unit  { uni.draw(g) }
                        if let obs = obj as? Obstacle { obs.draw(g) }
                    }
                }
                tileX += 1; i += 1; j -= 1
            }
            tileY += 1
            if toggle { XX += 1; toggle = false }
            else       { YY += 1; toggle = true  }
        }

        // Fueguitos del jugador se dibujan encima (delegado a ArgentineFaction via Player)
        // m_player.Dibujar(g) — in the original it drew fire effects; delegated if needed

        g.setClip(oldClip.x, oldClip.y, oldClip.w, oldClip.h)
    }

    // MARK: - WON state

    private func updateWonState() {
        if m_button?.update() != 0 {
            setState(.END)
        }
    }

    private func drawWonState(_ g: Video) {
        drawPlayingState(g)
        m_button?.draw(g)
        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_WIN],
                       Definitions.COLOR_WIN_TEXT)
        g.write(Res.STR_GANASTE, 0, 0, Surface.centerHorizontal | Surface.centerVertical)
    }

    // MARK: - LOST state

    private func updateLostState() {
        m_count += 1
        guard m_count > Episode.COUNT_TO_ASK_RESTART else { return }

        let result = m_gameOverMenu.update()
        if result == ConfirmationMenu.SELECCION.IZQUIERDO.rawValue {
            setState(.END)
        }
        if result == ConfirmationMenu.SELECCION.DERECHO.rawValue {
            setState(.LOADING)
        }
    }

    private func drawLostState(_ g: Video) {
        drawPlayingState(g)
        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_WIN],
                       Definitions.COLOR_WIN_TEXT)
        g.write(Res.STR_PERDISTE, 0, -100, Surface.centerHorizontal | Surface.centerVertical)
        if m_count > Episode.COUNT_TO_ASK_RESTART {
            m_gameOverMenu.draw(g)
        }
    }

    // MARK: - Cheats

    private func checkCheats() {
        let teclas = Keyboard.shared.pressedKeys

        if teclas.contains(Keyboard.KEY_G) && m_cheatGanarIndice == 0 {
            m_cheatGanarIndice += 1
        } else if teclas.contains(Keyboard.KEY_A) && m_cheatGanarIndice == 1 {
            m_cheatGanarIndice += 1
        } else if teclas.contains(Keyboard.KEY_N) && m_cheatGanarIndice == 2 {
            m_cheatGanarIndice += 1
        } else if teclas.contains(Keyboard.KEY_X) && m_cheatGanarIndice == 3 {
            m_cheatGanarIndice += 1
        } else if teclas.contains(Keyboard.KEY_W) && m_cheatGanarIndice == 4 {
            setState(.WON); m_cheatGanarIndice = 0
        } else if teclas.contains(Keyboard.KEY_P) && m_cheatPerderIndice == 0 {
            m_cheatPerderIndice += 1
        } else if teclas.contains(Keyboard.KEY_E) && m_cheatPerderIndice == 1 {
            m_cheatPerderIndice += 1
        } else if teclas.contains(Keyboard.KEY_R) && m_cheatPerderIndice == 2 {
            m_cheatPerderIndice += 1
        } else if teclas.contains(Keyboard.KEY_X) && m_cheatPerderIndice == 3 {
            m_cheatPerderIndice += 1
        } else if teclas.contains(Keyboard.KEY_W) && m_cheatPerderIndice == 4 {
            setState(.LOST); m_cheatPerderIndice = 0
        } else if teclas.contains(Keyboard.KEY_O) && m_cheatObjetivoIndice == 0 {
            m_cheatObjetivoIndice += 1
        } else if teclas.contains(Keyboard.KEY_B) && m_cheatObjetivoIndice == 1 {
            m_cheatObjetivoIndice += 1
        } else if teclas.contains(Keyboard.KEY_J) && m_cheatObjetivoIndice == 2 {
            m_cheatObjetivoIndice += 1
        } else if teclas.contains(Keyboard.KEY_X) && m_cheatObjetivoIndice == 3 {
            m_cheatObjetivoIndice += 1
        } else if teclas.contains(Keyboard.KEY_W) && m_cheatObjetivoIndice == 4 {
            setNewObjective(); m_cheatObjetivoIndice = 0
        } else if !teclas.isEmpty {
            if teclas.contains(Keyboard.KEY_U) { m_player?.selectNextUnit() }
            Log.shared.debug("Reseteo todos los cheats--")
            m_cheatObjetivoIndice = 0
            m_cheatGanarIndice    = 0
            m_cheatPerderIndice   = 0
        }
        Keyboard.shared.clearKeys()
    }

    // MARK: - Private

    private func setState(_ state: STATE) {
        m_count       = 0
        m_state = state
        m_currentPage = 0
        if state == .SHOW_OBJECTIVES { m_currentPage = 2 }
    }
}

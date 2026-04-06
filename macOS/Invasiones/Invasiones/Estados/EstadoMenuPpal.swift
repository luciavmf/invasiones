//
//  EstadoMenuPpal.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoMenuPpal.cs — main menu with entry animation.
//

import Foundation

class EstadoMenuPpal: Estado {

    // MARK: - Constants
    private let CUENTA_HASTA_MOSTRAR_MENU = 20
    private let INCREMENTO_MENU_Y         = 5

    // MARK: - Menu items
    private enum ITEM: Int {
        case NUEVO_JUEGO = 0
        case AYUDA       = 1
        case SALIR       = 2
    }

    // MARK: - Declarations
    private var m_itemSeleccionado:      Int = -1
    private var m_menu:                  Menu?
    private var m_menuPosicionDeseadaY:  Int = 0
    private var m_posicionY:             Int = 0
    private var m_primeraVezConstruido:  Bool = true

    // MARK: - Initializer
    override init(_ sm: MaquinaDeEstados) {
        super.init(sm)
        m_primeraVezConstruido = true
    }

    // MARK: - Methods

    override func iniciar() {
        m_fondo = AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_SPLASH)

        Mouse.Instancia.setearCursor(AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_CURSOR))
        Mouse.Instancia.mostrarCursor()

        let menu = Menu(imagen: nil,
                        cantItem: 3,
                        x: 0,
                        y: Video.Alto - Definiciones.MENU_PRINCIPAL_Y_OFFSET,
                        ancla: Superficie.H_CENTRO)

        menu.agregarItem(ITEM.NUEVO_JUEGO.rawValue, Res.STR_MENU_NUEVO_JUEGO, Menu.ITEM_VISIBLE)
        menu.agregarItem(ITEM.AYUDA.rawValue,       Res.STR_MENU_AYUDA,       Menu.ITEM_VISIBLE)
        menu.agregarItem(ITEM.SALIR.rawValue,       Res.STR_MENU_SALIR,       Menu.ITEM_VISIBLE)

        if m_primeraVezConstruido {
            m_primeraVezConstruido   = false
            m_menuPosicionDeseadaY   = Video.Alto - menu.alto - Definiciones.MENU_PRINCIPAL_Y_OFFSET
            m_posicionY              = Video.Alto + menu.alto + Definiciones.MENU_PRINCIPAL_Y_OFFSET
            menu.setearPosicion(0, Video.Alto + 15, Superficie.H_CENTRO)
        }

        menu.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_MENU])
        m_menu = menu
    }

    override func actualizar() {
        guard let menu = m_menu else { return }

        m_cuenta += 1
        if m_cuenta > CUENTA_HASTA_MOSTRAR_MENU {
            if m_posicionY > m_menuPosicionDeseadaY {
                m_posicionY -= INCREMENTO_MENU_Y
            }
            menu.setearPosicion(0, m_posicionY, Superficie.H_CENTRO)
        }

        m_itemSeleccionado = menu.actualizar()

        switch m_itemSeleccionado {
        case ITEM.NUEVO_JUEGO.rawValue:
            maquinaDeEstados.setearElProximoEstado(.JUEGO)
        case ITEM.AYUDA.rawValue:
            maquinaDeEstados.setearElProximoEstado(.AYUDA)
        case ITEM.SALIR.rawValue:
            maquinaDeEstados.setearElProximoEstado(.SALIR)
        default:
            break
        }
    }

    override func dibujar(_ g: Video) {
        g.dibujar(m_fondo, 0, 0, 0)
        m_menu?.dibujar(g)
    }

    override func salir() {
        m_menu = nil
    }
}

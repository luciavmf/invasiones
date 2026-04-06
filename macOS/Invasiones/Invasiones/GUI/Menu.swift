//
//  Menu.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Menu.cs — vertical menu with mouse-selectable items.
//

import Foundation

class Menu: CajaGUI {

    // MARK: - Constants
    static let MAX_CANTIDAD_ITEMS    = 15
    static let ITEM_VISIBLE          = 1 << 1
    static let ITEM_ESCONDIDO        = 1 << 2
    static let ITEM_DEBAJO_DEL_MOUSE = 1 << 3
    static let ITEM_SELECCIONADO     = 1 << 4

    // MARK: - Declarations
    private var m_items:              [Int]
    private var m_cantidadDeItems:    Int = 0
    private var m_botonAncho:         Int = 160
    private var m_botonAlto:          Int = 26
    private var m_espacioEntreLineas: Int = 1
    private var m_posicionOriginalY:  Int
    private var m_posicionOriginalX:  Int
    private var m_ancla:              Int

    // MARK: - Initializer
    init(imagen: Superficie?, cantItem: Int, x: Int, y: Int, ancla: Int) {
        m_items             = Array(repeating: 0, count: Menu.MAX_CANTIDAD_ITEMS)
        m_posicionOriginalX = x
        m_posicionOriginalY = y
        m_ancla             = ancla
        super.init()

        m_imagen = imagen
        if cantItem == 3 {
            m_imagen = AdministradorDeRecursos.Instancia.obtenerImagenAlpha(Res.IMG_MENU_3)
        } else if cantItem == 2 {
            m_imagen = AdministradorDeRecursos.Instancia.obtenerImagenAlpha(Res.IMG_MENU_2)
        }
    }

    // MARK: - Methods

    override func dibujar(_ g: Video) {
        if let img = m_imagen {
            g.dibujar(img, m_x, m_y - 6, 0)
        }

        var y = m_y
        for i in 0..<m_cantidadDeItems {
            let flags = (m_items[i] & 0xFF00) >> 8
            if flags != Menu.ITEM_ESCONDIDO {
                if (flags & Menu.ITEM_DEBAJO_DEL_MOUSE) != 0 {
                    g.setearColor(Definiciones.COLOR_NEGRO)
                    g.llenarRectangulo(m_x + 2, y, m_botonAncho, m_botonAlto)
                }
                g.setearFuente(m_fuente, Definiciones.GUI_COLOR_TEXTO)
                g.escribir(m_items[i] & 0xFF,
                           m_x - (Video.Ancho >> 1) + (m_botonAncho >> 1),
                           y   - (Video.Alto  >> 1) + (m_botonAlto  >> 1),
                           Superficie.H_CENTRO | Superficie.V_CENTRO)
                y += m_espacioEntreLineas + m_botonAlto
            }
        }
    }

    @discardableResult
    override func actualizar() -> Int {
        var itemSeleccionado = -1
        var y = m_y

        for i in 0..<m_cantidadDeItems {
            let flags = (m_items[i] & 0xFF00) >> 8
            if flags != Menu.ITEM_ESCONDIDO {
                let mx = Int(Mouse.Instancia.X)
                let my = Int(Mouse.Instancia.Y)
                if mx > m_x && mx < m_x + m_botonAncho && my > y && my < y + m_botonAlto {
                    m_items[i] |= (Menu.ITEM_DEBAJO_DEL_MOUSE << 8)
                    if Mouse.Instancia.BotonesApretados.contains(Mouse.BOTON_IZQ) {
                        m_items[i] |= (Menu.ITEM_SELECCIONADO << 8)
                        itemSeleccionado = i
                    }
                } else {
                    m_items[i] &= ~(Menu.ITEM_DEBAJO_DEL_MOUSE << 8)
                }
                y += m_espacioEntreLineas + m_botonAlto
            }
        }

        return itemSeleccionado
    }

    override func setearPosicion(_ x: Int, _ y: Int, _ ancla: Int) {
        m_posicionOriginalX = x
        m_x = x
        m_posicionOriginalY = y
        m_y = y
        m_ancla = ancla

        if (m_ancla & Superficie.H_CENTRO) != 0 {
            m_x = (Video.Ancho >> 1) - (m_botonAncho >> 1) + m_posicionOriginalX
        }
        if (m_ancla & Superficie.V_CENTRO) != 0 {
            m_y = (Video.Alto >> 1) + m_posicionOriginalY
                - (((m_botonAlto + m_espacioEntreLineas) * m_cantidadDeItems
                    - m_espacioEntreLineas) >> 1)
        }
    }

    @discardableResult
    func agregarItem(_ index: Int, _ stringId: Int, _ flag: Int) -> Bool {
        guard index <= Menu.MAX_CANTIDAD_ITEMS - 1 else { return false }

        if m_cantidadDeItems == index {
            m_cantidadDeItems += 1
        }
        m_items[index] = (flag << 8) | (stringId & 0xFF)

        if (m_ancla & Superficie.H_CENTRO) != 0 {
            m_x = (Video.Ancho >> 1) - (m_botonAncho >> 1) + m_posicionOriginalX
        }
        if (m_ancla & Superficie.V_CENTRO) != 0 {
            m_y = (Video.Alto >> 1) + m_posicionOriginalY
                - (((m_botonAlto + m_espacioEntreLineas) * m_cantidadDeItems
                    - m_espacioEntreLineas) >> 1)
        }

        m_alto  = m_imagen?.alto  ?? 0
        m_ancho = m_imagen?.ancho ?? 0

        return true
    }

    func setearImagen(_ sup: Superficie?) {
        m_imagen = sup
    }

    func setearFuente(_ fuente: Fuente?) {
        m_fuente = fuente
    }
}

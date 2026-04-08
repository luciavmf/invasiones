//
//  GameText.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Texto.cs — loads and caches localised strings from strings.json.
//

import Foundation

/// Loads and caches all localised strings from strings.json.
/// All strings are cached in a static array indexed by the `Res.STR_*` constants.
enum GameText {

    // MARK: - Key order (must match Res.STR_* index values)
    private static let keyOrder: [String] = [
        "SDL_INIT_FALLO",                   // 0
        "WINDOW_CAPTION",                   // 1
        "FATAL_ERROR_CAPTION",              // 2
        "PRESIONE_PARA_CONTINUAR",          // 3
        "CARGANDO",                         // 4
        "SIGUIENTE",                        // 5
        "ATRAS",                            // 6
        "GANASTE",                          // 7
        "PERDISTE",                         // 8
        "CONTINUARJUEGO",                   // 9
        "OBJETIVOS",                        // 10
        "ACEPTAR",                          // 11
        "CONTINUAR",                        // 12
        "MENU_PRINCIPAL",                   // 13
        "MENU_CONTINUAR",                   // 14
        "MENU_NUEVO_JUEGO",                 // 15
        "MENU_CARGAR_PARTIDA",              // 16
        "MENU_OPCIONES",                    // 17
        "MENU_CREDITOS",                    // 18
        "MENU_AYUDA",                       // 19
        "MENU_SALIR",                       // 20
        "MENU_GUARDAR",                     // 21
        "MENU_REINICIAR",                   // 22
        "BOTON_MENU",                       // 23
        "BOTON_MENU_DEL_JUEGO",             // 24
        "JUEGO_PAUSADO",                    // 25
        "UNIDAD",                           // 26
        "PUNTOS_DE_RESISTENCIA",            // 27
        "ALCANCE",                          // 28
        "PUNTOS_DE_ATAQUE",                 // 29
        "VISIBILIDAD",                      // 30
        "PUNTERIA",                         // 31
        "VELOCIDAD",                        // 32
        "CONFIRMACION_SALIR",               // 33
        "SI",                               // 34
        "NO",                               // 35
        "INGRESE_NOMBRE",                   // 36
        "LISTO",                            // 37
        "CREDITOS_PROGRAMACION",            // 38
        "CREDITOS_PROGRAMADOR_1",           // 39
        "CREDITOS_DISENO_DE_NIVEL",         // 40
        "CREDITOS_DISENADOR_DE_NIVEL_1",    // 41
        "OBJETIVO_BATALLA_1_1",             // 42
        "OBJETIVO_BATALLA_2_1",             // 43
        "OBJETIVO_BATALLA_3_1",             // 44
        "OBJETIVO_BATALLA_4_1",             // 45
        "PRIMER_BATALLA",                   // 46
        "PRIMER_BATALLA_2",                 // 47
        "PRIMER_BATALLA_OBJETIVO_3",        // 48
        "SEGUNDA_BATALLA",                  // 49
        "SEGUNDA_BATALLA_2",                // 50
        "SEGUNDA_BATALLA_OBJETIVO_3",       // 51
        "TERCER_BATALLA",                   // 52
        "TERCER_BATALLA_2",                 // 53
        "TERCER_BATALLA_OBJETIVO_3",        // 54
        "CUARTA_BATALLA",                   // 55
        "CUARTA_BATALLA_2",                 // 56
        "CUARTA_BATALLA_OBJETIVO_3",        // 57
        "CONSECUENCIAS",                    // 58
        "CONSECUENCIAS_1",                  // 59
        "CONSECUENCIAS_2",                  // 60
        "CONSECUENCIAS_3",                  // 61
        "MENU_AYUDA_TEXTO_SELECCIONAR_01",  // 62
        "MENU_AYUDA_TEXTO_SELECCIONAR_02",  // 63
        "MENU_AYUDA_TEXTO_MOVER_01",        // 64
        "MENU_AYUDA_TEXTO_MOVER_02",        // 65
        "MENU_AYUDA_TEXTO_ATACAR_01",       // 66
        "MENU_AYUDA_TEXTO_ATACAR_02",       // 67
        "MENU_AYUDA_TEXTO_OBJETIVO_01",     // 68
        "MENU_AYUDA_TEXTO_OBJETIVO_02",     // 69
        "MENU_AYUDA_TEXTO_SCROLL_01",       // 70
        "MENU_AYUDA_TEXTO_SCROLL_02",       // 71
        "MENU_AYUDA_TEXTO_HUD_01",          // 72
        "MENU_AYUDA_TEXTO_HUD_02",          // 73
        "MENU_AYUDA_TEXTO_SANAR_01",        // 74
        "MENU_AYUDA_TEXTO_SANAR_02",        // 75
        "MENU_AYUDA_TEXTO_TIPS_01",         // 76
        "MENU_AYUDA_TEXTO_TIPS_02",         // 77
        "MENU_AYUDA_TEXTO_GANAR_01",        // 78
        "MENU_AYUDA_TEXTO_GANAR_02",        // 79
        "TIP_00",  // 80
        "TIP_01",  // 81
        "TIP_02",  // 82
        "TIP_03",  // 83
        "TIP_04",  // 84
        "TIP_05",  // 85
        "TIP_06",  // 86
        "TIP_07",  // 87
        "TIP_08",  // 88
        "TIP_09",  // 89
        "TIP_10",  // 90
        "TIP_11",  // 91
        "TIP_12",  // 92
        "TIP_13",  // 93
        "TIP_14",  // 94
        "TIP_15",  // 95
        "TIP_16",  // 96
        "TIP_17",  // 97
        "TIP_18",  // 98
        "TIP_19",  // 99
        "TIP_20",  // 100
        "TIP_21",  // 101
        "TIP_22",  // 102
        "TIP_23",  // 103
    ]

    // MARK: - Static storage
    private static var s_strings: [String]?

    // MARK: - Load
    static func loadStrings() throws {
        guard let path = Utils.getPath(ResourcePath.stringsPath) else {
            throw GameError.fileNotFound("No se encuentra el archivo \(ResourcePath.stringsPath).")
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let dict: [String: String]
        do {
            dict = try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            throw GameError.parsingFailed("GameText: failed to parse \(ResourcePath.stringsPath): \(error).")
        }
        s_strings = keyOrder.map { dict[$0] ?? "" }
    }

    // MARK: - Access
    static var Strings: [String] {
        if s_strings == nil { try? loadStrings() }
        return s_strings ?? []
    }
}

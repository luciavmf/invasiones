//
//  Fuente.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Fuente.cs — wrapper over SDL_ttf for TrueType fonts.
//  On macOS we use NSFont; custom TTF fonts are registered with CTFontManager.
//

import AppKit
import CoreText

class Fuente {

    // MARK: - Declarations
    private(set) var nsFont: NSFont?
    private(set) var nombre: String
    private(set) var tamanio: Int

    // MARK: - Initializer
    /// Creates a font from a font ID (index in PathsFuentes) and the point size.
    init(idFuente: Int, tamanio: Int) {
        self.tamanio = tamanio

        let paths = AdministradorDeRecursos.Instancia.pathsFuentes
        guard idFuente < paths.count, let path = paths[idFuente] else {
            Log.Instancia.error("Fuente: path inválido para id \(idFuente)")
            self.nombre = ""
            return
        }

        // Register the custom TTF font if not yet registered
        let url = URL(fileURLWithPath: path) as CFURL
        CTFontManagerRegisterFontsForURL(url, .process, nil)

        // Obtain the descriptor and PostScript name from the registered URL
        if let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url) as? [CTFontDescriptor],
           let descriptor = descriptors.first {
            let postscriptName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String ?? ""
            self.nombre = postscriptName
            self.nsFont = NSFont(name: postscriptName, size: CGFloat(tamanio))
        } else {
            self.nombre = ""
            Log.Instancia.error("Fuente: no se pudo obtener descriptor desde \(path)")
        }

        if nsFont == nil {
            // Fall back to system font
            self.nsFont = NSFont.systemFont(ofSize: CGFloat(tamanio))
            Log.Instancia.advertir("Fuente: usando fuente del sistema como fallback (tamaño \(tamanio))")
        }
    }

    func dispose() {
        nsFont = nil
    }
}

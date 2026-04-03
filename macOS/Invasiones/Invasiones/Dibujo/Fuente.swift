// Dibujo/Fuente.swift
// Puerto de Fuente.cs — envoltorio sobre SDL_ttf para fuentes TrueType.
// En macOS usamos NSFont; las fuentes TTF personalizadas se registran con CTFontManager.

import AppKit
import CoreText

class Fuente {

    // MARK: - Declaraciones
    private(set) var nsFont: NSFont?
    private(set) var nombre: String
    private(set) var tamanio: Int

    // MARK: - Constructor
    /// Crea una fuente desde el ID de fuente (índice en PathsFuentes) y el tamaño en puntos.
    init(idFuente: Int, tamanio: Int) {
        self.tamanio = tamanio

        let paths = AdministradorDeRecursos.Instancia.pathsFuentes
        guard idFuente < paths.count, let path = paths[idFuente] else {
            Log.Instancia.error("Fuente: path inválido para id \(idFuente)")
            self.nombre = ""
            return
        }

        // Registrar la fuente TTF personalizada si aún no está registrada
        let url = URL(fileURLWithPath: path) as CFURL
        CTFontManagerRegisterFontsForURL(url, .process, nil)

        // Obtener el descriptor y el nombre PostScript desde la URL registrada
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
            // Fallback a fuente del sistema
            self.nsFont = NSFont.systemFont(ofSize: CGFloat(tamanio))
            Log.Instancia.advertir("Fuente: usando fuente del sistema como fallback (tamaño \(tamanio))")
        }
    }

    func dispose() {
        nsFont = nil
    }
}

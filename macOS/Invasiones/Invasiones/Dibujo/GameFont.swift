//
//  GameFont.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Fuente.cs — wrapper over SDL_ttf for TrueType fonts.
//  On macOS we use NSFont; custom TTF fonts are registered with CTFontManager.
//

import AppKit
import CoreText

class GameFont {

    // MARK: - Declarations
    private(set) var nsFont: NSFont?
    private(set) var name: String
    private(set) var size: Int

    // MARK: - Initializer
    /// Creates a font from a font ID (index in PathsFuentes) and the point size.
    init(fontId: Int, size: Int) {
        self.size = size

        let paths = ResourceManager.shared.fontPaths
        guard fontId < paths.count, let path = paths[fontId] else {
            Log.shared.error("GameFont: path inválido para id \(fontId)")
            self.name = ""
            return
        }

        // Register the custom TTF font if not yet registered
        let url = URL(fileURLWithPath: path) as CFURL
        CTFontManagerRegisterFontsForURL(url, .process, nil)

        // Obtain the descriptor and PostScript name from the registered URL
        if let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url) as? [CTFontDescriptor],
           let descriptor = descriptors.first {
            let postscriptName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String ?? ""
            self.name = postscriptName
            self.nsFont = NSFont(name: postscriptName, size: CGFloat(size))
        } else {
            self.name = ""
            Log.shared.error("GameFont: no se pudo obtener descriptor desde \(path)")
        }

        if nsFont == nil {
            // Fall back to system font
            self.nsFont = NSFont.systemFont(ofSize: CGFloat(size))
            Log.shared.warn("GameFont: usando fuente del sistema como fallback (tamaño \(size))")
        }
    }

    func dispose() {
        nsFont = nil
    }
}

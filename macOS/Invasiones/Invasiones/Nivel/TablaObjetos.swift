//
//  TablaObjetos.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Reference wrapper over the map object grid.
//  In C# arrays are reference types; in Swift they are value types.
//  Shared between Episodio, BandoArgentino, and BandoEnemigo so all read and write
//  to the same underlying array.
//

final class TablaObjetos {
    var tabla: [[Objeto?]]
    init(_ tabla: [[Objeto?]]) { self.tabla = tabla }
}

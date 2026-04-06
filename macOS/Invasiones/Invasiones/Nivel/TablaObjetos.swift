// Nivel/TablaObjetos.swift
// Envoltorio de referencia sobre la cuadrícula de objetos del mapa.
// En C# los arrays son tipos de referencia; en Swift son tipos de valor.
// Al compartir esta clase entre Episodio, BandoArgentino y BandoEnemigo,
// todos leen y escriben sobre el mismo arreglo subyacente.

final class TablaObjetos {
    var tabla: [[Objeto?]]
    init(_ tabla: [[Objeto?]]) { self.tabla = tabla }
}

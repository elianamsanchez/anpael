package com.anpael.trazabilidad.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/**
 * Categorías admitidas por rodeo (v0.2a, migración categorias_rodeos_v3): un
 * id_rodeo sin ninguna fila acá no tiene restricción de categoría (por
 * ejemplo Descarte o Tropa de Venta).
 */
@Entity
@Table(name = "rodeo_categoria")
@Getter
public class RodeoCategoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_rodeo_categoria")
    private Integer idRodeoCategoria;

    @Column(name = "id_rodeo", nullable = false)
    private Integer idRodeo;

    @Column(name = "id_categoria", nullable = false)
    private Integer idCategoria;
}

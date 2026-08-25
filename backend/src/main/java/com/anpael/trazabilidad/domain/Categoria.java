package com.anpael.trazabilidad.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/** Catálogo: vaca, vaquillona, ternero, toro, CUT, … con un orden (docs/modelo-datos.md). */
@Entity
@Table(name = "categoria")
@Getter
public class Categoria {

    @Id
    @Column(name = "id_categoria")
    private Integer idCategoria;

    @Column(name = "codigo", nullable = false)
    private String codigo;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    @Column(name = "sexo", nullable = false)
    private String sexo;

    @Column(name = "orden", nullable = false)
    private Integer orden;
}

package com.anpael.trazabilidad.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/** Catálogo de causas de baja: VENTA, MUERTE, TRASLADO, FALTANTE (docs/modelo-datos.md). */
@Entity
@Table(name = "causa_baja")
@Getter
public class CausaBaja {

    @Id
    @Column(name = "id_causa_baja")
    private Integer idCausaBaja;

    @Column(name = "tipo_baja", nullable = false)
    private String tipoBaja;

    @Column(name = "descripcion", nullable = false)
    private String descripcion;
}

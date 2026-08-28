package com.anpael.trazabilidad.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/** Catálogo: VISUAL, RFID, SENASA, FUEGO, ADICIONAL (docs/modelo-datos.md). */
@Entity
@Table(name = "tipo_identificacion")
@Getter
public class TipoIdentificacion {

    @Id
    @Column(name = "id_tipo_ident")
    private Integer idTipoIdent;

    @Column(name = "codigo", nullable = false)
    private String codigo;

    @Column(name = "descripcion", nullable = false)
    private String descripcion;

    @Column(name = "ambito", nullable = false)
    private String ambito;

    @Column(name = "es_oficial", nullable = false)
    private Boolean esOficial;
}

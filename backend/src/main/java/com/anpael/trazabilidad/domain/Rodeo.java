package com.anpael.trazabilidad.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/** Los rodeos (docs/modelo-datos.md). Un rodeo no es una categoría. */
@Entity
@Table(name = "rodeo")
@Getter
public class Rodeo {

    @Id
    @Column(name = "id_rodeo")
    private Integer idRodeo;

    @Column(name = "id_establecimiento", nullable = false)
    private Integer idEstablecimiento;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    @Column(name = "descripcion")
    private String descripcion;

    @Column(name = "activo", nullable = false)
    private Boolean activo;

    @Column(name = "orden", nullable = false)
    private Integer orden;
}

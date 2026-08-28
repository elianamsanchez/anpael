package com.anpael.trazabilidad.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/** Los campos, incluido Santa Ana -el propio- y los CUIG de origen de compras. */
@Entity
@Table(name = "establecimiento")
@Getter
public class Establecimiento {

    @Id
    @Column(name = "id_establecimiento")
    private Integer idEstablecimiento;

    @Column(name = "cuig", nullable = false)
    private String cuig;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    @Column(name = "es_propio", nullable = false)
    private Boolean esPropio;

    @Column(name = "localidad")
    private String localidad;

    @Column(name = "provincia")
    private String provincia;

    @Column(name = "activo", nullable = false)
    private Boolean activo;
}

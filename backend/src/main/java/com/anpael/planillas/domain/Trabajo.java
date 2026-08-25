package com.anpael.planillas.domain;

import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * La jornada: que se hizo, cuando, en que establecimiento (docs/modelo-datos.md).
 * Una fila por planilla cargada.
 */
@Entity
@Table(name = "trabajo")
@Getter
@Setter
public class Trabajo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_trabajo")
    private Integer idTrabajo;

    @Column(name = "id_establecimiento", nullable = false)
    private Integer idEstablecimiento;

    @Column(name = "id_responsable")
    private Integer idResponsable;

    @Column(name = "fecha", nullable = false)
    private LocalDate fecha;

    @Column(name = "tipo_trabajo", nullable = false)
    private String tipoTrabajo;

    @Column(name = "id_rodeo")
    private Integer idRodeo;

    @Column(name = "observaciones")
    private String observaciones;
}

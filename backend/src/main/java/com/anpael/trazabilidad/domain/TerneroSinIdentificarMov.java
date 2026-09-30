package com.anpael.trazabilidad.domain;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import org.hibernate.annotations.Immutable;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * Un movimiento de terneros sin caravana: cantidad por ciclo y sexo, sin
 * animal (migración 20260929120000). Solo se insertan: la base rechaza
 * UPDATE/DELETE con un trigger, y @Immutable hace que Hibernate ni lo intente.
 * Una corrección es una ANULACION del movimiento equivocado.
 *
 * excedeSaldo lo recalcula el trigger ternero_mov_validar() al insertar: el
 * valor que tenga la entidad después de save() puede no ser el guardado. Para
 * leer el movimiento ya cargado, usar la vista (TerneroSinIdentificarConsultas).
 * fechaRegistro la pone la base (default now()).
 */
@Entity
@Immutable
@Table(name = "ternero_sin_identificar_mov")
@Getter
@Setter
public class TerneroSinIdentificarMov {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_mov")
    private Integer idMov;

    @Column(name = "id_establecimiento", nullable = false)
    private Integer idEstablecimiento;

    @Column(name = "id_ciclo_productivo", nullable = false)
    private Integer idCicloProductivo;

    @Column(name = "ciclo_manual", nullable = false)
    private Boolean cicloManual = false;

    @Column(name = "fecha_evento", nullable = false)
    private LocalDate fechaEvento;

    @Column(name = "fecha_es_estimada", nullable = false)
    private Boolean fechaEsEstimada = false;

    @Column(name = "fecha_registro", insertable = false, updatable = false)
    private OffsetDateTime fechaRegistro;

    @Column(name = "sexo", nullable = false)
    private String sexo;

    @Column(name = "cantidad", nullable = false)
    private Integer cantidad;

    @Column(name = "tipo", nullable = false)
    private String tipo;

    @Column(name = "id_mov_anulado")
    private Integer idMovAnulado;

    @Column(name = "id_trabajo")
    private Integer idTrabajo;

    @Column(name = "excede_saldo", nullable = false)
    private Boolean excedeSaldo = false;

    @Column(name = "observaciones")
    private String observaciones;

    @Column(name = "id_persona_registro")
    private Integer idPersonaRegistro;
}

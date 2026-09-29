package com.anpael.trazabilidad.domain;

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
 * Un ciclo productivo, de servicio a destete (migración 20260929120000). Hay
 * dos líneas en paralelo: VACA ('2025-26') y VAQ ('VAQ2025-26'). Dentro de
 * una línea, [paricionDesde, fechaFin] no se superpone: es el rango que
 * define a qué ciclo pertenece una fecha (ciclo_productivo_sugerido()).
 */
@Entity
@Table(name = "ciclo_productivo")
@Getter
@Setter
public class CicloProductivo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_ciclo_productivo")
    private Integer idCicloProductivo;

    @Column(name = "codigo", nullable = false)
    private String codigo;

    @Column(name = "linea", nullable = false)
    private String linea;

    @Column(name = "fecha_inicio", nullable = false)
    private LocalDate fechaInicio;

    @Column(name = "paricion_desde", nullable = false)
    private LocalDate paricionDesde;

    @Column(name = "paricion_hasta", nullable = false)
    private LocalDate paricionHasta;

    @Column(name = "fecha_fin", nullable = false)
    private LocalDate fechaFin;

    @Column(name = "observaciones")
    private String observaciones;
}

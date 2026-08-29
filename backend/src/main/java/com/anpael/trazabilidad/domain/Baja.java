package com.anpael.trazabilidad.domain;

import java.math.BigDecimal;
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
 * Cuándo salió el animal del campo y por qué (docs/modelo-datos.md). Un
 * animal no se borra: baja_id_animal_key es UNIQUE, una sola baja por
 * animal, para siempre. No hay update ni segunda baja.
 */
@Entity
@Table(name = "baja")
@Getter
@Setter
public class Baja {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_baja")
    private Integer idBaja;

    @Column(name = "id_animal", nullable = false)
    private Integer idAnimal;

    @Column(name = "id_causa_baja", nullable = false)
    private Integer idCausaBaja;

    @Column(name = "fecha", nullable = false)
    private LocalDate fecha;

    @Column(name = "peso_salida_kg")
    private BigDecimal pesoSalidaKg;

    @Column(name = "destino")
    private String destino;

    @Column(name = "observaciones")
    private String observaciones;

    @Column(name = "id_persona_registro")
    private Integer idPersonaRegistro;

    /**
     * true = 'fecha' es el día del saneamiento, no el día real en que el
     * animal salió del campo -lo normal en una baja REGULARIZACION
     * (docs/modelo-datos.md, migración 20260828100000).
     */
    @Column(name = "fecha_es_estimada", nullable = false)
    private Boolean fechaEsEstimada;
}

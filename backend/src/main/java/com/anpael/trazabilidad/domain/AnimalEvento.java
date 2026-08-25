package com.anpael.trazabilidad.domain;

import java.math.BigDecimal;
import java.time.LocalDate;

import org.hibernate.annotations.Immutable;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/**
 * La historia de un animal (docs/modelo-datos.md): mapea v_animal_evento,
 * que arma un "detalle" legible por evento a partir de la tabla especifica
 * de cada trabajo (diagnostico_gestacion, pesaje, revision_toro, sanidad,
 * medicion_corporal, evento_reproductivo). Solo lectura, igual que AnimalLista.
 */
@Entity
@Immutable
@Table(name = "v_animal_evento")
@Getter
public class AnimalEvento {

    @Id
    @Column(name = "id_evento")
    private Integer idEvento;

    @Column(name = "id_animal")
    private Integer idAnimal;

    @Column(name = "fecha")
    private LocalDate fecha;

    @Column(name = "tipo_trabajo")
    private String tipoTrabajo;

    @Column(name = "jornada")
    private String jornada;

    @Column(name = "cuig")
    private String cuig;

    @Column(name = "origen_dato")
    private String origenDato;

    @Column(name = "detalle")
    private String detalle;

    @Column(name = "clase")
    private String clase;

    @Column(name = "tacto_resultado")
    private String tactoResultado;

    @Column(name = "condicion_corporal")
    private BigDecimal condicionCorporal;

    @Column(name = "dentadura")
    private String dentadura;

    @Column(name = "comentario")
    private String comentario;
}

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
 * Un numero de identificacion de un animal (docs/modelo-datos.md): la
 * columna se llama `caravana` pero la tabla guarda todos los tipos -incluida
 * la marca a fuego-, texto siempre para no perder ceros a la izquierda. Un
 * animal puede tener varias identificaciones vigentes; para "la" del animal
 * hay que usar la vista v_ident_principal (AnimalLista), nunca un join
 * directo contra esta tabla.
 */
@Entity
@Table(name = "identificacion")
@Getter
@Setter
public class Identificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_identificacion")
    private Integer idIdentificacion;

    @Column(name = "id_animal", nullable = false)
    private Integer idAnimal;

    @Column(name = "id_tipo_ident", nullable = false)
    private Integer idTipoIdent;

    @Column(name = "id_establecimiento")
    private Integer idEstablecimiento;

    @Column(name = "caravana", nullable = false)
    private String caravana;

    @Column(name = "fecha_alta")
    private LocalDate fechaAlta;

    @Column(name = "fecha_baja")
    private LocalDate fechaBaja;

    @Column(name = "motivo_baja")
    private String motivoBaja;

    @Column(name = "fecha_alta_es_estimada", nullable = false)
    private Boolean fechaAltaEsEstimada;
}

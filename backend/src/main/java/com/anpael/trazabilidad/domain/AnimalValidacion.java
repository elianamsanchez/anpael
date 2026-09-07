package com.anpael.trazabilidad.domain;

import java.time.OffsetDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * La revisión de saneamiento de un animal: VALIDADO, CORREGIR o DUDOSO
 * (ADR-004). Una sola fila por animal -id_animal es la PK, no hay historial-,
 * así que "marcar" siempre es upsert: si ya existe, se pisa.
 *
 * revisado_en no es escribible desde acá (insertable/updatable = false): la
 * pone siempre el trigger sellar_validacion() con el reloj de la base, no el
 * de la app.
 */
@Entity
@Table(name = "animal_validacion")
@Getter
@Setter
public class AnimalValidacion {

    @Id
    @Column(name = "id_animal")
    private Integer idAnimal;

    @Column(name = "estado", nullable = false)
    private String estado;

    @Column(name = "id_persona")
    private Integer idPersona;

    @Column(name = "revisado_en", insertable = false, updatable = false)
    private OffsetDateTime revisadoEn;

    @Column(name = "observacion")
    private String observacion;
}

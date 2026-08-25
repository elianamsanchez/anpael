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
 * Que categoria tiene un animal, con fecha_desde/fecha_hasta (docs/modelo-datos.md).
 * La fila vigente es la que tiene fecha_hasta null. Un indice unico parcial
 * (ux_animal_categoria_abierta) impide que un animal tenga dos filas
 * abiertas: por eso AnimalCategoriaService cierra la anterior antes de
 * insertar la nueva, en la misma transaccion.
 */
@Entity
@Table(name = "animal_categoria")
@Getter
@Setter
public class AnimalCategoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_animal_categoria")
    private Integer idAnimalCategoria;

    @Column(name = "id_animal", nullable = false)
    private Integer idAnimal;

    @Column(name = "id_categoria", nullable = false)
    private Integer idCategoria;

    @Column(name = "fecha_desde", nullable = false)
    private LocalDate fechaDesde;

    @Column(name = "fecha_hasta")
    private LocalDate fechaHasta;
}

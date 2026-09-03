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
 * La identidad del animal, no el estado (docs/modelo-datos.md). Distinta de
 * AnimalLista (@Immutable, mapea la vista de solo lectura): esta es la
 * tabla real, para poder corregir y completar datos -raza, pelaje, fecha de
 * nacimiento, peso al nacer- desde el saneamiento (v0.2a).
 */
@Entity
@Table(name = "animal")
@Getter
@Setter
public class Animal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_animal")
    private Integer idAnimal;

    @Column(name = "id_estab_origen")
    private Integer idEstabOrigen;

    @Column(name = "id_raza")
    private Integer idRaza;

    @Column(name = "id_pelaje")
    private Integer idPelaje;

    @Column(name = "id_cabana")
    private Integer idCabana;

    @Column(name = "id_madre")
    private Integer idMadre;

    @Column(name = "id_padre")
    private Integer idPadre;

    @Column(name = "sexo", nullable = false)
    private String sexo;

    @Column(name = "fecha_nacimiento")
    private LocalDate fechaNacimiento;

    @Column(name = "fecha_nac_es_estimada", nullable = false)
    private Boolean fechaNacEsEstimada;

    @Column(name = "anio_nacimiento")
    private Integer anioNacimiento;

    @Column(name = "peso_nacer_kg")
    private BigDecimal pesoNacerKg;

    @Column(name = "origen", nullable = false)
    private String origen;

    @Column(name = "fecha_ingreso")
    private LocalDate fechaIngreso;

    @Column(name = "anio_ingreso")
    private Integer anioIngreso;

    @Column(name = "activo", nullable = false)
    private Boolean activo;
}

package com.anpael.trazabilidad.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/** Origen de los animales comprados (docs/modelo-datos.md). */
@Entity
@Table(name = "cabana")
@Getter
public class Cabana {

    @Id
    @Column(name = "id_cabana")
    private Integer idCabana;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    @Column(name = "contacto")
    private String contacto;
}

package com.anpael.planillas.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/** El resultado de un tacto/ecografia. id_evento es el PK, no se autogenera. */
@Entity
@Table(name = "diagnostico_gestacion")
@Getter
@Setter
public class DiagnosticoGestacion {

    @Id
    @Column(name = "id_evento")
    private Integer idEvento;

    @Column(name = "metodo", nullable = false)
    private String metodo;

    @Column(name = "resultado", nullable = false)
    private String resultado;

    @Column(name = "tamano")
    private String tamano;
}

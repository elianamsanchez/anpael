package com.anpael.planillas.domain;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "pesaje")
@Getter
@Setter
public class Pesaje {

    @Id
    @Column(name = "id_evento")
    private Integer idEvento;

    @Column(name = "peso_kg", nullable = false)
    private BigDecimal pesoKg;

    @Column(name = "tipo_pesada")
    private String tipoPesada;
}

package com.anpael.planillas.domain;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "sanidad")
@Getter
@Setter
public class Sanidad {

    @Id
    @Column(name = "id_evento")
    private Integer idEvento;

    @Column(name = "producto", nullable = false)
    private String producto;

    @Column(name = "dosis")
    private BigDecimal dosis;
}

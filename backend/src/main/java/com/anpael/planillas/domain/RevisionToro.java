package com.anpael.planillas.domain;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "revision_toro")
@Getter
@Setter
public class RevisionToro {

    @Id
    @Column(name = "id_evento")
    private Integer idEvento;

    @Column(name = "apto", nullable = false)
    private Boolean apto;

    @Column(name = "circ_escrotal_cm")
    private BigDecimal circEscrotalCm;
}

package com.anpael.planillas.domain;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/** Condicion corporal, dentadura, alzada (docs/modelo-datos.md). Solo se
 * carga condicion_corporal desde la planilla de revision de toros. */
@Entity
@Table(name = "medicion_corporal")
@Getter
@Setter
public class MedicionCorporal {

    @Id
    @Column(name = "id_evento")
    private Integer idEvento;

    @Column(name = "condicion_corporal")
    private BigDecimal condicionCorporal;
}

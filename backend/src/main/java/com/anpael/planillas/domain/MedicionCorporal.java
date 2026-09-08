package com.anpael.planillas.domain;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/** Condicion corporal, dentadura, alzada (docs/modelo-datos.md). Se cargan
 * condicion_corporal y dentadura desde la planilla de revision de toros;
 * alzada todavia no tiene pantalla. */
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

    /** Catálogo: 2D, 3D, 4D, 6D, BLL, 3/4D, MD+, MD, MD-, 1/4D, -1/4D, SD/CUT (CHECK en la base). */
    @Column(name = "dentadura")
    private String dentadura;
}

package com.anpael.planillas.api.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Pattern;

public record CorregirRevisionTorosRequest(

        @DecimalMin(value = "24", message = "tiene que estar entre 24 y 50 cm")
        @DecimalMax(value = "50", message = "tiene que estar entre 24 y 50 cm")
        BigDecimal circunferenciaEscrotal,

        @DecimalMin(value = "1", message = "tiene que estar entre 1 y 5")
        @DecimalMax(value = "5", message = "tiene que estar entre 1 y 5")
        BigDecimal condicionCorporal,

        @Pattern(regexp = "2D|3D|4D|6D|BLL|3/4D|MD\\+|MD|MD-|1/4D|-1/4D|SD/CUT",
                message = "no es un valor del catálogo de dentadura")
        String dentadura,

        Boolean apto) {
}

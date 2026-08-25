package com.anpael.planillas.api.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;

public record CorregirPesadaRequest(

        @DecimalMin(value = "15", message = "tiene que estar entre 15 y 1400 kg")
        @DecimalMax(value = "1400", message = "tiene que estar entre 15 y 1400 kg")
        BigDecimal kilos) {
}

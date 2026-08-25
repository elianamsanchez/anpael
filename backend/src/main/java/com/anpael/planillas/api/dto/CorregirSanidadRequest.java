package com.anpael.planillas.api.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.Positive;

public record CorregirSanidadRequest(

        String producto,

        @Positive(message = "tiene que ser mayor a 0")
        BigDecimal dosis) {
}

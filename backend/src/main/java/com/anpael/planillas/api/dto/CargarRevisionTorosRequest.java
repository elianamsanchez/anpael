package com.anpael.planillas.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record CargarRevisionTorosRequest(

        @NotNull(message = "es obligatorio")
        Integer idRodeo,

        LocalDate fecha,

        @NotEmpty(message = "cargá al menos un resultado")
        List<@Valid Linea> resultados) {

    public record Linea(

            @NotNull(message = "es obligatorio")
            Integer idAnimal,

            @DecimalMin(value = "24", message = "tiene que estar entre 24 y 50 cm")
            @DecimalMax(value = "50", message = "tiene que estar entre 24 y 50 cm")
            BigDecimal circunferenciaEscrotal,

            @DecimalMin(value = "1", message = "tiene que estar entre 1 y 5")
            @DecimalMax(value = "5", message = "tiene que estar entre 1 y 5")
            BigDecimal condicionCorporal,

            @NotNull(message = "es obligatorio")
            Boolean apto) {
    }
}

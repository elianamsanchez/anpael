package com.anpael.planillas.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record CargarPesadaRequest(

        @NotNull(message = "es obligatorio")
        Integer idRodeo,

        LocalDate fecha,

        @NotEmpty(message = "cargá al menos un resultado")
        List<@Valid Linea> resultados) {

    public record Linea(

            @NotNull(message = "es obligatorio")
            Integer idAnimal,

            @NotNull(message = "es obligatorio")
            @DecimalMin(value = "15", message = "tiene que estar entre 15 y 1400 kg")
            @DecimalMax(value = "1400", message = "tiene que estar entre 15 y 1400 kg")
            BigDecimal kilos) {
    }
}

package com.anpael.planillas.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record CargarSanidadRequest(

        @NotNull(message = "es obligatorio")
        Integer idRodeo,

        LocalDate fecha,

        @NotEmpty(message = "cargá al menos un resultado")
        List<@Valid Linea> resultados) {

    public record Linea(

            @NotNull(message = "es obligatorio")
            Integer idAnimal,

            @NotBlank(message = "es obligatorio")
            String producto,

            @Positive(message = "tiene que ser mayor a 0")
            BigDecimal dosis) {
    }
}

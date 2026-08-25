package com.anpael.planillas.api.dto;

import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record CargarTactoRequest(

        @NotNull(message = "es obligatorio")
        Integer idRodeo,

        LocalDate fecha,

        @NotEmpty(message = "cargá al menos un resultado")
        List<@Valid Linea> resultados) {

    /** resultado: PRENADA/VACIA/DUDOSA · tamano: CHICA/MEDIANA/GRANDE (solo si PRENADA). */
    public record Linea(

            @NotNull(message = "es obligatorio")
            Integer idAnimal,

            @NotBlank(message = "es obligatorio")
            String resultado,

            String tamano,

            String observaciones) {
    }
}

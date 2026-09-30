package com.anpael.planillas.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Inseminación: toro / estado / comentario, las mismas tres columnas de las
 * hojas del Excel ("Inseminación 11-11-22: Minihue / 4 / GNRH"). El estado
 * es la condición corporal de la vaca, como lo leyó la migración.
 */
public record CargarInseminacionRequest(

        @NotNull(message = "es obligatorio")
        Integer idRodeo,

        LocalDate fecha,

        @NotEmpty(message = "cargá al menos un resultado")
        List<@Valid Linea> resultados) {

    public record Linea(

            @NotNull(message = "es obligatorio")
            Integer idAnimal,

            @Size(max = 80, message = "tiene que tener hasta 80 caracteres")
            String toro,

            @DecimalMin(value = "1", message = "tiene que estar entre 1 y 5")
            @DecimalMax(value = "5", message = "tiene que estar entre 1 y 5")
            BigDecimal condicionCorporal,

            @Size(max = 500, message = "tiene que tener hasta 500 caracteres")
            String comentario) {
    }
}

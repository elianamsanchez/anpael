package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

/** Alta o edición de un ciclo productivo. El orden de las fechas lo valida el servicio. */
public record GuardarCicloProductivoRequest(

        @NotBlank(message = "el código es obligatorio")
        String codigo,

        @NotBlank(message = "la línea es obligatoria")
        @Pattern(regexp = "VACA|VAQ", message = "tiene que ser VACA o VAQ")
        String linea,

        @NotNull(message = "el inicio del servicio es obligatorio")
        LocalDate fechaInicio,

        @NotNull(message = "el inicio de la parición es obligatorio")
        LocalDate paricionDesde,

        @NotNull(message = "el fin de la parición es obligatorio")
        LocalDate paricionHasta,

        @NotNull(message = "el fin del ciclo es obligatorio")
        LocalDate fechaFin,

        String observaciones) {
}

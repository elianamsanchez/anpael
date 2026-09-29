package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;

/**
 * Nacimientos de terneros que no son candidatos a torito: solo cantidad.
 * idCicloProductivo es opcional: si no viene, se toma el que sugiere la
 * fecha dentro de la línea. Si viene y no coincide con el sugerido, queda
 * marcado como ciclo_manual.
 */
public record RegistrarNacimientoRequest(

        @NotNull(message = "la fecha es obligatoria")
        @PastOrPresent(message = "no puede ser una fecha futura")
        LocalDate fecha,

        Boolean fechaEsEstimada,

        @NotBlank(message = "el sexo es obligatorio")
        @Pattern(regexp = "M|H", message = "tiene que ser M o H")
        String sexo,

        @NotNull(message = "la cantidad es obligatoria")
        @Min(value = 1, message = "tiene que ser al menos 1")
        @Max(value = 2000, message = "no puede ser más de 2000 en un solo movimiento")
        Integer cantidad,

        @NotBlank(message = "la línea es obligatoria")
        @Pattern(regexp = "VACA|VAQ", message = "tiene que ser VACA o VAQ")
        String linea,

        Integer idCicloProductivo,

        String observaciones) {
}

package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;

/**
 * Muerte u otra baja de terneros sin caravana. A diferencia de la
 * identificación, no puede dejar el saldo del ciclo en negativo: no pueden
 * morir terneros que el sistema no tiene registrados.
 */
public record RegistrarBajaTernerosRequest(

        @NotBlank(message = "el tipo es obligatorio")
        @Pattern(regexp = "MUERTE|BAJA_OTRA", message = "tiene que ser MUERTE o BAJA_OTRA")
        String tipo,

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

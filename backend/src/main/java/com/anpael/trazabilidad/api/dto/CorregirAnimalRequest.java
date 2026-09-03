package com.anpael.trazabilidad.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.PastOrPresent;

/**
 * Correccion parcial: solo se actualiza lo que viene distinto de null. No
 * hay forma de "borrar" un campo ya cargado con este endpoint -no hace
 * falta todavia, y evita la ambiguedad entre "no mandado" y "poner en
 * null" que tiene JSON con un record tan simple como este.
 */
public record CorregirAnimalRequest(

        Integer idRaza,

        Integer idPelaje,

        @PastOrPresent(message = "no puede ser una fecha futura")
        LocalDate fechaNacimiento,

        Boolean fechaNacEsEstimada,

        @Min(value = 1900, message = "tiene que ser un año válido")
        @Max(value = 2100, message = "tiene que ser un año válido")
        Integer anioNacimiento,

        @Min(value = 1900, message = "tiene que ser un año válido")
        @Max(value = 2100, message = "tiene que ser un año válido")
        Integer anioIngreso,

        @DecimalMin(value = "10", message = "tiene que estar entre 10 y 70 kg")
        @DecimalMax(value = "70", message = "tiene que estar entre 10 y 70 kg")
        BigDecimal pesoNacerKg) {
}

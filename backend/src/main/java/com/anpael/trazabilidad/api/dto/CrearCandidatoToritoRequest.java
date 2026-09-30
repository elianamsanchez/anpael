package com.anpael.trazabilidad.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;

/**
 * Alta de un candidato a torito al nacer: macho, NACIDO, categoría TORITO.
 * La caravana especial se guarda como identificación ADICIONAL; la caravana
 * visual llega después, en el trabajo de identificación.
 */
public record CrearCandidatoToritoRequest(

        @NotBlank(message = "la caravana especial es obligatoria")
        String caravanaAdicional,

        @NotNull(message = "la fecha de nacimiento es obligatoria")
        @PastOrPresent(message = "no puede ser una fecha futura")
        LocalDate fechaNacimiento,

        Boolean fechaNacEsEstimada,

        Integer idMadre,

        Integer idPadre,

        String padreNombre,

        @DecimalMin(value = "10", message = "tiene que estar entre 10 y 70 kg")
        @DecimalMax(value = "70", message = "tiene que estar entre 10 y 70 kg")
        BigDecimal pesoNacerKg,

        Integer idRaza,

        Integer idPelaje,

        Integer idRodeo,

        String observaciones) {
}

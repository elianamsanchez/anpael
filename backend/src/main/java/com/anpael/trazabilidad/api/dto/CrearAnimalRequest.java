package com.anpael.trazabilidad.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PastOrPresent;

/**
 * Alta de un animal nuevo, con identificacion (v0.2a): a diferencia de
 * CorregirAnimalRequest, caravana/sexo/origen son obligatorios porque no hay
 * nada previo que conservar. idCategoria/idRodeo son opcionales: si vienen,
 * se asignan en el mismo pedido en lugar de mandar al usuario a la pantalla
 * de detalle a hacerlo aparte.
 */
public record CrearAnimalRequest(

        @NotBlank(message = "la caravana es obligatoria")
        String caravana,

        @NotBlank(message = "el sexo es obligatorio")
        @Pattern(regexp = "M|H", message = "tiene que ser M o H")
        String sexo,

        @NotBlank(message = "el origen es obligatorio")
        @Pattern(regexp = "NACIDO|COMPRADO|RECIBIDO", message = "tiene que ser NACIDO, COMPRADO o RECIBIDO")
        String origen,

        Integer idRaza,

        Integer idPelaje,

        Integer idCabana,

        Integer idEstabOrigen,

        @PastOrPresent(message = "no puede ser una fecha futura")
        LocalDate fechaNacimiento,

        Boolean fechaNacEsEstimada,

        @DecimalMin(value = "10", message = "tiene que estar entre 10 y 70 kg")
        @DecimalMax(value = "70", message = "tiene que estar entre 10 y 70 kg")
        BigDecimal pesoNacerKg,

        @PastOrPresent(message = "no puede ser una fecha futura")
        LocalDate fechaIngreso,

        Integer idMadre,

        Integer idPadre,

        Integer idCategoria,

        Integer idRodeo) {
}

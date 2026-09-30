package com.anpael.trazabilidad.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;

/**
 * Alta de un animal nuevo, con identificacion (v0.2a): a diferencia de
 * CorregirAnimalRequest, sexo/origen son obligatorios porque no hay nada
 * previo que conservar. La identificación también: la caravana, o en un
 * macho la marca a fuego (hay toros que solo tienen marca a fuego) -lo
 * valida AnimalAltaService-. idCategoria/idRodeo son opcionales: si vienen,
 * se asignan en el mismo pedido en lugar de mandar al usuario a la pantalla
 * de detalle a hacerlo aparte.
 */
public record CrearAnimalRequest(

        String caravana,

        /** Número de la marca a fuego. Solo machos. */
        @Size(max = 30, message = "tiene que tener hasta 30 caracteres")
        String marcaFuego,

        /** Número adicional / interno (por ejemplo, el RP). Machos y hembras. */
        @Size(max = 30, message = "tiene que tener hasta 30 caracteres")
        String numeroAdicional,

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

        @Min(value = 1900, message = "tiene que ser un año válido")
        @Max(value = 2100, message = "tiene que ser un año válido")
        Integer anioNacimiento,

        @DecimalMin(value = "10", message = "tiene que estar entre 10 y 70 kg")
        @DecimalMax(value = "70", message = "tiene que estar entre 10 y 70 kg")
        BigDecimal pesoNacerKg,

        @PastOrPresent(message = "no puede ser una fecha futura")
        LocalDate fechaIngreso,

        @Min(value = 1900, message = "tiene que ser un año válido")
        @Max(value = 2100, message = "tiene que ser un año válido")
        Integer anioIngreso,

        @Min(value = 1900, message = "tiene que ser un año válido")
        @Max(value = 2100, message = "tiene que ser un año válido")
        Integer anioPrimerServicio,

        Integer idMadre,

        Integer idPadre,

        String padreNombre,

        String observaciones,

        Integer idCategoria,

        Integer idRodeo) {
}

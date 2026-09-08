package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotNull;

public record AsignarRodeoRequest(

        @NotNull(message = "es obligatorio")
        Integer idRodeo,

        LocalDate fecha,

        /** true = la fecha es la del saneamiento, no la real en que el animal entró al rodeo. */
        Boolean fechaEsEstimada) {
}

package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotNull;

public record AsignarCategoriaRequest(

        @NotNull(message = "es obligatoria")
        Integer idCategoria,

        // null = hoy. Se resuelve en el controller, no aca: un record no es
        // buen lugar para "current date" porque cada deserializacion lo
        // fijaria en un instante distinto si se pusiera un default aca.
        LocalDate fecha) {
}

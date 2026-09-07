package com.anpael.trazabilidad.api.dto;

import jakarta.validation.constraints.NotNull;

public record AsignarEstablecimientoRequest(

        @NotNull(message = "es obligatorio")
        Integer idEstablecimiento) {
}

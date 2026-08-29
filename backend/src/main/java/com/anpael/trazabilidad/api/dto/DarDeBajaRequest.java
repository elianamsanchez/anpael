package com.anpael.trazabilidad.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record DarDeBajaRequest(

        @NotNull(message = "es obligatoria")
        Integer idCausaBaja,

        LocalDate fecha,

        Boolean fechaEsEstimada,

        @Positive(message = "tiene que ser mayor a 0")
        BigDecimal pesoSalidaKg,

        String destino,

        String observaciones) {
}

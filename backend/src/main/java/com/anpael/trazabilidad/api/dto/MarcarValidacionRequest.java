package com.anpael.trazabilidad.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record MarcarValidacionRequest(

        @NotBlank(message = "es obligatorio")
        @Pattern(regexp = "VALIDADO|CORREGIR|DUDOSO", message = "tiene que ser VALIDADO, CORREGIR o DUDOSO")
        String estado,

        String observacion) {
}

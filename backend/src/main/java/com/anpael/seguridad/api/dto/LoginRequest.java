package com.anpael.seguridad.api.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(

        @NotBlank(message = "es obligatorio")
        String usuario,

        @NotBlank(message = "es obligatoria")
        String password) {
}

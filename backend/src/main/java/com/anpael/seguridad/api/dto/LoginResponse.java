package com.anpael.seguridad.api.dto;

import java.time.OffsetDateTime;

public record LoginResponse(
        String token,
        OffsetDateTime expiraEn,
        String nombre,
        String rol) {
}

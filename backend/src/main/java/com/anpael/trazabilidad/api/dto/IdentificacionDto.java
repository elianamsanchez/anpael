package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;

public record IdentificacionDto(String tipoIdent, String caravana, LocalDate fechaAlta, Boolean fechaAltaEsEstimada) {
}

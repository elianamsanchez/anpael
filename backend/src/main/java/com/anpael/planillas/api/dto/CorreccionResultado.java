package com.anpael.planillas.api.dto;

import com.anpael.trazabilidad.domain.AnimalEvento;

public record CorreccionResultado(String mensaje, AnimalEvento evento) {
}

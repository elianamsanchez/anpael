package com.anpael.planillas.api.dto;

/** Actualizacion parcial: solo se pisa lo que venga distinto de null. */
public record CorregirTactoRequest(String resultado, String tamano, String observaciones) {
}

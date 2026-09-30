package com.anpael.trazabilidad.api.dto;

/**
 * Anular un movimiento, o reasignarlo a otro ciclo. idCicloProductivo solo
 * se usa al reasignar. observaciones = por qué se corrige: queda en la
 * ANULACION.
 */
public record CorregirMovimientoTernerosRequest(Integer idCicloProductivo, String observaciones) {
}

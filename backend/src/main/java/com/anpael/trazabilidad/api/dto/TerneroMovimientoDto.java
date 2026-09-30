package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;

/** Una fila de v_ternero_sin_identificar_mov: el movimiento con su efecto sobre el saldo (delta). */
public record TerneroMovimientoDto(
        Integer idMov,
        Integer idCicloProductivo,
        String ciclo,
        String linea,
        Boolean cicloManual,
        LocalDate fechaEvento,
        Boolean fechaEsEstimada,
        OffsetDateTime fechaRegistro,
        String sexo,
        Integer cantidad,
        String tipo,
        Integer idMovAnulado,
        Integer idTrabajo,
        Boolean excedeSaldo,
        String observaciones,
        String registradoPor,
        Boolean anulado,
        Integer delta) {
}

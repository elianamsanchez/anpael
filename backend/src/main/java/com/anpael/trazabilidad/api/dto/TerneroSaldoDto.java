package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;

/**
 * Una fila de v_ternero_sin_identificar_saldo. nivel = 'CICLO' (una por ciclo
 * y sexo) o 'TOTAL' (por sexo, o general con sexo null). saldo negativo =
 * se identificaron más terneros que los nacimientos cargados en ese ciclo.
 */
public record TerneroSaldoDto(
        String nivel,
        Integer idCicloProductivo,
        String ciclo,
        String linea,
        LocalDate paricionDesde,
        LocalDate fechaFin,
        String sexo,
        Long nacidos,
        Long identificados,
        Long muertes,
        Long otrasBajas,
        Long saldo,
        Boolean cicloCerrado) {
}

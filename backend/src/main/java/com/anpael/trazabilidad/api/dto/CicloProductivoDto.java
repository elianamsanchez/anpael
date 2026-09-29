package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;

import com.anpael.trazabilidad.domain.CicloProductivo;

public record CicloProductivoDto(
        Integer idCicloProductivo,
        String codigo,
        String linea,
        LocalDate fechaInicio,
        LocalDate paricionDesde,
        LocalDate paricionHasta,
        LocalDate fechaFin,
        String observaciones) {

    public static CicloProductivoDto de(CicloProductivo c) {
        return new CicloProductivoDto(c.getIdCicloProductivo(), c.getCodigo(), c.getLinea(), c.getFechaInicio(),
                c.getParicionDesde(), c.getParicionHasta(), c.getFechaFin(), c.getObservaciones());
    }

    /**
     * El año de nacimiento de un ternero de este ciclo: el último año del
     * código ('2025-26' -> 2026), que es el año en que empieza la parición.
     */
    public int anioNacimiento() {
        return paricionDesde.getYear();
    }
}

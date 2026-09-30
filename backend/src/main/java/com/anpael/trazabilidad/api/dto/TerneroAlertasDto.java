package com.anpael.trazabilidad.api.dto;

import java.time.LocalDate;
import java.util.List;

/**
 * Lo que tiene que quedar a la vista aunque no sea un error:
 * ciclos terminados con saldo distinto de cero, y movimientos cuya fecha cae
 * fuera del ciclo al que se cargaron.
 */
public record TerneroAlertasDto(List<CicloCerrado> ciclosCerrados, List<FueraDeCiclo> fueraDeCiclo) {

    public record CicloCerrado(Integer idCicloProductivo, String ciclo, String linea, LocalDate fechaFin,
            String sexo, Long saldo) {
    }

    public record FueraDeCiclo(Integer idMov, String tipo, LocalDate fechaEvento, String sexo, Integer cantidad,
            String ciclo, Boolean cicloManual, LocalDate fechaInicio, LocalDate fechaFin) {
    }
}

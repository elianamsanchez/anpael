package com.anpael.planillas.api.dto;

import java.util.List;

public record CargaIdentificacionResumen(
        String mensaje,
        Integer idTrabajo,
        int animalesCreados,
        int toritosIdentificados,
        List<Descuento> descuentos) {

    /** Lo que se descontó de la cantidad pendiente de un ciclo y sexo. */
    public record Descuento(Integer idCicloProductivo, String ciclo, String sexo, int cantidad, boolean excedeSaldo) {
    }
}

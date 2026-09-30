package com.anpael.planillas.api.dto;

import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;

/**
 * Trabajo de identificación (transcripción de la planilla). Dos cosas distintas:
 *   - grupos: terneros que se llevaban como cantidad. Cada caravana crea un
 *     animal, y cada grupo descuenta sus caravanas de la cantidad pendiente de
 *     SU ciclo y sexo. Puede haber grupos de ciclos distintos en el mismo trabajo.
 *   - toritos: candidatos a torito que ya son animales. Se les agrega la
 *     caravana visual; no tocan la cantidad pendiente.
 *
 * confirmarExcesoSaldo: si un grupo tiene más caravanas que el saldo de su
 * ciclo, sin esto no se carga nada; con esto se carga y queda marcado.
 * idRodeo (opcional): rodeo del trabajo y de los animales nuevos.
 */
public record CargarIdentificacionRequest(

        @NotNull(message = "la fecha es obligatoria")
        @PastOrPresent(message = "no puede ser una fecha futura")
        LocalDate fecha,

        Integer idRodeo,

        @Valid
        List<Grupo> grupos,

        @Valid
        List<Torito> toritos,

        Boolean confirmarExcesoSaldo,

        String observaciones) {

    public record Grupo(

            @NotNull(message = "el ciclo es obligatorio")
            Integer idCicloProductivo,

            @NotBlank(message = "el sexo es obligatorio")
            @Pattern(regexp = "M|H", message = "tiene que ser M o H")
            String sexo,

            @NotEmpty(message = "tiene que tener al menos una caravana")
            List<@NotBlank(message = "la caravana no puede estar vacía") String> caravanas) {
    }

    public record Torito(

            @NotNull(message = "el animal es obligatorio")
            Integer idAnimal,

            @NotBlank(message = "la caravana es obligatoria")
            String caravana) {
    }
}

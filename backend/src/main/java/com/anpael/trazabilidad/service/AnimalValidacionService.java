package com.anpael.trazabilidad.service;

import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.security.ContextoAutenticacion;
import com.anpael.trazabilidad.domain.AnimalValidacion;
import com.anpael.trazabilidad.infrastructure.AnimalValidacionRepository;

/**
 * Marca la revisión de saneamiento de un animal (ADR-004): VALIDADO,
 * CORREGIR o DUDOSO, con quién y cuándo. Reemplaza a santa_ana_v02.html, que
 * hacía esto mismo por fuera de la app.
 *
 * Una fila por animal -upsert-, no historial: revisar de nuevo pisa la
 * marca anterior.
 */
@Service
public class AnimalValidacionService {

    private final AnimalValidacionRepository validaciones;

    public AnimalValidacionService(AnimalValidacionRepository validaciones) {
        this.validaciones = validaciones;
    }

    @Transactional
    public String marcar(Integer idAnimal, String estado, String observacion) {
        Optional<AnimalValidacion> existente = validaciones.findById(idAnimal);
        AnimalValidacion validacion = existente.orElseGet(AnimalValidacion::new);
        validacion.setIdAnimal(idAnimal);
        validacion.setEstado(estado);
        validacion.setObservacion(observacion);
        validacion.setIdPersona(ContextoAutenticacion.idPersonaActual());
        validaciones.save(validacion);

        return switch (estado) {
            case "VALIDADO" -> "Marcado como validado.";
            case "CORREGIR" -> "Marcado para corregir.";
            default -> "Marcado como dudoso.";
        };
    }
}

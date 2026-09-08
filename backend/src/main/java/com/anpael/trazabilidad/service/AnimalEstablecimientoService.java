package com.anpael.trazabilidad.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.domain.Establecimiento;
import com.anpael.trazabilidad.domain.Identificacion;
import com.anpael.trazabilidad.infrastructure.EstablecimientoRepository;
import com.anpael.trazabilidad.infrastructure.IdentificacionRepository;

/**
 * Asigna o corrige el establecimiento (y con él, el CUIG) de un animal.
 * El CUIG no es un campo del animal: sale de identificacion.id_establecimiento
 * (docs/modelo-datos.md), así que "asignar cuig" es en realidad completar o
 * corregir ese dato en su identificación vigente.
 *
 * Corregir uno ya cargado es válido -por ejemplo, un animal que quedó
 * unificado a PC269 por mig_17_unificar_cuig.sql ("es el mismo campo, otra
 * sociedad") pero en realidad corresponde puntualmente a Al154-.
 *
 * Actualiza TODAS las identificaciones vigentes del animal, no solo la
 * principal: los toros suelen tener FUEGO y VISUAL a la vez, migradas con
 * el mismo establecimiento en las dos filas (docs/modelo-datos.md), y
 * corregir solo una dejaría la otra con el dato viejo.
 */
@Service
public class AnimalEstablecimientoService {

    private final IdentificacionRepository identificaciones;
    private final EstablecimientoRepository establecimientos;

    public AnimalEstablecimientoService(IdentificacionRepository identificaciones,
            EstablecimientoRepository establecimientos) {
        this.identificaciones = identificaciones;
        this.establecimientos = establecimientos;
    }

    @Transactional
    public String asignar(Integer idAnimal, Integer idEstablecimiento) {
        Establecimiento establecimiento = establecimientos.findById(idEstablecimiento)
                .orElseThrow(() -> new ReglaDeNegocioException("El establecimiento " + idEstablecimiento + " no existe."));

        List<Identificacion> vigentes = identificaciones.findByIdAnimalAndFechaBajaIsNull(idAnimal);
        if (vigentes.isEmpty()) {
            throw new ReglaDeNegocioException("El animal no tiene una identificación vigente para asignarle un establecimiento.");
        }

        boolean huboCambio = false;
        boolean esCorreccion = false;
        for (Identificacion identificacion : vigentes) {
            Integer actual = identificacion.getIdEstablecimiento();
            if (idEstablecimiento.equals(actual)) {
                continue;
            }
            huboCambio = true;
            esCorreccion = esCorreccion || actual != null;
            identificacion.setIdEstablecimiento(idEstablecimiento);
            identificaciones.save(identificacion);
        }

        if (!huboCambio) {
            return "Sin cambios: ya estaba asignado a " + establecimiento.getNombre() + ".";
        }
        return (esCorreccion ? "Corregido a " : "Asignado a ") + establecimiento.getNombre()
                + " (" + establecimiento.getCuig() + ").";
    }
}

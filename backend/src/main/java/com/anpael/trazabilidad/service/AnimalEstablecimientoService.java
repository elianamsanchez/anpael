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
 * Asigna el establecimiento (y con él, el CUIG) a un animal que no lo tiene.
 * El CUIG no es un campo del animal: sale de identificacion.id_establecimiento
 * (docs/modelo-datos.md), así que "asignar cuig" es en realidad completar ese
 * dato en su identificación vigente.
 *
 * A propósito solo completa lo que falta -no corrige un establecimiento ya
 * cargado-: si hubiera que corregirlo, el origen del animal cambió de
 * verdad, y eso es una decisión aparte, no un fix de datos.
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
        if (vigentes.size() > 1) {
            throw new ReglaDeNegocioException(
                    "El animal tiene más de una identificación vigente; no se puede elegir cuál actualizar.");
        }

        Identificacion identificacion = vigentes.get(0);
        if (identificacion.getIdEstablecimiento() != null) {
            throw new ReglaDeNegocioException("Este animal ya tiene un establecimiento asignado.");
        }

        identificacion.setIdEstablecimiento(idEstablecimiento);
        identificaciones.save(identificacion);

        return "Asignado a " + establecimiento.getNombre() + " (" + establecimiento.getCuig() + ").";
    }
}

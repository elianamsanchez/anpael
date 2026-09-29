package com.anpael.trazabilidad.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.domain.Establecimiento;
import com.anpael.trazabilidad.infrastructure.EstablecimientoRepository;

/**
 * El establecimiento propio activo (Santa Ana): el supuesto de un único campo
 * de trabajo que ya usaba AnimalAltaService. Público para que planillas
 * pueda crear un trabajo sin rodeo (identificación de terneros).
 */
@Service
@Transactional(readOnly = true)
public class EstablecimientoPropioService {

    private final EstablecimientoRepository establecimientos;

    public EstablecimientoPropioService(EstablecimientoRepository establecimientos) {
        this.establecimientos = establecimientos;
    }

    public Establecimiento obtener() {
        List<Establecimiento> propios = establecimientos.findByEsPropioTrueAndActivoTrue();
        if (propios.size() != 1) {
            throw new ReglaDeNegocioException(
                    "No se pudo determinar el establecimiento propio activo (hay " + propios.size() + "). "
                            + "Revisar la tabla establecimiento.");
        }
        return propios.get(0);
    }

    public Integer obtenerId() {
        return obtener().getIdEstablecimiento();
    }
}

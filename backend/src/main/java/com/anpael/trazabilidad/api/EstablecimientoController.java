package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.Establecimiento;
import com.anpael.trazabilidad.infrastructure.EstablecimientoRepository;

/** Catálogo para el combo de "establecimiento de origen" al dar de alta un animal comprado o recibido. */
@RestController
@RequestMapping("/api/establecimientos")
public class EstablecimientoController {

    private final EstablecimientoRepository establecimientos;

    public EstablecimientoController(EstablecimientoRepository establecimientos) {
        this.establecimientos = establecimientos;
    }

    @GetMapping
    public List<Establecimiento> listar() {
        return establecimientos.findAllByActivoTrueOrderByNombreAsc();
    }
}

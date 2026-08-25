package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.Rodeo;
import com.anpael.trazabilidad.infrastructure.RodeoRepository;

/** Catálogo para el combo de "asignar rodeo" (v0.2a). Solo los activos. */
@RestController
@RequestMapping("/api/rodeos")
public class RodeoController {

    private final RodeoRepository rodeos;

    public RodeoController(RodeoRepository rodeos) {
        this.rodeos = rodeos;
    }

    @GetMapping
    public List<Rodeo> listar() {
        return rodeos.findAllByActivoTrueOrderByNombreAsc();
    }
}

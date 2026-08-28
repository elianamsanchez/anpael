package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.Cabana;
import com.anpael.trazabilidad.infrastructure.CabanaRepository;

/** Catálogo para el combo de "cabaña de origen" al dar de alta un animal comprado. */
@RestController
@RequestMapping("/api/cabanas")
public class CabanaController {

    private final CabanaRepository cabanas;

    public CabanaController(CabanaRepository cabanas) {
        this.cabanas = cabanas;
    }

    @GetMapping
    public List<Cabana> listar() {
        return cabanas.findAllByOrderByNombreAsc();
    }
}

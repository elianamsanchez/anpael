package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.Pelaje;
import com.anpael.trazabilidad.infrastructure.PelajeRepository;

/** Catálogo para el combo de "corregir pelaje" (v0.2a). */
@RestController
@RequestMapping("/api/pelajes")
public class PelajeController {

    private final PelajeRepository pelajes;

    public PelajeController(PelajeRepository pelajes) {
        this.pelajes = pelajes;
    }

    @GetMapping
    public List<Pelaje> listar() {
        return pelajes.findAllByOrderByNombreAsc();
    }
}

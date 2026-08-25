package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.Raza;
import com.anpael.trazabilidad.infrastructure.RazaRepository;

/** Catálogo para el combo de "corregir raza" (v0.2a). */
@RestController
@RequestMapping("/api/razas")
public class RazaController {

    private final RazaRepository razas;

    public RazaController(RazaRepository razas) {
        this.razas = razas;
    }

    @GetMapping
    public List<Raza> listar() {
        return razas.findAllByOrderByNombreAsc();
    }
}

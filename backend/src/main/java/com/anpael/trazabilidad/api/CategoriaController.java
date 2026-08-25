package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.Categoria;
import com.anpael.trazabilidad.infrastructure.CategoriaRepository;

/** Catálogo para el combo de "asignar categoría" (v0.2a). */
@RestController
@RequestMapping("/api/categorias")
public class CategoriaController {

    private final CategoriaRepository categorias;

    public CategoriaController(CategoriaRepository categorias) {
        this.categorias = categorias;
    }

    @GetMapping
    public List<Categoria> listar() {
        return categorias.findAllByOrderByOrdenAsc();
    }
}

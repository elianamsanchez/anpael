package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.AnimalLista;
import com.anpael.trazabilidad.domain.Rodeo;
import com.anpael.trazabilidad.infrastructure.RodeoRepository;
import com.anpael.trazabilidad.service.AnimalService;

/** Catálogo para el combo de "asignar rodeo" (v0.2a). Solo los activos. */
@RestController
@RequestMapping("/api/rodeos")
public class RodeoController {

    private final RodeoRepository rodeos;
    private final AnimalService animalService;

    public RodeoController(RodeoRepository rodeos, AnimalService animalService) {
        this.rodeos = rodeos;
        this.animalService = animalService;
    }

    @GetMapping
    public List<Rodeo> listar() {
        return rodeos.findAllByActivoTrueOrderByNombreAsc();
    }

    /** Los animales vigentes del rodeo, ordenados por caravana. Lo usa la carga de resultados (v0.2b). */
    @GetMapping("/{idRodeo}/animales")
    public List<AnimalLista> listarAnimales(@PathVariable Integer idRodeo) {
        return animalService.buscarPorRodeo(idRodeo);
    }
}

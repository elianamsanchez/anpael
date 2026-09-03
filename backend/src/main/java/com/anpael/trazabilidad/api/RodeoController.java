package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.AnimalLista;
import com.anpael.trazabilidad.domain.Rodeo;
import com.anpael.trazabilidad.service.AnimalService;
import com.anpael.trazabilidad.service.RodeoService;

/** Catálogo para el combo de "asignar rodeo" (v0.2a). Solo los activos. */
@RestController
@RequestMapping("/api/rodeos")
public class RodeoController {

    private final RodeoService rodeoService;
    private final AnimalService animalService;

    public RodeoController(RodeoService rodeoService, AnimalService animalService) {
        this.rodeoService = rodeoService;
        this.animalService = animalService;
    }

    /** Sin idCategoria: todos los rodeos activos. Con idCategoria: solo los que la admiten (rodeo_categoria). */
    @GetMapping
    public List<Rodeo> listar(@RequestParam(required = false) Integer idCategoria) {
        return rodeoService.listar(idCategoria);
    }

    /** Los animales vigentes del rodeo, ordenados por caravana. Lo usa la carga de resultados (v0.2b). */
    @GetMapping("/{idRodeo}/animales")
    public List<AnimalLista> listarAnimales(@PathVariable Integer idRodeo) {
        return animalService.buscarPorRodeo(idRodeo);
    }
}

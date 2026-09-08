package com.anpael.trazabilidad.api;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.api.dto.AsignacionResultado;
import com.anpael.trazabilidad.api.dto.AsignarCategoriaRequest;
import com.anpael.trazabilidad.api.dto.AsignarEstablecimientoRequest;
import com.anpael.trazabilidad.api.dto.AsignarRodeoRequest;
import com.anpael.trazabilidad.api.dto.CorregirAnimalRequest;
import com.anpael.trazabilidad.api.dto.CrearAnimalRequest;
import com.anpael.trazabilidad.api.dto.DarDeBajaRequest;
import com.anpael.trazabilidad.api.dto.IdentificacionDto;
import com.anpael.trazabilidad.api.dto.MarcarValidacionRequest;
import com.anpael.trazabilidad.domain.AnimalEvento;
import com.anpael.trazabilidad.domain.AnimalLista;
import com.anpael.trazabilidad.service.AnimalAltaService;
import com.anpael.trazabilidad.service.AnimalBajaService;
import com.anpael.trazabilidad.service.AnimalCategoriaService;
import com.anpael.trazabilidad.service.AnimalCorreccionService;
import com.anpael.trazabilidad.service.AnimalEstablecimientoService;
import com.anpael.trazabilidad.service.AnimalRodeoService;
import com.anpael.trazabilidad.service.AnimalService;
import com.anpael.trazabilidad.service.AnimalValidacionService;

import jakarta.validation.Valid;

/**
 * Padron para el saneamiento (v0.2a, docs/etapas.md): buscar un animal, ver
 * todo lo que se sabe de el, asignarle categoria/rodeo, corregir sus datos,
 * y darlo de baja.
 */
@RestController
@RequestMapping("/api/animales")
public class AnimalController {

    private final AnimalService animalService;
    private final AnimalCategoriaService animalCategoriaService;
    private final AnimalRodeoService animalRodeoService;
    private final AnimalBajaService animalBajaService;
    private final AnimalCorreccionService animalCorreccionService;
    private final AnimalAltaService animalAltaService;
    private final AnimalValidacionService animalValidacionService;
    private final AnimalEstablecimientoService animalEstablecimientoService;

    public AnimalController(AnimalService animalService, AnimalCategoriaService animalCategoriaService,
            AnimalRodeoService animalRodeoService, AnimalBajaService animalBajaService,
            AnimalCorreccionService animalCorreccionService, AnimalAltaService animalAltaService,
            AnimalValidacionService animalValidacionService, AnimalEstablecimientoService animalEstablecimientoService) {
        this.animalService = animalService;
        this.animalCategoriaService = animalCategoriaService;
        this.animalRodeoService = animalRodeoService;
        this.animalBajaService = animalBajaService;
        this.animalCorreccionService = animalCorreccionService;
        this.animalAltaService = animalAltaService;
        this.animalValidacionService = animalValidacionService;
        this.animalEstablecimientoService = animalEstablecimientoService;
    }

    @PostMapping
    public AnimalLista crear(@Valid @RequestBody CrearAnimalRequest pedido) {
        Integer idAnimal = animalAltaService.crear(pedido);
        return animalService.obtener(idAnimal);
    }

    @GetMapping
    public Page<AnimalLista> buscar(
            @RequestParam(required = false) String caravana,
            @RequestParam(required = false) Boolean sinCategoria,
            @RequestParam(required = false) Boolean sinRodeo,
            @RequestParam(required = false) Integer idRodeo,
            @RequestParam(required = false) Integer idCategoria,
            @PageableDefault(size = 50, sort = "caravana") Pageable pageable) {
        return animalService.buscar(caravana, sinCategoria, sinRodeo, idRodeo, idCategoria, pageable);
    }

    @GetMapping("/{idAnimal}")
    public AnimalLista detalle(@PathVariable Integer idAnimal) {
        return animalService.obtener(idAnimal);
    }

    @GetMapping("/{idAnimal}/historial")
    public List<AnimalEvento> historial(@PathVariable Integer idAnimal) {
        return animalService.historial(idAnimal);
    }

    @GetMapping("/{idAnimal}/identificaciones")
    public List<IdentificacionDto> identificaciones(@PathVariable Integer idAnimal) {
        return animalService.identificaciones(idAnimal);
    }

    @PostMapping("/{idAnimal}/categoria")
    public AsignacionResultado asignarCategoria(@PathVariable Integer idAnimal,
            @Valid @RequestBody AsignarCategoriaRequest pedido) {
        animalService.obtener(idAnimal); // 404 antes de tocar la base, no un FK roto
        String mensaje = animalCategoriaService.asignar(idAnimal, pedido.idCategoria(),
                pedido.fecha() != null ? pedido.fecha() : LocalDate.now());
        return new AsignacionResultado(mensaje, animalService.obtener(idAnimal));
    }

    @PostMapping("/{idAnimal}/rodeo")
    public AsignacionResultado asignarRodeo(@PathVariable Integer idAnimal,
            @Valid @RequestBody AsignarRodeoRequest pedido) {
        animalService.obtener(idAnimal);
        String mensaje = animalRodeoService.asignar(idAnimal, pedido.idRodeo(),
                pedido.fecha() != null ? pedido.fecha() : LocalDate.now(), pedido.fechaEsEstimada());
        return new AsignacionResultado(mensaje, animalService.obtener(idAnimal));
    }

    @PostMapping("/{idAnimal}/establecimiento")
    public AsignacionResultado asignarEstablecimiento(@PathVariable Integer idAnimal,
            @Valid @RequestBody AsignarEstablecimientoRequest pedido) {
        animalService.obtener(idAnimal);
        String mensaje = animalEstablecimientoService.asignar(idAnimal, pedido.idEstablecimiento());
        return new AsignacionResultado(mensaje, animalService.obtener(idAnimal));
    }

    @PostMapping("/{idAnimal}/validacion")
    public AsignacionResultado marcarValidacion(@PathVariable Integer idAnimal,
            @Valid @RequestBody MarcarValidacionRequest pedido) {
        animalService.obtener(idAnimal);
        String mensaje = animalValidacionService.marcar(idAnimal, pedido.estado(), pedido.observacion());
        return new AsignacionResultado(mensaje, animalService.obtener(idAnimal));
    }

    @PatchMapping("/{idAnimal}")
    public AnimalLista corregir(@PathVariable Integer idAnimal, @Valid @RequestBody CorregirAnimalRequest pedido) {
        animalCorreccionService.corregir(idAnimal, pedido);
        return animalService.obtener(idAnimal);
    }

    @PostMapping("/{idAnimal}/baja")
    public AsignacionResultado darDeBaja(@PathVariable Integer idAnimal,
            @Valid @RequestBody DarDeBajaRequest pedido) {
        animalService.obtener(idAnimal);
        String mensaje = animalBajaService.darDeBaja(idAnimal, pedido.idCausaBaja(),
                pedido.fecha() != null ? pedido.fecha() : LocalDate.now(), pedido.fechaEsEstimada(),
                pedido.pesoSalidaKg(), pedido.destino(), pedido.observaciones());
        return new AsignacionResultado(mensaje, animalService.obtener(idAnimal));
    }
}

package com.anpael.planillas.api;

import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.planillas.api.dto.CorreccionResultado;
import com.anpael.planillas.api.dto.CorregirPesadaRequest;
import com.anpael.planillas.api.dto.CorregirRevisionTorosRequest;
import com.anpael.planillas.api.dto.CorregirSanidadRequest;
import com.anpael.planillas.api.dto.CorregirTactoRequest;
import com.anpael.planillas.service.EditarResultadosService;
import com.anpael.trazabilidad.service.AnimalService;

import jakarta.validation.Valid;

/** Corregir un trabajo ya cargado (v0.2b, docs/etapas.md). */
@RestController
@RequestMapping("/api/eventos")
public class EditarResultadosController {

    private final EditarResultadosService editarResultadosService;
    private final AnimalService animalService;

    public EditarResultadosController(EditarResultadosService editarResultadosService, AnimalService animalService) {
        this.editarResultadosService = editarResultadosService;
        this.animalService = animalService;
    }

    @PatchMapping("/{idEvento}/tacto")
    public CorreccionResultado corregirTacto(@PathVariable Integer idEvento,
            @Valid @RequestBody CorregirTactoRequest pedido) {
        editarResultadosService.corregirTacto(idEvento, pedido);
        return resultado(idEvento);
    }

    @PatchMapping("/{idEvento}/pesada")
    public CorreccionResultado corregirPesada(@PathVariable Integer idEvento,
            @Valid @RequestBody CorregirPesadaRequest pedido) {
        editarResultadosService.corregirPesada(idEvento, pedido);
        return resultado(idEvento);
    }

    @PatchMapping("/{idEvento}/revision-toros")
    public CorreccionResultado corregirRevisionToros(@PathVariable Integer idEvento,
            @Valid @RequestBody CorregirRevisionTorosRequest pedido) {
        editarResultadosService.corregirRevisionToros(idEvento, pedido);
        return resultado(idEvento);
    }

    @PatchMapping("/{idEvento}/sanidad")
    public CorreccionResultado corregirSanidad(@PathVariable Integer idEvento,
            @Valid @RequestBody CorregirSanidadRequest pedido) {
        editarResultadosService.corregirSanidad(idEvento, pedido);
        return resultado(idEvento);
    }

    private CorreccionResultado resultado(Integer idEvento) {
        return new CorreccionResultado("Resultado corregido.", animalService.obtenerEvento(idEvento));
    }
}

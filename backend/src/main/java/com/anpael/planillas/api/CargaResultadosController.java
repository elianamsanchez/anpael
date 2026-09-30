package com.anpael.planillas.api;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.planillas.api.dto.CargaIdentificacionResumen;
import com.anpael.planillas.api.dto.CargaResultadosResumen;
import com.anpael.planillas.api.dto.CargarIdentificacionRequest;
import com.anpael.planillas.api.dto.CargarPesadaRequest;
import com.anpael.planillas.api.dto.CargarRevisionTorosRequest;
import com.anpael.planillas.api.dto.CargarSanidadRequest;
import com.anpael.planillas.api.dto.CargarTactoRequest;
import com.anpael.planillas.service.CargaIdentificacionService;
import com.anpael.planillas.service.CargaResultadosService;

import jakarta.validation.Valid;

/** Cargar los resultados de una planilla ya trabajada (v0.2b, docs/etapas.md). */
@RestController
@RequestMapping("/api/trabajos")
public class CargaResultadosController {

    private final CargaResultadosService cargaResultadosService;
    private final CargaIdentificacionService cargaIdentificacionService;

    public CargaResultadosController(CargaResultadosService cargaResultadosService,
            CargaIdentificacionService cargaIdentificacionService) {
        this.cargaResultadosService = cargaResultadosService;
        this.cargaIdentificacionService = cargaIdentificacionService;
    }

    @PostMapping("/tacto")
    public CargaResultadosResumen cargarTacto(@Valid @RequestBody CargarTactoRequest pedido) {
        return cargaResultadosService.cargarTacto(pedido);
    }

    @PostMapping("/pesada")
    public CargaResultadosResumen cargarPesada(@Valid @RequestBody CargarPesadaRequest pedido) {
        return cargaResultadosService.cargarPesada(pedido);
    }

    @PostMapping("/revision-toros")
    public CargaResultadosResumen cargarRevisionToros(@Valid @RequestBody CargarRevisionTorosRequest pedido) {
        return cargaResultadosService.cargarRevisionToros(pedido);
    }

    @PostMapping("/sanidad")
    public CargaResultadosResumen cargarSanidad(@Valid @RequestBody CargarSanidadRequest pedido) {
        return cargaResultadosService.cargarSanidad(pedido);
    }

    /** Identificación de terneros: crea los animales y descuenta la cantidad pendiente por ciclo. */
    @PostMapping("/identificacion")
    public CargaIdentificacionResumen cargarIdentificacion(@Valid @RequestBody CargarIdentificacionRequest pedido) {
        return cargaIdentificacionService.cargar(pedido);
    }
}

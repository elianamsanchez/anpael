package com.anpael.planillas.api;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.planillas.api.dto.CargaResultadosResumen;
import com.anpael.planillas.api.dto.CargarPesadaRequest;
import com.anpael.planillas.api.dto.CargarRevisionTorosRequest;
import com.anpael.planillas.api.dto.CargarSanidadRequest;
import com.anpael.planillas.api.dto.CargarTactoRequest;
import com.anpael.planillas.service.CargaResultadosService;

import jakarta.validation.Valid;

/** Cargar los resultados de una planilla ya trabajada (v0.2b, docs/etapas.md). */
@RestController
@RequestMapping("/api/trabajos")
public class CargaResultadosController {

    private final CargaResultadosService cargaResultadosService;

    public CargaResultadosController(CargaResultadosService cargaResultadosService) {
        this.cargaResultadosService = cargaResultadosService;
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
}

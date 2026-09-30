package com.anpael.trazabilidad.api;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.api.dto.CicloProductivoDto;
import com.anpael.trazabilidad.api.dto.GuardarCicloProductivoRequest;
import com.anpael.trazabilidad.service.CicloProductivoService;

import jakarta.validation.Valid;

/** Ciclos productivos: catálogo editable (migración 20260929120000). */
@RestController
@RequestMapping("/api/ciclos-productivos")
public class CicloProductivoController {

    private final CicloProductivoService cicloService;

    public CicloProductivoController(CicloProductivoService cicloService) {
        this.cicloService = cicloService;
    }

    @GetMapping
    public List<CicloProductivoDto> listar() {
        return cicloService.listar();
    }

    /** El ciclo de la línea al que pertenece la fecha. 204 si no cae en ninguno. */
    @GetMapping("/sugerido")
    public ResponseEntity<CicloProductivoDto> sugerido(@RequestParam String linea,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha) {
        return cicloService.sugerido(linea, fecha)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping
    public CicloProductivoDto crear(@Valid @RequestBody GuardarCicloProductivoRequest pedido) {
        return cicloService.crear(pedido);
    }

    @PutMapping("/{idCicloProductivo}")
    public CicloProductivoDto editar(@PathVariable Integer idCicloProductivo,
            @Valid @RequestBody GuardarCicloProductivoRequest pedido) {
        return cicloService.editar(idCicloProductivo, pedido);
    }
}

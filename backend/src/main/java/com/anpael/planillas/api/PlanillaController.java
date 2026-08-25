package com.anpael.planillas.api;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.planillas.service.PlanillaService;

/** El generador de planillas (v0.2b, docs/etapas.md). */
@RestController
@RequestMapping("/api/planillas")
public class PlanillaController {

    private final PlanillaService planillaService;

    public PlanillaController(PlanillaService planillaService) {
        this.planillaService = planillaService;
    }

    @GetMapping
    public ResponseEntity<byte[]> generar(@RequestParam Integer idRodeo, @RequestParam String tipoTrabajo) {
        byte[] pdf = planillaService.generar(idRodeo, tipoTrabajo);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"planilla.pdf\"")
                .body(pdf);
    }
}

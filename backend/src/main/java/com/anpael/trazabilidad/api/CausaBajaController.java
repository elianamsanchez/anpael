package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.domain.CausaBaja;
import com.anpael.trazabilidad.infrastructure.CausaBajaRepository;

/** Catálogo para el combo de "dar de baja" (v0.2a). */
@RestController
@RequestMapping("/api/causas-baja")
public class CausaBajaController {

    private final CausaBajaRepository causasBaja;

    public CausaBajaController(CausaBajaRepository causasBaja) {
        this.causasBaja = causasBaja;
    }

    @GetMapping
    public List<CausaBaja> listar() {
        return causasBaja.findAllByOrderByDescripcionAsc();
    }
}

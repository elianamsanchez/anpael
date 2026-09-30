package com.anpael.trazabilidad.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.trazabilidad.api.dto.CorregirMovimientoTernerosRequest;
import com.anpael.trazabilidad.api.dto.RegistrarBajaTernerosRequest;
import com.anpael.trazabilidad.api.dto.RegistrarNacimientoRequest;
import com.anpael.trazabilidad.api.dto.TerneroAlertasDto;
import com.anpael.trazabilidad.api.dto.TerneroMovimientoDto;
import com.anpael.trazabilidad.api.dto.TerneroSaldoDto;
import com.anpael.trazabilidad.service.TerneroSinIdentificarService;

import jakarta.validation.Valid;

/**
 * Terneros nacidos sin caravana, por ciclo productivo. La identificación no
 * está acá: se carga como trabajo en /api/trabajos/identificacion (planillas),
 * que crea los animales y descuenta la cantidad en la misma transacción.
 */
@RestController
@RequestMapping("/api/terneros-sin-identificar")
public class TerneroSinIdentificarController {

    private final TerneroSinIdentificarService terneroService;

    public TerneroSinIdentificarController(TerneroSinIdentificarService terneroService) {
        this.terneroService = terneroService;
    }

    @GetMapping("/saldo")
    public List<TerneroSaldoDto> saldo() {
        return terneroService.saldo();
    }

    @GetMapping("/movimientos")
    public List<TerneroMovimientoDto> movimientos(@RequestParam(required = false) Integer idCicloProductivo) {
        return terneroService.movimientos(idCicloProductivo);
    }

    @GetMapping("/alertas")
    public TerneroAlertasDto alertas() {
        return terneroService.alertas();
    }

    @PostMapping("/nacimientos")
    public TerneroMovimientoDto registrarNacimiento(@Valid @RequestBody RegistrarNacimientoRequest pedido) {
        return terneroService.registrarNacimiento(pedido);
    }

    @PostMapping("/bajas")
    public TerneroMovimientoDto registrarBaja(@Valid @RequestBody RegistrarBajaTernerosRequest pedido) {
        return terneroService.registrarBaja(pedido);
    }

    @PostMapping("/movimientos/{idMov}/anulacion")
    public TerneroMovimientoDto anular(@PathVariable Integer idMov,
            @RequestBody(required = false) CorregirMovimientoTernerosRequest pedido) {
        return terneroService.anular(idMov, pedido != null ? pedido.observaciones() : null);
    }

    @PostMapping("/movimientos/{idMov}/reasignacion")
    public TerneroMovimientoDto reasignarCiclo(@PathVariable Integer idMov,
            @RequestBody CorregirMovimientoTernerosRequest pedido) {
        return terneroService.reasignarCiclo(idMov, pedido.idCicloProductivo(), pedido.observaciones());
    }
}

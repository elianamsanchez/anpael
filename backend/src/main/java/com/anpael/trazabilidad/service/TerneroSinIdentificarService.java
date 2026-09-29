package com.anpael.trazabilidad.service;

import java.time.LocalDate;
import java.util.List;
import java.util.Objects;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.NoEncontradoException;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.shared.security.ContextoAutenticacion;
import com.anpael.trazabilidad.api.dto.CicloProductivoDto;
import com.anpael.trazabilidad.api.dto.RegistrarBajaTernerosRequest;
import com.anpael.trazabilidad.api.dto.RegistrarNacimientoRequest;
import com.anpael.trazabilidad.api.dto.TerneroAlertasDto;
import com.anpael.trazabilidad.api.dto.TerneroMovimientoDto;
import com.anpael.trazabilidad.api.dto.TerneroSaldoDto;
import com.anpael.trazabilidad.domain.TerneroSinIdentificarMov;
import com.anpael.trazabilidad.infrastructure.TerneroSinIdentificarConsultas;
import com.anpael.trazabilidad.infrastructure.TerneroSinIdentificarMovRepository;

/**
 * Terneros nacidos sin caravana, llevados como cantidad por ciclo y sexo
 * (migración 20260929120000). Los candidatos a torito no pasan por acá: son
 * animales desde que nacen (AnimalAltaService.crearCandidatoTorito).
 *
 * Reglas de saldo, iguales a las del trigger ternero_mov_validar() -que es la
 * red de seguridad; acá se validan antes para dar un mensaje entendible:
 *   - MUERTE, BAJA_OTRA y la anulación de un NACIMIENTO no pueden dejar el
 *     saldo del ciclo en negativo.
 *   - IDENTIFICACION sí, si quien carga lo confirma: los terneros existen, lo
 *     más probable es que falten nacimientos por cargar o sean de otro ciclo.
 *     Queda con excede_saldo = true y el saldo negativo a la vista.
 *
 * Nada se edita ni se borra. Una IDENTIFICACION no se anula sola -dejaría
 * animales creados sin descontar-: se reasigna a otro ciclo.
 */
@Service
@Transactional(readOnly = true)
public class TerneroSinIdentificarService {

    public static final String NACIMIENTO = "NACIMIENTO";
    public static final String IDENTIFICACION = "IDENTIFICACION";
    public static final String ANULACION = "ANULACION";

    private final TerneroSinIdentificarMovRepository movimientos;
    private final TerneroSinIdentificarConsultas consultas;
    private final CicloProductivoService cicloService;
    private final EstablecimientoPropioService establecimientoPropio;

    public TerneroSinIdentificarService(TerneroSinIdentificarMovRepository movimientos,
            TerneroSinIdentificarConsultas consultas, CicloProductivoService cicloService,
            EstablecimientoPropioService establecimientoPropio) {
        this.movimientos = movimientos;
        this.consultas = consultas;
        this.cicloService = cicloService;
        this.establecimientoPropio = establecimientoPropio;
    }

    public List<TerneroSaldoDto> saldo() {
        return consultas.saldo();
    }

    public List<TerneroMovimientoDto> movimientos(Integer idCicloProductivo) {
        return consultas.movimientos(idCicloProductivo);
    }

    public TerneroAlertasDto alertas() {
        return consultas.alertas();
    }

    @Transactional
    public TerneroMovimientoDto registrarNacimiento(RegistrarNacimientoRequest pedido) {
        CicloElegido ciclo = resolverCiclo(pedido.linea(), pedido.idCicloProductivo(), pedido.fecha());
        return insertar(NACIMIENTO, ciclo, pedido.fecha(), pedido.fechaEsEstimada(), pedido.sexo(),
                pedido.cantidad(), null, null, pedido.observaciones());
    }

    @Transactional
    public TerneroMovimientoDto registrarBaja(RegistrarBajaTernerosRequest pedido) {
        CicloElegido ciclo = resolverCiclo(pedido.linea(), pedido.idCicloProductivo(), pedido.fecha());
        exigirSaldo(ciclo.ciclo(), pedido.sexo(), pedido.cantidad(),
                pedido.tipo().equals("MUERTE") ? "dar por muertos" : "dar de baja");
        return insertar(pedido.tipo(), ciclo, pedido.fecha(), pedido.fechaEsEstimada(), pedido.sexo(),
                pedido.cantidad(), null, null, pedido.observaciones());
    }

    /**
     * Descuenta terneros identificados en un trabajo de identificación. Lo usa
     * el módulo planillas, dentro de la misma transacción en la que crea los
     * animales. Si la cantidad supera el saldo del ciclo y no se confirmó,
     * no se carga nada.
     */
    @Transactional
    public TerneroMovimientoDto registrarIdentificacion(Integer idCicloProductivo, String sexo, int cantidad,
            LocalDate fecha, Integer idTrabajo, boolean confirmarExcesoSaldo, String observaciones) {
        CicloProductivoDto ciclo = cicloService.obtener(idCicloProductivo);
        long saldo = consultas.saldoBloqueando(idCicloProductivo, sexo);
        if (cantidad > saldo && !confirmarExcesoSaldo) {
            throw new ReglaDeNegocioException("En el ciclo " + ciclo.codigo() + " quedan " + saldo + " "
                    + sexoPlural(sexo) + " sin identificar y se quieren identificar " + cantidad
                    + ". Confirmá el exceso para cargarlo igual (queda marcado).");
        }
        return insertar(IDENTIFICACION, new CicloElegido(ciclo, esManual(ciclo, fecha)), fecha, false, sexo,
                cantidad, null, idTrabajo, observaciones);
    }

    @Transactional
    public TerneroMovimientoDto anular(Integer idMov, String observaciones) {
        TerneroSinIdentificarMov original = anulable(idMov);
        if (IDENTIFICACION.equals(original.getTipo())) {
            throw new ReglaDeNegocioException("Una identificación no se anula sola: los animales ya se crearon con "
                    + "su caravana. Si el ciclo estaba mal, reasignala a otro ciclo.");
        }
        return insertarAnulacion(original, observaciones);
    }

    /**
     * Corrige el ciclo de un movimiento: ANULACION en el ciclo original y el
     * mismo movimiento de nuevo en el ciclo correcto, en una transacción.
     */
    @Transactional
    public TerneroMovimientoDto reasignarCiclo(Integer idMov, Integer idCicloNuevo, String observaciones) {
        if (idCicloNuevo == null) {
            throw new ReglaDeNegocioException("Falta el ciclo al que se reasigna el movimiento.");
        }
        TerneroSinIdentificarMov original = anulable(idMov);
        if (original.getIdCicloProductivo().equals(idCicloNuevo)) {
            throw new ReglaDeNegocioException("El movimiento ya está en ese ciclo.");
        }
        CicloProductivoDto nuevo = cicloService.obtener(idCicloNuevo);

        insertarAnulacion(original, observaciones);

        if (!NACIMIENTO.equals(original.getTipo()) && !IDENTIFICACION.equals(original.getTipo())) {
            exigirSaldo(nuevo, original.getSexo(), original.getCantidad(), "pasar a este ciclo");
        }
        // una identificación reasignada puede exceder el saldo del ciclo nuevo:
        // la confirmación es elegir el ciclo a mano, y el trigger la marca igual
        String obs = "Reasignado desde el movimiento " + original.getIdMov()
                + (observaciones != null && !observaciones.isBlank() ? ". " + observaciones : "");
        return insertar(original.getTipo(), new CicloElegido(nuevo, esManual(nuevo, original.getFechaEvento())),
                original.getFechaEvento(), original.getFechaEsEstimada(), original.getSexo(),
                original.getCantidad(), null, original.getIdTrabajo(), obs);
    }

    // ------------------------------------------------------------------

    private record CicloElegido(CicloProductivoDto ciclo, boolean manual) {
    }

    /**
     * Sin ciclo pedido: el que corresponde a la fecha en la línea. Con ciclo
     * pedido: ese, marcado como manual si no es el que correspondía.
     */
    private CicloElegido resolverCiclo(String linea, Integer idCicloPedido, LocalDate fecha) {
        if (idCicloPedido != null) {
            CicloProductivoDto ciclo = cicloService.obtener(idCicloPedido);
            return new CicloElegido(ciclo, esManual(ciclo, fecha));
        }
        CicloProductivoDto sugerido = cicloService.sugerido(linea, fecha)
                .orElseThrow(() -> new ReglaDeNegocioException("La fecha " + fecha + " no cae en ningún ciclo de la "
                        + "línea " + linea + ". Elegí el ciclo a mano, o cargá el ciclo que falta."));
        return new CicloElegido(sugerido, false);
    }

    private boolean esManual(CicloProductivoDto ciclo, LocalDate fecha) {
        return cicloService.sugerido(ciclo.linea(), fecha)
                .map(s -> !s.idCicloProductivo().equals(ciclo.idCicloProductivo()))
                .orElse(true);
    }

    private void exigirSaldo(CicloProductivoDto ciclo, String sexo, int cantidad, String accion) {
        long saldo = consultas.saldoBloqueando(ciclo.idCicloProductivo(), sexo);
        if (cantidad > saldo) {
            throw new ReglaDeNegocioException("En el ciclo " + ciclo.codigo() + " quedan " + saldo + " "
                    + sexoPlural(sexo) + " sin identificar: no se pueden " + accion + " " + cantidad + ".");
        }
    }

    private TerneroSinIdentificarMov anulable(Integer idMov) {
        TerneroSinIdentificarMov original = movimientos.findById(idMov)
                .orElseThrow(() -> new NoEncontradoException("No existe el movimiento " + idMov));
        if (ANULACION.equals(original.getTipo())) {
            throw new ReglaDeNegocioException("El movimiento " + idMov + " ya es una anulación: no se anula, "
                    + "se carga de nuevo el movimiento correcto.");
        }
        if (movimientos.existsByIdMovAnulado(idMov)) {
            throw new ReglaDeNegocioException("El movimiento " + idMov + " ya fue anulado.");
        }
        return original;
    }

    private TerneroMovimientoDto insertarAnulacion(TerneroSinIdentificarMov original, String observaciones) {
        CicloProductivoDto ciclo = cicloService.obtener(original.getIdCicloProductivo());
        if (NACIMIENTO.equals(original.getTipo())) {
            // anular un nacimiento resta: no puede dejar el ciclo en negativo
            exigirSaldo(ciclo, original.getSexo(), original.getCantidad(), "anular el nacimiento de");
        }
        return insertar(ANULACION, new CicloElegido(ciclo, original.getCicloManual()), original.getFechaEvento(),
                original.getFechaEsEstimada(), original.getSexo(), original.getCantidad(), original.getIdMov(),
                original.getIdTrabajo(), observaciones);
    }

    private TerneroMovimientoDto insertar(String tipo, CicloElegido ciclo, LocalDate fecha, Boolean fechaEsEstimada,
            String sexo, int cantidad, Integer idMovAnulado, Integer idTrabajo, String observaciones) {
        TerneroSinIdentificarMov mov = new TerneroSinIdentificarMov();
        mov.setIdEstablecimiento(establecimientoPropio.obtenerId());
        mov.setIdCicloProductivo(ciclo.ciclo().idCicloProductivo());
        mov.setCicloManual(ciclo.manual());
        mov.setFechaEvento(fecha);
        mov.setFechaEsEstimada(Boolean.TRUE.equals(fechaEsEstimada));
        mov.setSexo(sexo);
        mov.setCantidad(cantidad);
        mov.setTipo(tipo);
        mov.setIdMovAnulado(idMovAnulado);
        mov.setIdTrabajo(idTrabajo);
        mov.setObservaciones(observaciones != null && !observaciones.isBlank() ? observaciones.trim() : null);
        mov.setIdPersonaRegistro(ContextoAutenticacion.idPersonaActual());
        mov = movimientos.saveAndFlush(mov);

        // se relee de la vista: excede_saldo lo decide el trigger, no la entidad
        Integer id = Objects.requireNonNull(mov.getIdMov());
        return consultas.movimiento(id).orElseThrow();
    }

    private static String sexoPlural(String sexo) {
        return "M".equals(sexo) ? "machos" : "hembras";
    }
}

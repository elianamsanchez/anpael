package com.anpael.trazabilidad.service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.NoEncontradoException;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.api.dto.CicloProductivoDto;
import com.anpael.trazabilidad.api.dto.GuardarCicloProductivoRequest;
import com.anpael.trazabilidad.domain.CicloProductivo;
import com.anpael.trazabilidad.infrastructure.CicloProductivoRepository;

/**
 * Catálogo editable de ciclos productivos. Editar las fechas de un ciclo NO
 * mueve los movimientos ya cargados (guardan su ciclo explícito): si alguno
 * queda afuera del rango nuevo, aparece en v_alerta_ternero_fuera_de_ciclo.
 */
@Service
@Transactional(readOnly = true)
public class CicloProductivoService {

    private final CicloProductivoRepository ciclos;

    public CicloProductivoService(CicloProductivoRepository ciclos) {
        this.ciclos = ciclos;
    }

    public List<CicloProductivoDto> listar() {
        return ciclos.findAllByOrderByLineaAscFechaInicioDesc().stream().map(CicloProductivoDto::de).toList();
    }

    public CicloProductivoDto obtener(Integer idCicloProductivo) {
        return CicloProductivoDto.de(buscar(idCicloProductivo));
    }

    /**
     * El ciclo de la línea al que pertenece la fecha: el que tiene la fecha
     * entre el inicio de la parición y el fin del ciclo. Sirve tanto para un
     * nacimiento como para el ciclo "vigente" de una identificación.
     */
    public Optional<CicloProductivoDto> sugerido(String linea, LocalDate fecha) {
        return Optional.ofNullable(ciclos.sugerido(linea, fecha)).map(this::obtener);
    }

    @Transactional
    public CicloProductivoDto crear(GuardarCicloProductivoRequest pedido) {
        String codigo = pedido.codigo().trim();
        if (ciclos.existsByCodigoIgnoreCase(codigo)) {
            throw new ReglaDeNegocioException("Ya existe el ciclo " + codigo + ".");
        }
        CicloProductivo ciclo = new CicloProductivo();
        aplicar(ciclo, pedido, codigo, -1);
        return CicloProductivoDto.de(ciclos.save(ciclo));
    }

    @Transactional
    public CicloProductivoDto editar(Integer idCicloProductivo, GuardarCicloProductivoRequest pedido) {
        CicloProductivo ciclo = buscar(idCicloProductivo);
        String codigo = pedido.codigo().trim();
        if (ciclos.existsByCodigoIgnoreCaseAndIdCicloProductivoNot(codigo, idCicloProductivo)) {
            throw new ReglaDeNegocioException("Ya existe otro ciclo con el código " + codigo + ".");
        }
        aplicar(ciclo, pedido, codigo, idCicloProductivo);
        return CicloProductivoDto.de(ciclos.save(ciclo));
    }

    private void aplicar(CicloProductivo ciclo, GuardarCicloProductivoRequest pedido, String codigo, Integer idExcluido) {
        if (pedido.paricionDesde().isBefore(pedido.fechaInicio())
                || pedido.paricionHasta().isBefore(pedido.paricionDesde())
                || pedido.fechaFin().isBefore(pedido.paricionHasta())) {
            throw new ReglaDeNegocioException("Las fechas tienen que ir en orden: inicio del servicio ≤ inicio de la "
                    + "parición ≤ fin de la parición ≤ fin del ciclo.");
        }
        String superpuesto = ciclos.codigoSuperpuesto(pedido.linea(), pedido.paricionDesde(), pedido.fechaFin(),
                idExcluido);
        if (superpuesto != null) {
            throw new ReglaDeNegocioException("Desde el inicio de la parición hasta el fin, el ciclo se superpone con "
                    + superpuesto + " de la misma línea: una fecha no podría decidir a cuál pertenece un ternero.");
        }
        ciclo.setCodigo(codigo);
        ciclo.setLinea(pedido.linea());
        ciclo.setFechaInicio(pedido.fechaInicio());
        ciclo.setParicionDesde(pedido.paricionDesde());
        ciclo.setParicionHasta(pedido.paricionHasta());
        ciclo.setFechaFin(pedido.fechaFin());
        ciclo.setObservaciones(pedido.observaciones());
    }

    private CicloProductivo buscar(Integer idCicloProductivo) {
        return ciclos.findById(idCicloProductivo)
                .orElseThrow(() -> new NoEncontradoException("No existe el ciclo productivo " + idCicloProductivo));
    }
}

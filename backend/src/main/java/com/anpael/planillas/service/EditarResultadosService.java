package com.anpael.planillas.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.planillas.api.dto.CorregirPesadaRequest;
import com.anpael.planillas.api.dto.CorregirRevisionTorosRequest;
import com.anpael.planillas.api.dto.CorregirSanidadRequest;
import com.anpael.planillas.api.dto.CorregirTactoRequest;
import com.anpael.planillas.domain.DiagnosticoGestacion;
import com.anpael.planillas.domain.Evento;
import com.anpael.planillas.domain.MedicionCorporal;
import com.anpael.planillas.domain.Pesaje;
import com.anpael.planillas.domain.RevisionToro;
import com.anpael.planillas.domain.Sanidad;
import com.anpael.planillas.domain.Trabajo;
import com.anpael.planillas.infrastructure.DiagnosticoGestacionRepository;
import com.anpael.planillas.infrastructure.EventoRepository;
import com.anpael.planillas.infrastructure.MedicionCorporalRepository;
import com.anpael.planillas.infrastructure.PesajeRepository;
import com.anpael.planillas.infrastructure.RevisionToroRepository;
import com.anpael.planillas.infrastructure.SanidadRepository;
import com.anpael.planillas.infrastructure.TrabajoRepository;
import com.anpael.shared.exception.NoEncontradoException;
import com.anpael.shared.exception.ReglaDeNegocioException;

/**
 * Corregir el resultado de un trabajo ya cargado (v0.2b): un tacto mal
 * tipeado, un peso que se anoto mal, etc. No crea un evento nuevo -pisa el
 * que ya existe-, a diferencia de cargar resultados. Actualizacion
 * parcial: solo se cambia lo que venga distinto de null en el pedido.
 */
@Service
public class EditarResultadosService {

    private final EventoRepository eventos;
    private final TrabajoRepository trabajos;
    private final DiagnosticoGestacionRepository diagnosticos;
    private final PesajeRepository pesajes;
    private final RevisionToroRepository revisionesToro;
    private final MedicionCorporalRepository medicionesCorporales;
    private final SanidadRepository sanidades;

    public EditarResultadosService(EventoRepository eventos, TrabajoRepository trabajos,
            DiagnosticoGestacionRepository diagnosticos, PesajeRepository pesajes,
            RevisionToroRepository revisionesToro, MedicionCorporalRepository medicionesCorporales,
            SanidadRepository sanidades) {
        this.eventos = eventos;
        this.trabajos = trabajos;
        this.diagnosticos = diagnosticos;
        this.pesajes = pesajes;
        this.revisionesToro = revisionesToro;
        this.medicionesCorporales = medicionesCorporales;
        this.sanidades = sanidades;
    }

    @Transactional
    public void corregirTacto(Integer idEvento, CorregirTactoRequest pedido) {
        Evento evento = validarTipo(idEvento, "TACTO");

        DiagnosticoGestacion diagnostico = diagnosticos.findById(idEvento)
                .orElseThrow(() -> new ReglaDeNegocioException(
                        "El evento " + idEvento + " no tiene un diagnóstico de gestación cargado."));

        if (pedido.resultado() != null) {
            diagnostico.setResultado(pedido.resultado());
        }
        if (pedido.tamano() != null) {
            diagnostico.setTamano(pedido.tamano());
        }
        diagnosticos.save(diagnostico);

        if (pedido.observaciones() != null) {
            evento.setComentario(pedido.observaciones());
            eventos.save(evento);
        }
    }

    @Transactional
    public void corregirPesada(Integer idEvento, CorregirPesadaRequest pedido) {
        validarTipo(idEvento, "PESADA");

        Pesaje pesaje = pesajes.findById(idEvento)
                .orElseThrow(() -> new ReglaDeNegocioException("El evento " + idEvento + " no tiene un pesaje cargado."));

        if (pedido.kilos() != null) {
            pesaje.setPesoKg(pedido.kilos());
            pesajes.save(pesaje);
        }
    }

    @Transactional
    public void corregirRevisionToros(Integer idEvento, CorregirRevisionTorosRequest pedido) {
        validarTipo(idEvento, "REVISION_TOROS");

        RevisionToro revision = revisionesToro.findById(idEvento)
                .orElseThrow(() -> new ReglaDeNegocioException(
                        "El evento " + idEvento + " no tiene una revisión de toro cargada."));

        if (pedido.apto() != null) {
            revision.setApto(pedido.apto());
        }
        if (pedido.circunferenciaEscrotal() != null) {
            revision.setCircEscrotalCm(pedido.circunferenciaEscrotal());
        }
        revisionesToro.save(revision);

        if (pedido.condicionCorporal() != null) {
            MedicionCorporal medicion = medicionesCorporales.findById(idEvento).orElseGet(() -> {
                MedicionCorporal nueva = new MedicionCorporal();
                nueva.setIdEvento(idEvento);
                return nueva;
            });
            medicion.setCondicionCorporal(pedido.condicionCorporal());
            medicionesCorporales.save(medicion);
        }
    }

    @Transactional
    public void corregirSanidad(Integer idEvento, CorregirSanidadRequest pedido) {
        validarTipo(idEvento, "SANIDAD");

        Sanidad sanidad = sanidades.findById(idEvento)
                .orElseThrow(() -> new ReglaDeNegocioException("El evento " + idEvento + " no tiene sanidad cargada."));

        if (pedido.producto() != null) {
            sanidad.setProducto(pedido.producto());
        }
        if (pedido.dosis() != null) {
            sanidad.setDosis(pedido.dosis());
        }
        sanidades.save(sanidad);
    }

    private Evento validarTipo(Integer idEvento, String tipoEsperado) {
        Evento evento = eventos.findById(idEvento)
                .orElseThrow(() -> new NoEncontradoException("No existe el evento " + idEvento));

        Trabajo trabajo = trabajos.findById(evento.getIdTrabajo())
                .orElseThrow(() -> new NoEncontradoException("No existe el trabajo del evento " + idEvento));

        if (!tipoEsperado.equals(trabajo.getTipoTrabajo())) {
            throw new ReglaDeNegocioException(
                    "El evento " + idEvento + " es de " + trabajo.getTipoTrabajo() + ", no de " + tipoEsperado + ".");
        }
        return evento;
    }
}

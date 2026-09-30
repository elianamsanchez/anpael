package com.anpael.planillas.service;

import java.time.LocalDate;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.planillas.api.dto.CargaResultadosResumen;
import com.anpael.planillas.api.dto.CargarInseminacionRequest;
import com.anpael.planillas.api.dto.CargarPesadaRequest;
import com.anpael.planillas.api.dto.CargarRevisionTorosRequest;
import com.anpael.planillas.api.dto.CargarSanidadRequest;
import com.anpael.planillas.api.dto.CargarTactoRequest;
import com.anpael.planillas.domain.DiagnosticoGestacion;
import com.anpael.planillas.domain.Evento;
import com.anpael.planillas.domain.EventoReproductivo;
import com.anpael.planillas.domain.MedicionCorporal;
import com.anpael.planillas.domain.Pesaje;
import com.anpael.planillas.domain.RevisionToro;
import com.anpael.planillas.domain.Sanidad;
import com.anpael.planillas.domain.Trabajo;
import com.anpael.planillas.infrastructure.DiagnosticoGestacionRepository;
import com.anpael.planillas.infrastructure.EventoReproductivoRepository;
import com.anpael.planillas.infrastructure.EventoRepository;
import com.anpael.planillas.infrastructure.MedicionCorporalRepository;
import com.anpael.planillas.infrastructure.PesajeRepository;
import com.anpael.planillas.infrastructure.RevisionToroRepository;
import com.anpael.planillas.infrastructure.SanidadRepository;
import com.anpael.planillas.infrastructure.TrabajoRepository;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.shared.security.ContextoAutenticacion;
import com.anpael.trazabilidad.domain.AnimalLista;
import com.anpael.trazabilidad.domain.Rodeo;
import com.anpael.trazabilidad.service.AnimalService;
import com.anpael.trazabilidad.service.RodeoService;

/**
 * Carga los resultados de una planilla ya trabajada en el campo (v0.2b,
 * docs/etapas.md): "cargás los resultados sin transcribir nada dos veces"
 * -la caravana ya la trajo el PDF, aca solo se tipean los datos nuevos.
 *
 * Cada carga es un trabajo nuevo (una fila por planilla), con un evento por
 * animal y su fila especifica (diagnostico_gestacion, pesaje, etc.). No hay
 * tablas intermedias tipo sesion_trabajo/linea_planilla (ADR-002): esas son
 * para la captura offline de la Fase 2, que necesita UUID porque se genera
 * sin conexion. Esta pantalla es online, escribe directo.
 */
@Service
public class CargaResultadosService {

    private final RodeoService rodeoService;
    private final AnimalService animalService;
    private final TrabajoRepository trabajos;
    private final EventoRepository eventos;
    private final DiagnosticoGestacionRepository diagnosticos;
    private final PesajeRepository pesajes;
    private final RevisionToroRepository revisionesToro;
    private final MedicionCorporalRepository medicionesCorporales;
    private final SanidadRepository sanidades;
    private final EventoReproductivoRepository eventosReproductivos;

    public CargaResultadosService(RodeoService rodeoService, AnimalService animalService, TrabajoRepository trabajos,
            EventoRepository eventos, DiagnosticoGestacionRepository diagnosticos, PesajeRepository pesajes,
            RevisionToroRepository revisionesToro, MedicionCorporalRepository medicionesCorporales,
            SanidadRepository sanidades, EventoReproductivoRepository eventosReproductivos) {
        this.rodeoService = rodeoService;
        this.animalService = animalService;
        this.trabajos = trabajos;
        this.eventos = eventos;
        this.diagnosticos = diagnosticos;
        this.pesajes = pesajes;
        this.revisionesToro = revisionesToro;
        this.medicionesCorporales = medicionesCorporales;
        this.sanidades = sanidades;
        this.eventosReproductivos = eventosReproductivos;
    }

    @Transactional
    public CargaResultadosResumen cargarTacto(CargarTactoRequest pedido) {
        Trabajo trabajo = crearTrabajo(pedido.idRodeo(), "TACTO", pedido.fecha());

        for (CargarTactoRequest.Linea linea : pedido.resultados()) {
            Evento evento = crearEvento(trabajo, linea.idAnimal(), linea.observaciones());

            DiagnosticoGestacion diagnostico = new DiagnosticoGestacion();
            diagnostico.setIdEvento(evento.getIdEvento());
            diagnostico.setMetodo("TACTO");
            diagnostico.setResultado(linea.resultado());
            diagnostico.setTamano(linea.tamano());
            diagnosticos.save(diagnostico);
        }

        return resumen(trabajo, pedido.resultados().size());
    }

    @Transactional
    public CargaResultadosResumen cargarPesada(CargarPesadaRequest pedido) {
        Trabajo trabajo = crearTrabajo(pedido.idRodeo(), "PESADA", pedido.fecha());

        for (CargarPesadaRequest.Linea linea : pedido.resultados()) {
            Evento evento = crearEvento(trabajo, linea.idAnimal(), null);

            Pesaje pesaje = new Pesaje();
            pesaje.setIdEvento(evento.getIdEvento());
            pesaje.setPesoKg(linea.kilos());
            pesaje.setTipoPesada("CONTROL");
            pesajes.save(pesaje);
        }

        return resumen(trabajo, pedido.resultados().size());
    }

    @Transactional
    public CargaResultadosResumen cargarRevisionToros(CargarRevisionTorosRequest pedido) {
        Trabajo trabajo = crearTrabajo(pedido.idRodeo(), "REVISION_TOROS", pedido.fecha());

        for (CargarRevisionTorosRequest.Linea linea : pedido.resultados()) {
            Evento evento = crearEvento(trabajo, linea.idAnimal(), null);

            RevisionToro revision = new RevisionToro();
            revision.setIdEvento(evento.getIdEvento());
            revision.setApto(linea.apto());
            revision.setCircEscrotalCm(linea.circunferenciaEscrotal());
            revisionesToro.save(revision);

            if (linea.condicionCorporal() != null || linea.dentadura() != null) {
                MedicionCorporal medicion = new MedicionCorporal();
                medicion.setIdEvento(evento.getIdEvento());
                medicion.setCondicionCorporal(linea.condicionCorporal());
                medicion.setDentadura(linea.dentadura());
                medicionesCorporales.save(medicion);
            }
        }

        return resumen(trabajo, pedido.resultados().size());
    }

    @Transactional
    public CargaResultadosResumen cargarSanidad(CargarSanidadRequest pedido) {
        Trabajo trabajo = crearTrabajo(pedido.idRodeo(), "SANIDAD", pedido.fecha());

        for (CargarSanidadRequest.Linea linea : pedido.resultados()) {
            Evento evento = crearEvento(trabajo, linea.idAnimal(), null);

            Sanidad sanidad = new Sanidad();
            sanidad.setIdEvento(evento.getIdEvento());
            sanidad.setProducto(linea.producto());
            sanidad.setDosis(linea.dosis());
            sanidades.save(sanidad);
        }

        return resumen(trabajo, pedido.resultados().size());
    }

    /**
     * Inseminación: toro / estado / comentario, como en las hojas del Excel.
     * Se guarda igual que la migración para que el historial las muestre
     * igual: el toro y el comentario van en evento.comentario ("Toro:
     * Minihue | GNRH"), el estado es la condición corporal, y el evento
     * reproductivo queda de tipo INSEMINACION.
     */
    @Transactional
    public CargaResultadosResumen cargarInseminacion(CargarInseminacionRequest pedido) {
        for (CargarInseminacionRequest.Linea linea : pedido.resultados()) {
            AnimalLista animal = animalService.obtener(linea.idAnimal());
            if (!"H".equals(animal.getSexo())) {
                throw new ReglaDeNegocioException("Solo se insemina una hembra: el animal "
                        + (animal.getCaravana() != null ? animal.getCaravana() : "#" + animal.getIdAnimal())
                        + " es macho.");
            }
        }

        Trabajo trabajo = crearTrabajo(pedido.idRodeo(), "INSEMINACION", pedido.fecha());

        for (CargarInseminacionRequest.Linea linea : pedido.resultados()) {
            Evento evento = crearEvento(trabajo, linea.idAnimal(), comentarioInseminacion(linea));

            EventoReproductivo reproductivo = new EventoReproductivo();
            reproductivo.setIdEvento(evento.getIdEvento());
            reproductivo.setTipo("INSEMINACION");
            eventosReproductivos.save(reproductivo);

            if (linea.condicionCorporal() != null) {
                MedicionCorporal medicion = new MedicionCorporal();
                medicion.setIdEvento(evento.getIdEvento());
                medicion.setCondicionCorporal(linea.condicionCorporal());
                medicionesCorporales.save(medicion);
            }
        }

        return resumen(trabajo, pedido.resultados().size());
    }

    private static String comentarioInseminacion(CargarInseminacionRequest.Linea linea) {
        String toro = linea.toro() != null && !linea.toro().isBlank() ? "Toro: " + linea.toro().trim() : null;
        String comentario = linea.comentario() != null && !linea.comentario().isBlank() ? linea.comentario().trim() : null;
        String junto = Stream.of(toro, comentario).filter(Objects::nonNull).collect(Collectors.joining(" | "));
        return junto.isEmpty() ? null : junto;
    }

    private Trabajo crearTrabajo(Integer idRodeo, String tipoTrabajo, LocalDate fecha) {
        Rodeo rodeo = rodeoService.obtener(idRodeo);

        Trabajo trabajo = new Trabajo();
        trabajo.setIdEstablecimiento(rodeo.getIdEstablecimiento());
        trabajo.setIdRodeo(idRodeo);
        trabajo.setTipoTrabajo(tipoTrabajo);
        trabajo.setFecha(fecha != null ? fecha : LocalDate.now());
        trabajo.setIdResponsable(ContextoAutenticacion.idPersonaActual());
        return trabajos.save(trabajo);
    }

    private Evento crearEvento(Trabajo trabajo, Integer idAnimal, String comentario) {
        Evento evento = new Evento();
        evento.setIdTrabajo(trabajo.getIdTrabajo());
        evento.setIdAnimal(idAnimal);
        evento.setComentario(comentario);
        evento.setIdPersonaRegistro(ContextoAutenticacion.idPersonaActual());
        return eventos.save(evento);
    }

    private CargaResultadosResumen resumen(Trabajo trabajo, int cantidad) {
        return new CargaResultadosResumen(
                "Se cargaron " + cantidad + " resultados.", trabajo.getIdTrabajo(), cantidad);
    }
}

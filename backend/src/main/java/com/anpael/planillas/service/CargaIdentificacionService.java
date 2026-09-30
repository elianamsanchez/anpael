package com.anpael.planillas.service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.planillas.api.dto.CargaIdentificacionResumen;
import com.anpael.planillas.api.dto.CargarIdentificacionRequest;
import com.anpael.planillas.domain.Evento;
import com.anpael.planillas.domain.Trabajo;
import com.anpael.planillas.infrastructure.EventoRepository;
import com.anpael.planillas.infrastructure.TrabajoRepository;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.shared.security.ContextoAutenticacion;
import com.anpael.trazabilidad.api.dto.CicloProductivoDto;
import com.anpael.trazabilidad.api.dto.TerneroMovimientoDto;
import com.anpael.trazabilidad.service.AnimalAltaService;
import com.anpael.trazabilidad.service.CicloProductivoService;
import com.anpael.trazabilidad.service.EstablecimientoPropioService;
import com.anpael.trazabilidad.service.RodeoService;
import com.anpael.trazabilidad.service.TerneroSinIdentificarService;

/**
 * Carga de un trabajo de identificación: un trabajo IDENTIFICACION, un evento
 * por animal, los animales nuevos con su caravana, y el descuento de la
 * cantidad pendiente de cada ciclo -todo en una transacción: si falla una
 * caravana, no queda nada a medias (ni animales creados sin descontar, ni
 * descuentos sin animales).
 *
 * Los animales y la cantidad pendiente son de trazabilidad; acá solo se
 * orquesta por sus servicios públicos.
 */
@Service
public class CargaIdentificacionService {

    private final TrabajoRepository trabajos;
    private final EventoRepository eventos;
    private final RodeoService rodeoService;
    private final EstablecimientoPropioService establecimientoPropio;
    private final CicloProductivoService cicloService;
    private final TerneroSinIdentificarService terneroService;
    private final AnimalAltaService animalAltaService;

    public CargaIdentificacionService(TrabajoRepository trabajos, EventoRepository eventos,
            RodeoService rodeoService, EstablecimientoPropioService establecimientoPropio,
            CicloProductivoService cicloService, TerneroSinIdentificarService terneroService,
            AnimalAltaService animalAltaService) {
        this.trabajos = trabajos;
        this.eventos = eventos;
        this.rodeoService = rodeoService;
        this.establecimientoPropio = establecimientoPropio;
        this.cicloService = cicloService;
        this.terneroService = terneroService;
        this.animalAltaService = animalAltaService;
    }

    @Transactional
    public CargaIdentificacionResumen cargar(CargarIdentificacionRequest pedido) {
        List<CargarIdentificacionRequest.Grupo> grupos = pedido.grupos() != null ? pedido.grupos() : List.of();
        List<CargarIdentificacionRequest.Torito> toritos = pedido.toritos() != null ? pedido.toritos() : List.of();
        validar(grupos, toritos);

        Trabajo trabajo = crearTrabajo(pedido);
        boolean confirmarExceso = Boolean.TRUE.equals(pedido.confirmarExcesoSaldo());

        List<CargaIdentificacionResumen.Descuento> descuentos = new ArrayList<>();
        int animalesCreados = 0;
        for (CargarIdentificacionRequest.Grupo grupo : grupos) {
            CicloProductivoDto ciclo = cicloService.obtener(grupo.idCicloProductivo());

            // primero el descuento: si excede sin confirmar, se corta antes de crear animales
            TerneroMovimientoDto mov = terneroService.registrarIdentificacion(ciclo.idCicloProductivo(),
                    grupo.sexo(), grupo.caravanas().size(), pedido.fecha(), trabajo.getIdTrabajo(),
                    confirmarExceso, pedido.observaciones());
            descuentos.add(new CargaIdentificacionResumen.Descuento(ciclo.idCicloProductivo(), ciclo.codigo(),
                    grupo.sexo(), mov.cantidad(), Boolean.TRUE.equals(mov.excedeSaldo())));

            for (String caravana : grupo.caravanas()) {
                Integer idAnimal = animalAltaService.crearTerneroIdentificado(caravana, grupo.sexo(),
                        ciclo.anioNacimiento(), pedido.idRodeo(), pedido.fecha());
                crearEvento(trabajo, idAnimal, "Identificado · ciclo " + ciclo.codigo());
                animalesCreados++;
            }
        }

        for (CargarIdentificacionRequest.Torito torito : toritos) {
            animalAltaService.agregarIdentificacionVisual(torito.idAnimal(), torito.caravana(), pedido.fecha());
            crearEvento(trabajo, torito.idAnimal(), "Candidato a torito · caravana visual");
        }

        String mensaje = "Se identificaron " + animalesCreados + " terneros"
                + (toritos.isEmpty() ? "" : " y " + toritos.size() + " candidatos a torito") + "."
                + (descuentos.stream().anyMatch(CargaIdentificacionResumen.Descuento::excedeSaldo)
                        ? " Algún ciclo quedó con más identificados que nacimientos cargados: revisar el saldo."
                        : "");
        return new CargaIdentificacionResumen(mensaje, trabajo.getIdTrabajo(), animalesCreados, toritos.size(),
                descuentos);
    }

    private void validar(List<CargarIdentificacionRequest.Grupo> grupos,
            List<CargarIdentificacionRequest.Torito> toritos) {
        if (grupos.isEmpty() && toritos.isEmpty()) {
            throw new ReglaDeNegocioException("La planilla no tiene ningún animal para identificar.");
        }
        Set<String> gruposVistos = new HashSet<>();
        for (CargarIdentificacionRequest.Grupo g : grupos) {
            if (!gruposVistos.add(g.idCicloProductivo() + "|" + g.sexo())) {
                throw new ReglaDeNegocioException("Hay dos grupos del mismo ciclo y sexo: juntá las caravanas en uno.");
            }
        }
        Set<String> caravanas = new HashSet<>();
        List<String> repetidas = new ArrayList<>();
        grupos.stream().flatMap(g -> g.caravanas().stream())
                .map(c -> c.trim().toLowerCase())
                .forEach(c -> {
                    if (!caravanas.add(c)) repetidas.add(c);
                });
        toritos.stream().map(t -> t.caravana().trim().toLowerCase())
                .forEach(c -> {
                    if (!caravanas.add(c)) repetidas.add(c);
                });
        if (!repetidas.isEmpty()) {
            throw new ReglaDeNegocioException("Caravanas repetidas en la planilla: " + String.join(", ", repetidas) + ".");
        }
        Set<Integer> toritosVistos = new HashSet<>();
        for (CargarIdentificacionRequest.Torito t : toritos) {
            if (!toritosVistos.add(t.idAnimal())) {
                throw new ReglaDeNegocioException("El animal " + t.idAnimal() + " está dos veces en la planilla.");
            }
        }
    }

    private Trabajo crearTrabajo(CargarIdentificacionRequest pedido) {
        Trabajo trabajo = new Trabajo();
        trabajo.setIdEstablecimiento(pedido.idRodeo() != null
                ? rodeoService.obtener(pedido.idRodeo()).getIdEstablecimiento()
                : establecimientoPropio.obtenerId());
        trabajo.setIdRodeo(pedido.idRodeo());
        trabajo.setTipoTrabajo("IDENTIFICACION");
        trabajo.setFecha(pedido.fecha());
        trabajo.setObservaciones(pedido.observaciones());
        trabajo.setIdResponsable(ContextoAutenticacion.idPersonaActual());
        return trabajos.save(trabajo);
    }

    private void crearEvento(Trabajo trabajo, Integer idAnimal, String comentario) {
        Evento evento = new Evento();
        evento.setIdTrabajo(trabajo.getIdTrabajo());
        evento.setIdAnimal(idAnimal);
        evento.setComentario(comentario);
        evento.setIdPersonaRegistro(ContextoAutenticacion.idPersonaActual());
        eventos.save(evento);
    }
}

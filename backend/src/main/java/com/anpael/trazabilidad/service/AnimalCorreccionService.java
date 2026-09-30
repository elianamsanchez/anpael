package com.anpael.trazabilidad.service;

import java.time.LocalDate;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.NoEncontradoException;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.api.dto.CorregirAnimalRequest;
import com.anpael.trazabilidad.domain.Animal;
import com.anpael.trazabilidad.domain.Identificacion;
import com.anpael.trazabilidad.domain.TipoIdentificacion;
import com.anpael.trazabilidad.infrastructure.AnimalRepository;
import com.anpael.trazabilidad.infrastructure.IdentificacionRepository;
import com.anpael.trazabilidad.infrastructure.PelajeRepository;
import com.anpael.trazabilidad.infrastructure.RazaRepository;
import com.anpael.trazabilidad.infrastructure.TipoIdentificacionRepository;

/**
 * Corregir y completar datos (v0.2a, docs/etapas.md): la migracion trajo
 * animales completos pero no todos al dia -1.189 de 1.533 sin fecha de
 * nacimiento en esta base-. Actualizacion parcial: cada campo del pedido
 * que no sea null se pisa, el resto queda como estaba.
 *
 * La marca a fuego (solo machos) y el número adicional (machos y hembras)
 * son la excepción: son identificaciones, y las identificaciones no se
 * pisan. Si el animal ya tenía una vigente de ese tipo, esa queda dada de
 * baja (con el motivo) y se agrega la nueva, que hereda su fecha de
 * colocación -corregir el número no cambia cuándo se colocó-.
 */
@Service
public class AnimalCorreccionService {

    private static final String CODIGO_FUEGO = "FUEGO";
    private static final String CODIGO_ADICIONAL = "ADICIONAL";
    private static final String MOTIVO_CORRECCION = "Corregida desde la ficha del animal";

    private final AnimalRepository animales;
    private final RazaRepository razas;
    private final PelajeRepository pelajes;
    private final IdentificacionRepository identificaciones;
    private final TipoIdentificacionRepository tiposIdent;
    private final EstablecimientoPropioService establecimientoPropio;

    public AnimalCorreccionService(AnimalRepository animales, RazaRepository razas, PelajeRepository pelajes,
            IdentificacionRepository identificaciones, TipoIdentificacionRepository tiposIdent,
            EstablecimientoPropioService establecimientoPropio) {
        this.animales = animales;
        this.razas = razas;
        this.pelajes = pelajes;
        this.identificaciones = identificaciones;
        this.tiposIdent = tiposIdent;
        this.establecimientoPropio = establecimientoPropio;
    }

    @Transactional
    public void corregir(Integer idAnimal, CorregirAnimalRequest pedido) {
        Animal animal = animales.findById(idAnimal)
                .orElseThrow(() -> new NoEncontradoException("No existe el animal " + idAnimal));

        if (pedido.idRaza() != null) {
            if (!razas.existsById(pedido.idRaza())) {
                throw new ReglaDeNegocioException("La raza " + pedido.idRaza() + " no existe.");
            }
            animal.setIdRaza(pedido.idRaza());
        }
        if (pedido.idPelaje() != null) {
            if (!pelajes.existsById(pedido.idPelaje())) {
                throw new ReglaDeNegocioException("El pelaje " + pedido.idPelaje() + " no existe.");
            }
            animal.setIdPelaje(pedido.idPelaje());
        }
        if (pedido.fechaNacimiento() != null) {
            animal.setFechaNacimiento(pedido.fechaNacimiento());
            // la fecha completa manda: si se carga, el año se recalcula de
            // ella y pisa cualquier año cargado a mano en el mismo pedido.
            animal.setAnioNacimiento(pedido.fechaNacimiento().getYear());
        } else if (pedido.anioNacimiento() != null) {
            animal.setAnioNacimiento(pedido.anioNacimiento());
        }
        if (pedido.fechaNacEsEstimada() != null) {
            animal.setFechaNacEsEstimada(pedido.fechaNacEsEstimada());
        }
        if (pedido.anioIngreso() != null) {
            animal.setAnioIngreso(pedido.anioIngreso());
        }
        if (pedido.anioPrimerServicio() != null) {
            animal.setAnioPrimerServicio(pedido.anioPrimerServicio());
        }
        if (pedido.pesoNacerKg() != null) {
            animal.setPesoNacerKg(pedido.pesoNacerKg());
        }
        if (pedido.padreNombre() != null) {
            animal.setPadreNombre(pedido.padreNombre());
        }
        if (pedido.observaciones() != null) {
            animal.setObservaciones(pedido.observaciones());
        }
        if (pedido.marcaFuego() != null && !pedido.marcaFuego().isBlank()) {
            if (!"M".equals(animal.getSexo())) {
                throw new ReglaDeNegocioException("La marca a fuego es solo para machos.");
            }
            corregirIdentificacion(animal, CODIGO_FUEGO, "la marca a fuego", pedido.marcaFuego().trim());
        }
        if (pedido.numeroAdicional() != null && !pedido.numeroAdicional().isBlank()) {
            corregirIdentificacion(animal, CODIGO_ADICIONAL, "el número adicional", pedido.numeroAdicional().trim());
        }

        animales.save(animal);
    }

    /**
     * Agrega o cambia una identificación de un tipo (marca a fuego, número
     * adicional). Si ya tenía una vigente de ese tipo, queda dada de baja y
     * la nueva hereda su fecha de colocación.
     */
    private void corregirIdentificacion(Animal animal, String codigoTipo, String nombre, String valor) {
        TipoIdentificacion tipo = tiposIdent.findByCodigo(codigoTipo)
                .orElseThrow(() -> new ReglaDeNegocioException(
                        "Falta el tipo de identificación " + codigoTipo + " en el catálogo."));

        Optional<Identificacion> actual = identificaciones.findByIdAnimalAndFechaBajaIsNull(animal.getIdAnimal())
                .stream()
                .filter(i -> i.getIdTipoIdent().equals(tipo.getIdTipoIdent()))
                .findFirst();
        if (actual.isPresent() && actual.get().getCaravana().equalsIgnoreCase(valor)) {
            return; // es la misma: nada que cambiar
        }

        Integer idEstablecimiento = actual.map(Identificacion::getIdEstablecimiento)
                .orElseGet(establecimientoPropio::obtenerId);
        if (identificaciones.existsByIdTipoIdentAndIdEstablecimientoAndCaravanaIgnoreCaseAndIdAnimalNot(
                tipo.getIdTipoIdent(), idEstablecimiento, valor, animal.getIdAnimal())) {
            throw new ReglaDeNegocioException("Ya existe otro animal con " + nombre + " " + valor + ".");
        }

        Identificacion nueva = new Identificacion();
        nueva.setIdAnimal(animal.getIdAnimal());
        nueva.setIdTipoIdent(tipo.getIdTipoIdent());
        nueva.setIdEstablecimiento(idEstablecimiento);
        nueva.setCaravana(valor);
        if (actual.isPresent()) {
            Identificacion anterior = actual.get();
            nueva.setFechaAlta(anterior.getFechaAlta());
            nueva.setFechaAltaEsEstimada(anterior.getFechaAltaEsEstimada());
            LocalDate hoy = LocalDate.now();
            anterior.setFechaBaja(anterior.getFechaAlta() != null && anterior.getFechaAlta().isAfter(hoy)
                    ? anterior.getFechaAlta() : hoy);
            anterior.setMotivoBaja(MOTIVO_CORRECCION);
            identificaciones.saveAndFlush(anterior);
        } else {
            // no se sabe cuándo se marcó: queda vacía, no se inventa la fecha de hoy
            nueva.setFechaAlta(null);
            nueva.setFechaAltaEsEstimada(false);
        }
        identificaciones.save(nueva);
    }
}

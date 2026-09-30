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
 * La marca a fuego es la excepción: es una identificación, y las
 * identificaciones no se pisan. Si el animal ya tenía una vigente, esa queda
 * dada de baja (con el motivo) y se agrega la nueva, que hereda su fecha de
 * colocación -corregir el número no cambia cuándo se marcó-.
 */
@Service
public class AnimalCorreccionService {

    private static final String CODIGO_FUEGO = "FUEGO";
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
            corregirMarcaFuego(animal, pedido.marcaFuego().trim());
        }

        animales.save(animal);
    }

    private void corregirMarcaFuego(Animal animal, String marca) {
        if (!"M".equals(animal.getSexo())) {
            throw new ReglaDeNegocioException("La marca a fuego es solo para machos.");
        }
        TipoIdentificacion fuego = tiposIdent.findByCodigo(CODIGO_FUEGO)
                .orElseThrow(() -> new ReglaDeNegocioException("Falta el tipo de identificación FUEGO en el catálogo."));

        Optional<Identificacion> actual = identificaciones.findByIdAnimalAndFechaBajaIsNull(animal.getIdAnimal())
                .stream()
                .filter(i -> i.getIdTipoIdent().equals(fuego.getIdTipoIdent()))
                .findFirst();
        if (actual.isPresent() && actual.get().getCaravana().equalsIgnoreCase(marca)) {
            return; // es la misma: nada que cambiar
        }

        Integer idEstablecimiento = actual.map(Identificacion::getIdEstablecimiento)
                .orElseGet(establecimientoPropio::obtenerId);
        if (identificaciones.existsByIdTipoIdentAndIdEstablecimientoAndCaravanaIgnoreCaseAndIdAnimalNot(
                fuego.getIdTipoIdent(), idEstablecimiento, marca, animal.getIdAnimal())) {
            throw new ReglaDeNegocioException("Ya existe otro animal con la marca a fuego " + marca + ".");
        }

        Identificacion nueva = new Identificacion();
        nueva.setIdAnimal(animal.getIdAnimal());
        nueva.setIdTipoIdent(fuego.getIdTipoIdent());
        nueva.setIdEstablecimiento(idEstablecimiento);
        nueva.setCaravana(marca);
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

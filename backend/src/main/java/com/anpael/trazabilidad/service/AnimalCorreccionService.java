package com.anpael.trazabilidad.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.NoEncontradoException;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.api.dto.CorregirAnimalRequest;
import com.anpael.trazabilidad.domain.Animal;
import com.anpael.trazabilidad.infrastructure.AnimalRepository;
import com.anpael.trazabilidad.infrastructure.PelajeRepository;
import com.anpael.trazabilidad.infrastructure.RazaRepository;

/**
 * Corregir y completar datos (v0.2a, docs/etapas.md): la migracion trajo
 * animales completos pero no todos al dia -1.189 de 1.533 sin fecha de
 * nacimiento en esta base-. Actualizacion parcial: cada campo del pedido
 * que no sea null se pisa, el resto queda como estaba.
 */
@Service
public class AnimalCorreccionService {

    private final AnimalRepository animales;
    private final RazaRepository razas;
    private final PelajeRepository pelajes;

    public AnimalCorreccionService(AnimalRepository animales, RazaRepository razas, PelajeRepository pelajes) {
        this.animales = animales;
        this.razas = razas;
        this.pelajes = pelajes;
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
        if (pedido.pesoNacerKg() != null) {
            animal.setPesoNacerKg(pedido.pesoNacerKg());
        }

        animales.save(animal);
    }
}

package com.anpael.trazabilidad.service;

import java.time.LocalDate;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.domain.AnimalCategoria;
import com.anpael.trazabilidad.domain.Categoria;
import com.anpael.trazabilidad.infrastructure.AnimalCategoriaRepository;
import com.anpael.trazabilidad.infrastructure.CategoriaRepository;

/**
 * Asigna o cambia la categoria de un animal. No hay una funcion de base para
 * esto (a diferencia de rodeo, que tiene mover_a_rodeo()), asi que la logica
 * -cerrar la fila abierta, abrir la nueva, en la misma transaccion- vive
 * aca, replicando a proposito el mismo comportamiento: sin cambios si ya
 * estaba en esa categoria, error si la fecha nueva no es posterior a la de
 * ingreso actual. El indice unico parcial ux_animal_categoria_abierta es la
 * red de seguridad si esto se rompe.
 */
@Service
public class AnimalCategoriaService {

    private final CategoriaRepository categorias;
    private final AnimalCategoriaRepository animalCategorias;

    public AnimalCategoriaService(CategoriaRepository categorias, AnimalCategoriaRepository animalCategorias) {
        this.categorias = categorias;
        this.animalCategorias = animalCategorias;
    }

    @Transactional
    public String asignar(Integer idAnimal, Integer idCategoria, LocalDate fecha) {
        Categoria categoria = categorias.findById(idCategoria)
                .orElseThrow(() -> new ReglaDeNegocioException("La categoría " + idCategoria + " no existe."));

        Optional<AnimalCategoria> actual = animalCategorias.findByIdAnimalAndFechaHastaIsNull(idAnimal);

        if (actual.isPresent() && actual.get().getIdCategoria().equals(idCategoria)) {
            return "Sin cambios: el animal ya estaba en " + categoria.getNombre() + ".";
        }

        if (actual.isPresent()) {
            LocalDate desdeActual = actual.get().getFechaDesde();
            if (!fecha.isAfter(desdeActual)) {
                throw new ReglaDeNegocioException("La fecha " + fecha + " no es posterior a la de ingreso "
                        + "a la categoría actual (" + desdeActual + "). No se cambió nada.");
            }
            actual.get().setFechaHasta(fecha);
        }

        AnimalCategoria nueva = new AnimalCategoria();
        nueva.setIdAnimal(idAnimal);
        nueva.setIdCategoria(idCategoria);
        nueva.setFechaDesde(fecha);
        animalCategorias.save(nueva);

        return (actual.isPresent() ? "Movido a " : "Asignado a ") + categoria.getNombre() + " el " + fecha + ".";
    }
}

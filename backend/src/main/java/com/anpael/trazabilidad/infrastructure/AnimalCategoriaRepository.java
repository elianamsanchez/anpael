package com.anpael.trazabilidad.infrastructure;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.AnimalCategoria;

public interface AnimalCategoriaRepository extends JpaRepository<AnimalCategoria, Integer> {

    Optional<AnimalCategoria> findByIdAnimalAndFechaHastaIsNull(Integer idAnimal);
}

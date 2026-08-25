package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.AnimalEvento;

public interface AnimalEventoRepository extends JpaRepository<AnimalEvento, Integer> {

    List<AnimalEvento> findByIdAnimalOrderByFechaDesc(Integer idAnimal);
}

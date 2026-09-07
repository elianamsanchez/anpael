package com.anpael.trazabilidad.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.AnimalValidacion;

public interface AnimalValidacionRepository extends JpaRepository<AnimalValidacion, Integer> {
}

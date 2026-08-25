package com.anpael.trazabilidad.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Animal;

public interface AnimalRepository extends JpaRepository<Animal, Integer> {
}

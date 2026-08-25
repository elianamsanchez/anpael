package com.anpael.trazabilidad.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Baja;

public interface BajaRepository extends JpaRepository<Baja, Integer> {

    boolean existsByIdAnimal(Integer idAnimal);
}

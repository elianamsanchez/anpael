package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Rodeo;

public interface RodeoRepository extends JpaRepository<Rodeo, Integer> {

    List<Rodeo> findAllByActivoTrueOrderByNombreAsc();
}

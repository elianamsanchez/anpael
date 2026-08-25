package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Pelaje;

public interface PelajeRepository extends JpaRepository<Pelaje, Integer> {

    List<Pelaje> findAllByOrderByNombreAsc();
}

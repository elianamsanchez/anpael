package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.CausaBaja;

public interface CausaBajaRepository extends JpaRepository<CausaBaja, Integer> {

    List<CausaBaja> findAllByOrderByDescripcionAsc();
}

package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Cabana;

public interface CabanaRepository extends JpaRepository<Cabana, Integer> {

    List<Cabana> findAllByOrderByNombreAsc();
}

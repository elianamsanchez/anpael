package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Raza;

public interface RazaRepository extends JpaRepository<Raza, Integer> {

    List<Raza> findAllByOrderByNombreAsc();
}

package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Establecimiento;

public interface EstablecimientoRepository extends JpaRepository<Establecimiento, Integer> {

    List<Establecimiento> findByEsPropioTrueAndActivoTrue();

    List<Establecimiento> findAllByActivoTrueOrderByNombreAsc();
}

package com.anpael.trazabilidad.infrastructure;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.TipoIdentificacion;

public interface TipoIdentificacionRepository extends JpaRepository<TipoIdentificacion, Integer> {

    Optional<TipoIdentificacion> findByCodigo(String codigo);
}

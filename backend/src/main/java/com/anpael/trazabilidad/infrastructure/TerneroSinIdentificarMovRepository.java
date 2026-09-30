package com.anpael.trazabilidad.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.TerneroSinIdentificarMov;

public interface TerneroSinIdentificarMovRepository extends JpaRepository<TerneroSinIdentificarMov, Integer> {

    boolean existsByIdMovAnulado(Integer idMovAnulado);
}

package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Categoria;

public interface CategoriaRepository extends JpaRepository<Categoria, Integer> {

    List<Categoria> findAllByActivoTrueOrderByOrdenAsc();
}

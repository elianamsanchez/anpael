package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.anpael.trazabilidad.domain.Rodeo;

public interface RodeoRepository extends JpaRepository<Rodeo, Integer> {

    List<Rodeo> findAllByActivoTrueOrderByOrdenAsc();

    /**
     * Rodeos activos que admiten la categoria dada: los que no tienen
     * ninguna fila en rodeo_categoria (sin restriccion) mas los que tienen
     * una fila puntual para esa categoria.
     */
    @Query("""
            select r from Rodeo r
            where r.activo = true
              and (
                not exists (select 1 from RodeoCategoria rc where rc.idRodeo = r.idRodeo)
                or exists (select 1 from RodeoCategoria rc where rc.idRodeo = r.idRodeo and rc.idCategoria = :idCategoria)
              )
            order by r.orden
            """)
    List<Rodeo> findAllByActivoTrueYCategoriaPermitida(@Param("idCategoria") Integer idCategoria);
}

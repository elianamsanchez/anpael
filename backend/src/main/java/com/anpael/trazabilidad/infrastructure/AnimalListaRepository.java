package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.anpael.trazabilidad.domain.AnimalLista;

/**
 * JpaSpecificationExecutor porque la busqueda combina filtros opcionales
 * (caravana, sin categoria, sin rodeo) que se arman en AnimalService segun
 * lo que venga en el pedido -no todas las combinaciones tienen sentido como
 * metodo derivado propio.
 */
public interface AnimalListaRepository extends JpaRepository<AnimalLista, Integer>,
        JpaSpecificationExecutor<AnimalLista> {

    // Nativa porque v_animal_lista no tiene id_rodeo (trae el nombre, no el
    // id): para filtrar por rodeo hay que volver a animal_rodeo.
    @Query(value = "select val.* from v_animal_lista val "
            + "join animal_rodeo ar on ar.id_animal = val.id_animal "
            + "where ar.id_rodeo = :idRodeo and ar.fecha_hasta is null "
            + "order by val.caravana", nativeQuery = true)
    List<AnimalLista> buscarPorRodeo(@Param("idRodeo") Integer idRodeo);
}

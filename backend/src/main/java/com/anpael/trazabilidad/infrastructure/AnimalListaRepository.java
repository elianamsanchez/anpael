package com.anpael.trazabilidad.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import com.anpael.trazabilidad.domain.AnimalLista;

/**
 * JpaSpecificationExecutor porque la busqueda combina filtros opcionales
 * (caravana, sin categoria, sin rodeo) que se arman en AnimalService segun
 * lo que venga en el pedido -no todas las combinaciones tienen sentido como
 * metodo derivado propio.
 */
public interface AnimalListaRepository extends JpaRepository<AnimalLista, Integer>,
        JpaSpecificationExecutor<AnimalLista> {
}

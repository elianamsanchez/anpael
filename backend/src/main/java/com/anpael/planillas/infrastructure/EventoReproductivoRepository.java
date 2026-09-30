package com.anpael.planillas.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.planillas.domain.EventoReproductivo;

public interface EventoReproductivoRepository extends JpaRepository<EventoReproductivo, Integer> {
}

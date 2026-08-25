package com.anpael.planillas.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.planillas.domain.Evento;

public interface EventoRepository extends JpaRepository<Evento, Integer> {
}

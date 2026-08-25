package com.anpael.planillas.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.planillas.domain.Sanidad;

public interface SanidadRepository extends JpaRepository<Sanidad, Integer> {
}

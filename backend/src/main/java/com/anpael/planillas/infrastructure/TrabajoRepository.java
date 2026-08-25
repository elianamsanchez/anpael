package com.anpael.planillas.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.planillas.domain.Trabajo;

public interface TrabajoRepository extends JpaRepository<Trabajo, Integer> {
}

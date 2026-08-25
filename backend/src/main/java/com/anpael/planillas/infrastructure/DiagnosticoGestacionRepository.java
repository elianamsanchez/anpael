package com.anpael.planillas.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.planillas.domain.DiagnosticoGestacion;

public interface DiagnosticoGestacionRepository extends JpaRepository<DiagnosticoGestacion, Integer> {
}

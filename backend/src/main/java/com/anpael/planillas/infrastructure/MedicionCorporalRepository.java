package com.anpael.planillas.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.planillas.domain.MedicionCorporal;

public interface MedicionCorporalRepository extends JpaRepository<MedicionCorporal, Integer> {
}

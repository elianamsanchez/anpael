package com.anpael.planillas.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.planillas.domain.Pesaje;

public interface PesajeRepository extends JpaRepository<Pesaje, Integer> {
}

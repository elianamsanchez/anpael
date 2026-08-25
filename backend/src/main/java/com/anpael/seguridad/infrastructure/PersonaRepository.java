package com.anpael.seguridad.infrastructure;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.seguridad.domain.Persona;

public interface PersonaRepository extends JpaRepository<Persona, Integer> {

    Optional<Persona> findByUsuario(String usuario);
}

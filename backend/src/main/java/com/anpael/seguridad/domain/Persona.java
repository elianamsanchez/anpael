package com.anpael.seguridad.domain;

import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * Quien carga y quien trabaja (docs/modelo-datos.md). No extiende
 * AuditableEntity: la tabla no tiene columnas de auditoria todavia.
 *
 * usuario y passwordHash son nullable a proposito: hoy solo existe la fila
 * de PROPIETARIO y todavia no tiene ninguno de los dos cargado (ver
 * supabase/migrations/20260824100000_agregar_login_persona.sql y
 * docs/decisiones.md, ADR-001).
 */
@Entity
@Table(name = "persona")
@Getter
@Setter
public class Persona {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_persona")
    private Integer idPersona;

    @Column(name = "id_auth_user")
    private UUID idAuthUser;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    @Enumerated(EnumType.STRING)
    @Column(name = "rol", nullable = false)
    private RolPersona rol;

    @Column(name = "usuario", unique = true)
    private String usuario;

    @Column(name = "password_hash")
    private String passwordHash;
}

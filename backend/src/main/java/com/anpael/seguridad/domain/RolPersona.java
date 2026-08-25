package com.anpael.seguridad.domain;

/**
 * Los cuatro roles del negocio (docs/decisiones.md, ADR-001). Hoy solo
 * PROPIETARIO tiene una fila cargada en `persona`; los otros tres se dan de
 * alta cuando exista el modulo Seguridad completo.
 */
public enum RolPersona {
    PROPIETARIO,
    GESTOR,
    GERENTE,
    OPERATIVO
}

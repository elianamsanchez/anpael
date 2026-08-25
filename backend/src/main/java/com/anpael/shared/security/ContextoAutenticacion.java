package com.anpael.shared.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * El id de la persona autenticada. Existe porque JpaConfig.auditorActual()
 * usa Authentication.getName() para el nombre legible (creado_por,
 * modificado_por), pero algunas columnas -baja.id_persona_registro- son un
 * FK numerico a persona, no texto. JwtAuthenticationFilter deja ese id en
 * Authentication.details para no pisar el principal que ya usa el auditor.
 */
public final class ContextoAutenticacion {

    private ContextoAutenticacion() {
    }

    public static Integer idPersonaActual() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getDetails() == null) {
            return null;
        }
        return Integer.valueOf((String) auth.getDetails());
    }
}

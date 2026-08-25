package com.anpael.shared.config;

import java.util.Optional;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Enciende la auditoria de Spring Data y le dice de donde sacar "quien".
 *
 * Mientras no exista el login, devuelve "sistema". Cuando el modulo seguridad
 * este listo, el nombre sale solo del token: no hay que tocar ninguna entidad.
 */
@Configuration
@EnableJpaAuditing(auditorAwareRef = "auditorActual")
public class JpaConfig {

    @Bean
    public AuditorAware<String> auditorActual() {
        return () -> {
            Authentication a = SecurityContextHolder.getContext().getAuthentication();
            if (a == null || !a.isAuthenticated() || "anonymousUser".equals(a.getPrincipal())) {
                return Optional.of("sistema");
            }
            return Optional.of(a.getName());
        };
    }
}

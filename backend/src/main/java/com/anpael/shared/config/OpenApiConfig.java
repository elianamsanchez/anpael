package com.anpael.shared.config;

import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;

/**
 * Declara el candado "Authorize" de Swagger UI: pegas el JWT que devuelve
 * /api/auth/login (sin "Bearer ", springdoc lo agrega solo) y de ahi en mas
 * las pruebas de endpoints protegidos lo mandan en el header solas.
 */
@Configuration
@OpenAPIDefinition(
        info = @Info(title = "ANPAEL", description = "Gestion ganadera Santa Ana"),
        security = @SecurityRequirement(name = "bearerAuth")
)
@SecurityScheme(
        name = "bearerAuth",
        type = SecuritySchemeType.HTTP,
        scheme = "bearer",
        bearerFormat = "JWT"
)
public class OpenApiConfig {
}

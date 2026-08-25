package com.anpael.shared.config;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/**
 * CORS.
 *
 * En desarrollo hay DOS formas de que el frontend hable con el backend y
 * conviene saber cual esta usando cada uno, porque los sintomas se parecen:
 *
 *   a) proxy de Vite: el navegador pide a localhost:5173/api y Vite reenvia.
 *      Para el navegador es el MISMO origen, asi que CORS no interviene.
 *   b) llamada directa a localhost:8080: ahi si interviene CORS y hace falta
 *      esta configuracion.
 *
 * El proyecto usa (a) por defecto -esta en vite.config.ts- pero dejamos (b)
 * configurado igual, porque el dia que el frontend se sirva desde otro dominio
 * va a hacer falta y es mejor tenerlo resuelto de antemano.
 *
 * Los origenes salen de application.yml para no hardcodear el dominio de
 * produccion en el codigo.
 */
@Configuration
public class CorsConfig {

    @Value("${anpael.cors.origenes-permitidos}")
    private List<String> origenes;

    @Bean
    public UrlBasedCorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration c = new CorsConfiguration();
        c.setAllowedOrigins(origenes);
        c.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        c.setAllowedHeaders(List.of("*"));
        // Necesario para que el navegador acepte el header Authorization en
        // las respuestas y para que funcione el refresh del token.
        c.setAllowCredentials(true);
        c.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/api/**", c);
        return src;
    }
}

package com.anpael.shared.config;

import java.io.IOException;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import com.anpael.shared.security.JwtAuthenticationFilter;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.http.HttpServletResponse;

/**
 * Seguridad HTTP.
 *
 * Spring Security es el guardian (ADR-001, Opcion A): un JWT propio, emitido
 * por /api/auth/login, es lo unico que abre las puertas cerradas de abajo.
 * Las 112 politicas RLS de la base siguen activas, pero como red de
 * seguridad para lo que toque la base por fuera del backend — no como
 * mecanismo de autorizacion de esta API.
 *
 * Por que no dejar todo abierto por default: si arrancamos con todo abierto
 * y "despues" lo cerramos, siempre queda algo abierto. Al reves, cada
 * endpoint nuevo obliga a decidir explicitamente quien lo puede usar.
 */
@Configuration
@EnableMethodSecurity   // habilita @PreAuthorize("hasRole('GERENTE')") en los servicios
public class SecurityConfig {

    private final UrlBasedCorsConfigurationSource cors;
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final ObjectMapper objectMapper;

    public SecurityConfig(UrlBasedCorsConfigurationSource cors,
            JwtAuthenticationFilter jwtAuthenticationFilter,
            ObjectMapper objectMapper) {
        this.cors = cors;
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.objectMapper = objectMapper;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(c -> c.configurationSource(cors))
            // Sin CSRF porque no hay cookies de sesion: la autenticacion va a
            // ser por token en el header Authorization. Si algun dia se usan
            // cookies, ESTO HAY QUE VOLVER A ENCENDER.
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/health").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/api/auth/login").permitAll()
                // todo lo demas cerrado: necesita un JWT valido
                .anyRequest().authenticated()
            )
            // GlobalExceptionHandler no aplica aca: un token ausente o
            // invalido lo rechaza este filtro, antes de llegar a ningun
            // controller. Sin esto, Spring Security devuelve un 403 sin
            // cuerpo (o redirige a un form de login que no existe).
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req, res, ex) -> cuerpoError(res, 401, "No autenticado"))
                .accessDeniedHandler((req, res, ex) -> cuerpoError(res, 403, "No autorizado"))
            )
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
            .httpBasic(b -> b.disable())
            .formLogin(f -> f.disable());

        return http.build();
    }

    private void cuerpoError(HttpServletResponse res, int estado, String mensaje) throws IOException {
        res.setStatus(estado);
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        Map<String, Object> cuerpo = new LinkedHashMap<>();
        cuerpo.put("hora", OffsetDateTime.now().toString());
        cuerpo.put("estado", estado);
        cuerpo.put("mensaje", mensaje);
        objectMapper.writeValue(res.getWriter(), cuerpo);
    }

    /**
     * BCrypt con el costo por defecto (10). Subirlo encarece el login sin
     * beneficio real para tres o cuatro usuarios.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}

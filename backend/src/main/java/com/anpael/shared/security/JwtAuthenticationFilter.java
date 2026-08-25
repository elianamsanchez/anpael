package com.anpael.shared.security;

import java.io.IOException;
import java.util.List;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Lee el header Authorization, valida el JWT y arma la Authentication.
 *
 * Si no hay token, o el token no es valido, este filtro NO corta la
 * cadena ni devuelve un error: deja pasar la solicitud sin autenticar y es
 * SecurityConfig quien decide si el endpoint pedido necesita login. Eso es
 * lo que permite que /api/health y /api/auth/login sigan siendo publicos sin
 * casos especiales aca adentro.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String PREFIJO_BEARER = "Bearer ";

    private final JwtService jwtService;

    public JwtAuthenticationFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
            FilterChain chain) throws ServletException, IOException {

        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith(PREFIJO_BEARER)) {
            Claims claims = jwtService.validar(header.substring(PREFIJO_BEARER.length()));
            if (claims != null) {
                String nombre = claims.get("nombre", String.class);
                String rol = claims.get("rol", String.class);

                var autoridad = new SimpleGrantedAuthority("ROLE_" + rol);
                var auth = new UsernamePasswordAuthenticationToken(nombre, null, List.of(autoridad));
                // El subject del JWT es el id de persona (JwtService.generar). Va en
                // "details", no en el principal: JpaConfig.auditorActual() ya usa el
                // principal como nombre legible para auditoria, y ContextoAutenticacion
                // lee este id aparte para FKs numericos como baja.id_persona_registro.
                auth.setDetails(claims.getSubject());
                SecurityContextHolder.getContext().setAuthentication(auth);
            }
        }

        chain.doFilter(request, response);
    }
}

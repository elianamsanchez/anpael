package com.anpael.shared.security;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Date;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

/**
 * Emite y valida los JWT propios (ADR-001, Opcion A1). El backend nunca
 * llama a la API de Supabase Auth para esto: firma y valida con una clave
 * simetrica que vive solo en la variable de entorno ANPAEL_JWT_SECRETO.
 *
 * El secreto se usa tal cual, como bytes UTF-8 — no se decodifica como
 * Base64 aunque en produccion se genere con `openssl rand -base64 48`. Para
 * HMAC lo que importa es la cantidad de entropia, y el texto en si mismo ya
 * tiene de sobra para HS256 (se necesitan 32 bytes; el default de
 * application.yml y cualquier salida de ese comando superan eso).
 */
@Component
public class JwtService {

    private final SecretKey clave;
    private final long minutosDeVida;

    public JwtService(
            @Value("${anpael.jwt.secreto}") String secreto,
            @Value("${anpael.jwt.minutos-de-vida}") long minutosDeVida) {
        this.clave = Keys.hmacShaKeyFor(secreto.getBytes(StandardCharsets.UTF_8));
        this.minutosDeVida = minutosDeVida;
    }

    public record TokenEmitido(String valor, OffsetDateTime expiraEn) {
    }

    public TokenEmitido generar(String idPersona, String nombre, String rol) {
        Instant ahora = Instant.now();
        Instant expira = ahora.plusSeconds(minutosDeVida * 60);

        String token = Jwts.builder()
                .subject(idPersona)
                .claim("nombre", nombre)
                .claim("rol", rol)
                .issuedAt(Date.from(ahora))
                .expiration(Date.from(expira))
                .signWith(clave)
                .compact();

        return new TokenEmitido(token, OffsetDateTime.ofInstant(expira, ZoneOffset.UTC));
    }

    /** Null si el token no es valido, esta vencido o fue alterado: nunca tira excepcion. */
    public Claims validar(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(clave)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (JwtException | IllegalArgumentException e) {
            return null;
        }
    }
}

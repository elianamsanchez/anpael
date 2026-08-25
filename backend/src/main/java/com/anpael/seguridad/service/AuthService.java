package com.anpael.seguridad.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.seguridad.api.dto.LoginRequest;
import com.anpael.seguridad.api.dto.LoginResponse;
import com.anpael.seguridad.domain.Persona;
import com.anpael.seguridad.infrastructure.PersonaRepository;
import com.anpael.shared.exception.CredencialesInvalidasException;
import com.anpael.shared.security.JwtService;

/**
 * Valida usuario y contraseña contra `persona` y, si son correctos, emite un
 * JWT propio (ADR-001, Opcion A1). Nunca llama a la API de Supabase Auth.
 */
@Service
public class AuthService {

    // Mismo mensaje para "no existe" y "contraseña incorrecta": distinguirlos
    // le dice a quien intenta entrar cuales usuarios existen de verdad.
    private static final String CREDENCIALES_INVALIDAS = "Usuario o contraseña incorrectos";

    private final PersonaRepository personas;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(PersonaRepository personas, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.personas = personas;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest pedido) {
        Persona persona = personas.findByUsuario(pedido.usuario())
                .orElseThrow(() -> new CredencialesInvalidasException(CREDENCIALES_INVALIDAS));

        // password_hash es nullable: una persona sin contraseña cargada
        // todavia no puede entrar, no es un caso especial.
        if (persona.getPasswordHash() == null
                || !passwordEncoder.matches(pedido.password(), persona.getPasswordHash())) {
            throw new CredencialesInvalidasException(CREDENCIALES_INVALIDAS);
        }

        JwtService.TokenEmitido token = jwtService.generar(
                persona.getIdPersona().toString(),
                persona.getNombre(),
                persona.getRol().name());

        return new LoginResponse(token.valor(), token.expiraEn(), persona.getNombre(), persona.getRol().name());
    }
}

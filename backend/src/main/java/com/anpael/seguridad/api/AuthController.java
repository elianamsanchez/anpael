package com.anpael.seguridad.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.anpael.seguridad.api.dto.LoginRequest;
import com.anpael.seguridad.api.dto.LoginResponse;
import com.anpael.seguridad.service.AuthService;

import jakarta.validation.Valid;

/**
 * Login (ADR-001, Opcion A1). Es el unico endpoint de este modulo que no
 * necesita token: es el que lo entrega. Ver SecurityConfig, que lo abre
 * explicitamente.
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest pedido) {
        return ResponseEntity.ok(authService.login(pedido));
    }
}

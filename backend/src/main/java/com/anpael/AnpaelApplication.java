package com.anpael;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Punto de entrada. Monolito modular: un solo proceso, un paquete por modulo
 * de negocio (seguridad, trazabilidad, sanidad, ...).
 *
 * Las tres reglas que sostienen la arquitectura estan en docs/decisiones.md
 * y se resumen asi:
 *   1. un modulo nunca importa domain ni infrastructure de otro
 *   2. shared no conoce a ningun modulo
 *   3. ninguna entidad JPA cruza la capa api: siempre DTO
 */
@SpringBootApplication
public class AnpaelApplication {

    public static void main(String[] args) {
        SpringApplication.run(AnpaelApplication.class, args);
    }
}

package com.anpael.shared.exception;

/** Una regla del negocio que no se cumple. Devuelve 409. */
public class ReglaDeNegocioException extends RuntimeException {
    public ReglaDeNegocioException(String mensaje) { super(mensaje); }
}

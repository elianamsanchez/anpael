package com.anpael.shared.exception;

/** Usuario o contraseña incorrectos. Devuelve 401. */
public class CredencialesInvalidasException extends RuntimeException {
    public CredencialesInvalidasException(String mensaje) { super(mensaje); }
}

package com.anpael.shared.exception;

/** El recurso pedido no existe. Devuelve 404. */
public class NoEncontradoException extends RuntimeException {
    public NoEncontradoException(String mensaje) { super(mensaje); }
}

package com.anpael.shared.exception;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Un solo lugar donde se decide que ve el usuario cuando algo falla.
 *
 * Regla: al cliente se le devuelve un mensaje que pueda entender; el detalle
 * tecnico va al log del servidor. Un stack trace en la respuesta HTTP es una
 * filtracion de informacion, no una ayuda.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** Errores de validacion de un @Valid: se listan campo por campo. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> validacion(MethodArgumentNotValidException e) {
        String detalle = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getField() + ": " + f.getDefaultMessage())
                .collect(Collectors.joining(" · "));
        return cuerpo(HttpStatus.BAD_REQUEST, "Datos invalidos", detalle);
    }

    /** Reglas de negocio violadas. La lanzan los servicios a proposito. */
    @ExceptionHandler(ReglaDeNegocioException.class)
    public ResponseEntity<Map<String, Object>> regla(ReglaDeNegocioException e) {
        return cuerpo(HttpStatus.CONFLICT, e.getMessage(), null);
    }

    @ExceptionHandler(NoEncontradoException.class)
    public ResponseEntity<Map<String, Object>> noEncontrado(NoEncontradoException e) {
        return cuerpo(HttpStatus.NOT_FOUND, e.getMessage(), null);
    }

    /** Login fallido: usuario inexistente o contraseña incorrecta. */
    @ExceptionHandler(CredencialesInvalidasException.class)
    public ResponseEntity<Map<String, Object>> credenciales(CredencialesInvalidasException e) {
        return cuerpo(HttpStatus.UNAUTHORIZED, e.getMessage(), null);
    }

    /** El resto: se loguea completo y al cliente le llega poco. */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> inesperado(Exception e) {
        log.error("Error no controlado", e);
        return cuerpo(HttpStatus.INTERNAL_SERVER_ERROR,
                "Ocurrio un error inesperado. Quedo registrado en el servidor.", null);
    }

    private ResponseEntity<Map<String, Object>> cuerpo(HttpStatus s, String msg, String detalle) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("hora", OffsetDateTime.now().toString());
        m.put("estado", s.value());
        m.put("mensaje", msg);
        if (detalle != null) m.put("detalle", detalle);
        return ResponseEntity.status(s).body(m);
    }
}

package com.anpael.shared.api;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * El endpoint tonto del paso 2 del arranque tecnico.
 *
 * No es decorativo: es la forma barata de validar, ANTES de escribir una linea
 * de logica, que la cadena entera esta bien conectada. Devuelve a proposito
 * cuantos animales hay en la base, porque eso prueba cuatro cosas de una vez:
 * que hay conexion, que las credenciales sirven, que el esquema es el correcto
 * y que el rol tiene permiso de lectura.
 *
 * El ultimo punto no es teorico: la aplicacion web de revision fallo justamente
 * ahi, con "permission denied for view", porque los GRANT no estaban puestos.
 */
@RestController
@RequestMapping("/api/health")
public class HealthController {

    private final DataSource dataSource;

    @Value("${spring.application.name:anpael}")
    private String appName;

    // "local" o "produccion" (ANPAEL_ENTORNO). Local corre con un dump de la
    // base productiva, asi que el conteo de animales de mas abajo va a dar
    // el mismo numero en las dos: esto es lo unico que las distingue.
    @Value("${anpael.entorno:sin-definir}")
    private String entorno;

    public HealthController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("aplicacion", appName);
        r.put("entorno", entorno);
        r.put("hora", OffsetDateTime.now().toString());

        try (Connection cn = dataSource.getConnection();
             Statement st = cn.createStatement()) {

            try (ResultSet rs = st.executeQuery("select current_user, current_database()")) {
                if (rs.next()) {
                    r.put("usuarioBase", rs.getString(1));
                    r.put("base", rs.getString(2));
                }
            }
            // Si esta consulta falla por permisos, el mensaje sale tal cual en
            // la respuesta. Es exactamente lo que se quiere ver en este paso.
            try (ResultSet rs = st.executeQuery("select count(*) from animal")) {
                if (rs.next()) r.put("animales", rs.getInt(1));
            }
            r.put("base_de_datos", "ok");
            return ResponseEntity.ok(r);

        } catch (Exception e) {
            r.put("base_de_datos", "ERROR");
            r.put("detalle", e.getMessage());
            // 503 y no 500: el servicio esta arriba, lo que falla es una
            // dependencia. Un monitor externo sabe distinguirlos.
            return ResponseEntity.status(503).body(r);
        }
    }
}

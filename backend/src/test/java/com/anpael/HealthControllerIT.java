package com.anpael;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Map;

/**
 * Prueba de integracion del arranque.
 *
 * Levanta un PostgreSQL de verdad en Docker, arranca la aplicacion contra el,
 * y pega en /api/health. Si esto pasa, quiere decir que la aplicacion arranca,
 * que se conecta a una base y que el endpoint responde.
 *
 * POR QUE UN TEST DE INTEGRACION Y NO UNO UNITARIO: el documento de stack lo
 * pide explicitamente, y con razon. Un test unitario del controlador con la
 * base simulada pasaria aunque la conexion estuviera mal configurada, que es
 * justo el error que uno quiere atrapar.
 *
 * REQUISITO: Docker corriendo. Si no lo tenes, este test se saltea con
 *   mvn test -Dtest='!*IT'
 *
 * NOTA: el contenedor arranca VACIO, sin el esquema. Por eso el health
 * devuelve 503 (no puede contar animales) y el test lo espera asi. Cuando
 * exista la primera migracion versionada en supabase/migrations, se le puede
 * pedir a Testcontainers que la aplique con withInitScript y entonces el
 * esperado pasa a ser 200.
 */
@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class HealthControllerIT {

    @Container
    static PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>("postgres:16-alpine")
                    .withDatabaseName("anpael_test")
                    .withUsername("test")
                    .withPassword("test");

    @DynamicPropertySource
    static void propiedades(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", postgres::getJdbcUrl);
        r.add("spring.datasource.username", postgres::getUsername);
        r.add("spring.datasource.password", postgres::getPassword);
        // El contenedor esta vacio: sin esto, 'validate' impide arrancar en
        // cuanto exista la primera entidad JPA.
        r.add("spring.jpa.hibernate.ddl-auto", () -> "none");
    }

    @Autowired
    private TestRestTemplate rest;

    @LocalServerPort
    private int port;

    @Test
    void health_responde_y_reporta_el_estado_de_la_base() {
        @SuppressWarnings("rawtypes")
        ResponseEntity<Map> r = rest.getForEntity("/api/health", Map.class);

        // El endpoint responde: la aplicacion levanto y la seguridad lo dejo
        // pasar sin token, que es lo que queremos de /api/health.
        assertThat(r.getStatusCode().value()).isIn(200, 503);

        @SuppressWarnings("unchecked")
        Map<String, Object> cuerpo = r.getBody();
        assertThat(cuerpo).isNotNull();
        assertThat(cuerpo.get("aplicacion")).isEqualTo("anpael");
        assertThat(cuerpo).containsKey("base_de_datos");
    }
}

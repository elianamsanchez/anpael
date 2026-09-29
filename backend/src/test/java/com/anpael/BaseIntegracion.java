package com.anpael;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Stream;

import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.MountableFile;

/**
 * Base de los tests de integración contra una base con el esquema real.
 *
 * El contenedor arranca con, en este orden (/docker-entrypoint-initdb.d, psql
 * con ON_ERROR_STOP):
 *   00 · lo mínimo de Supabase que el esquema necesita (roles, auth.uid(), ...)
 *   01 · la estructura del esquema public, sin datos, a la versión VERSION_ESQUEMA
 *   02 · cada migración de supabase/migrations posterior a esa versión, tal cual
 *   99 · catálogos mínimos para probar
 * Así la migración nueva se prueba con el mismo archivo que después se corre
 * contra la base real, y con ddl-auto: validate las entidades JPA se chequean
 * contra las tablas de verdad.
 *
 * Un solo contenedor para todas las clases que heredan de esta (se arranca
 * una vez por JVM). Cada test empieza con las tablas de movimientos vacías.
 *
 * REQUISITO: Docker corriendo. Si no, se saltean con mvn test -Dtest='!*IT'.
 */
@SpringBootTest
public abstract class BaseIntegracion {

    /** Última migración incluida en db/01_esquema_*.sql. Las posteriores se aplican encima. */
    static final String VERSION_ESQUEMA = "20260910190500";

    private static final Path MIGRACIONES = Path.of("..", "supabase", "migrations");
    private static final String INIT = "/docker-entrypoint-initdb.d/";

    static final PostgreSQLContainer<?> POSTGRES = crearContenedor();

    static {
        POSTGRES.start();
    }

    @DynamicPropertySource
    static void propiedades(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        r.add("spring.datasource.username", POSTGRES::getUsername);
        r.add("spring.datasource.password", POSTGRES::getPassword);
        r.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
    }

    @Autowired
    protected JdbcClient jdbc;

    @BeforeEach
    void limpiarMovimientos() {
        // TRUNCATE no dispara el trigger que impide borrar movimientos: es solo para tests
        jdbc.sql("truncate ternero_sin_identificar_mov, evento, trabajo, identificacion, "
                + "animal_categoria, animal_rodeo, animal cascade").update();
        jdbc.sql("delete from ciclo_productivo where codigo not in ('2025-26', '2026-27', 'VAQ2025-26', 'VAQ2026-27')")
                .update();
    }

    protected Integer idCiclo(String codigo) {
        return jdbc.sql("select id_ciclo_productivo from ciclo_productivo where codigo = :codigo")
                .param("codigo", codigo)
                .query(Integer.class)
                .single();
    }

    protected long contar(String sql) {
        return jdbc.sql(sql).query(Long.class).single();
    }

    private static PostgreSQLContainer<?> crearContenedor() {
        PostgreSQLContainer<?> c = new PostgreSQLContainer<>("postgres:17-alpine")
                .withDatabaseName("anpael_test")
                .withUsername("postgres")
                .withPassword("test")
                .withCopyFileToContainer(MountableFile.forClasspathResource("db/00_simular_supabase.sql"),
                        INIT + "00_simular_supabase.sql")
                .withCopyFileToContainer(
                        MountableFile.forClasspathResource("db/01_esquema_" + VERSION_ESQUEMA + ".sql"),
                        INIT + "01_esquema.sql")
                .withCopyFileToContainer(MountableFile.forClasspathResource("db/99_datos_prueba.sql"),
                        INIT + "99_datos_prueba.sql");
        for (Path migracion : migracionesPosteriores()) {
            c.withCopyFileToContainer(MountableFile.forHostPath(migracion), INIT + "02_" + migracion.getFileName());
        }
        return c;
    }

    private static List<Path> migracionesPosteriores() {
        try (Stream<Path> archivos = Files.list(MIGRACIONES)) {
            return archivos
                    .filter(p -> p.getFileName().toString().matches("\\d{14}_.*\\.sql"))
                    .filter(p -> p.getFileName().toString().substring(0, 14).compareTo(VERSION_ESQUEMA) > 0)
                    .sorted()
                    .toList();
        } catch (IOException e) {
            throw new UncheckedIOException("No se encontró " + MIGRACIONES.toAbsolutePath()
                    + ": los tests se corren desde backend/.", e);
        }
    }
}

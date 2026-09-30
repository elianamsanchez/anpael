package com.anpael.trazabilidad.infrastructure;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.anpael.trazabilidad.domain.CicloProductivo;

public interface CicloProductivoRepository extends JpaRepository<CicloProductivo, Integer> {

    List<CicloProductivo> findAllByOrderByLineaAscFechaInicioDesc();

    boolean existsByCodigoIgnoreCaseAndIdCicloProductivoNot(String codigo, Integer idCicloProductivo);

    boolean existsByCodigoIgnoreCase(String codigo);

    /** El ciclo de la línea al que pertenece la fecha, o null. Misma regla que usa la base. */
    @Query(value = "select ciclo_productivo_sugerido(:linea, :fecha)", nativeQuery = true)
    Integer sugerido(@Param("linea") String linea, @Param("fecha") LocalDate fecha);

    /**
     * Otro ciclo de la misma línea cuyo [paricion_desde, fecha_fin] se superpone
     * con el dado. Es el EXCLUDE de la tabla, preguntado antes para dar un
     * mensaje entendible en vez de un error de base. idExcluido nunca null
     * (-1 en un alta): un parámetro null en SQL nativo no tiene tipo para Postgres.
     */
    @Query(value = """
            select c.codigo from ciclo_productivo c
             where c.linea = :linea
               and c.id_ciclo_productivo <> :idExcluido
               and daterange(c.paricion_desde, c.fecha_fin, '[]') && daterange(:desde, :hasta, '[]')
             limit 1
            """, nativeQuery = true)
    String codigoSuperpuesto(@Param("linea") String linea, @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta, @Param("idExcluido") Integer idExcluido);
}

package com.anpael.trazabilidad.infrastructure;

import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import com.anpael.trazabilidad.api.dto.TerneroAlertasDto;
import com.anpael.trazabilidad.api.dto.TerneroMovimientoDto;
import com.anpael.trazabilidad.api.dto.TerneroSaldoDto;

/**
 * Lecturas de las vistas de terneros sin identificar. Van por JdbcClient y no
 * como @Entity @Immutable porque v_ternero_sin_identificar_saldo no tiene una
 * clave por fila (las filas TOTAL tienen el ciclo en null): los records se
 * llenan por nombre de columna (id_ciclo_productivo -> idCicloProductivo).
 * JdbcClient toma la misma conexión que la transacción JPA en curso, así que
 * ve lo que se acaba de insertar.
 */
@Repository
public class TerneroSinIdentificarConsultas {

    private final JdbcClient jdbc;

    public TerneroSinIdentificarConsultas(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    public List<TerneroSaldoDto> saldo() {
        return jdbc.sql("""
                select * from v_ternero_sin_identificar_saldo
                 order by nivel, linea, paricion_desde desc nulls last, sexo nulls last
                """)
                .query(TerneroSaldoDto.class)
                .list();
    }

    /**
     * El saldo de un ciclo y sexo, después de tomar el mismo lock que el
     * trigger ternero_mov_validar(): así el control de Java y el INSERT que
     * sigue ven el mismo saldo aunque haya otra carga en paralelo. Tiene que
     * correr dentro de la transacción del INSERT (el lock se suelta al commit).
     */
    public long saldoBloqueando(Integer idCicloProductivo, String sexo) {
        // envuelto en un select 1: pg_advisory_xact_lock devuelve void, que JDBC no sabe leer
        jdbc.sql("select 1 from (select pg_advisory_xact_lock(hashtext('ternero_sin_identificar_mov'), :clave)) l")
                .param("clave", idCicloProductivo * 2 + ("H".equals(sexo) ? 1 : 0))
                .query(Integer.class)
                .single();
        return jdbc.sql("""
                select coalesce(sum(delta), 0) from v_ternero_sin_identificar_mov
                 where id_ciclo_productivo = :idCiclo and sexo = :sexo
                """)
                .param("idCiclo", idCicloProductivo)
                .param("sexo", sexo)
                .query(Long.class)
                .single();
    }

    public List<TerneroMovimientoDto> movimientos(Integer idCicloProductivo) {
        String sql = "select * from v_ternero_sin_identificar_mov"
                + (idCicloProductivo != null ? " where id_ciclo_productivo = :idCiclo" : "")
                + " order by fecha_evento desc, id_mov desc";
        JdbcClient.StatementSpec consulta = jdbc.sql(sql);
        if (idCicloProductivo != null) {
            consulta = consulta.param("idCiclo", idCicloProductivo);
        }
        return consulta.query(TerneroMovimientoDto.class).list();
    }

    public Optional<TerneroMovimientoDto> movimiento(Integer idMov) {
        return jdbc.sql("select * from v_ternero_sin_identificar_mov where id_mov = :idMov")
                .param("idMov", idMov)
                .query(TerneroMovimientoDto.class)
                .optional();
    }

    public TerneroAlertasDto alertas() {
        List<TerneroAlertasDto.CicloCerrado> cerrados = jdbc.sql("""
                select * from v_alerta_ternero_ciclo_cerrado order by fecha_fin desc, sexo
                """)
                .query(TerneroAlertasDto.CicloCerrado.class)
                .list();
        List<TerneroAlertasDto.FueraDeCiclo> fuera = jdbc.sql("""
                select * from v_alerta_ternero_fuera_de_ciclo order by fecha_evento desc
                """)
                .query(TerneroAlertasDto.FueraDeCiclo.class)
                .list();
        return new TerneroAlertasDto(cerrados, fuera);
    }
}

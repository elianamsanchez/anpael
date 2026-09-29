package com.anpael.trazabilidad;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;

import com.anpael.BaseIntegracion;
import com.anpael.planillas.api.dto.CargaIdentificacionResumen;
import com.anpael.planillas.api.dto.CargarIdentificacionRequest;
import com.anpael.planillas.service.CargaIdentificacionService;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.api.dto.CrearCandidatoToritoRequest;
import com.anpael.trazabilidad.api.dto.GuardarCicloProductivoRequest;
import com.anpael.trazabilidad.api.dto.RegistrarBajaTernerosRequest;
import com.anpael.trazabilidad.api.dto.RegistrarNacimientoRequest;
import com.anpael.trazabilidad.api.dto.TerneroMovimientoDto;
import com.anpael.trazabilidad.api.dto.TerneroSaldoDto;
import com.anpael.trazabilidad.service.AnimalAltaService;
import com.anpael.trazabilidad.service.CicloProductivoService;
import com.anpael.trazabilidad.service.TerneroSinIdentificarService;

/**
 * Terneros sin identificar por ciclo productivo (migración 20260929120000):
 * saldo por ciclo, que no quede negativo, correcciones por movimiento
 * contrario, identificación transaccional y asignación de ciclo por fecha.
 *
 * Ciclos que carga la migración (ver docs/ciclo_*.png):
 *   2025-26     VACA  parición 15/07/2026 – 30/09/2026, fin 30/04/2027
 *   2026-27     VACA  parición 15/07/2027 – 30/09/2027, fin 30/04/2028
 *   VAQ2025-26  VAQ   parición 01/04/2026 – 31/07/2026, fin 31/12/2026
 *   VAQ2026-27  VAQ   parición 01/04/2027 – 31/07/2027, fin 31/12/2027
 */
class TerneroSinIdentificarIT extends BaseIntegracion {

    private static final LocalDate AGO_2026 = LocalDate.of(2026, 8, 1);
    private static final LocalDate MAY_2026 = LocalDate.of(2026, 5, 15);
    private static final LocalDate SEP_2026 = LocalDate.of(2026, 9, 20);

    @Autowired
    private TerneroSinIdentificarService terneros;

    @Autowired
    private CicloProductivoService ciclos;

    @Autowired
    private CargaIdentificacionService cargaIdentificacion;

    @Autowired
    private AnimalAltaService altaAnimales;

    // ------------------------------------------------------------------ saldo

    @Test
    void el_saldo_se_lleva_por_ciclo_y_sexo() {
        nacimiento("VACA", AGO_2026, "M", 30);
        nacimiento("VACA", AGO_2026.plusDays(9), "H", 25);
        nacimiento("VAQ", MAY_2026, "M", 8);
        terneros.registrarBaja(baja("MUERTE", "VACA", AGO_2026.plusDays(20), "M", 2));

        assertThat(saldo("2025-26", "M")).isEqualTo(28);
        assertThat(saldo("2025-26", "H")).isEqualTo(25);
        assertThat(saldo("VAQ2025-26", "M")).isEqualTo(8);
        assertThat(saldo("VAQ2025-26", "H")).isZero();
        assertThat(saldo("2026-27", "M")).isZero();

        TerneroSaldoDto fila = fila("2025-26", "M");
        assertThat(fila.nacidos()).isEqualTo(30);
        assertThat(fila.muertes()).isEqualTo(2);

        List<TerneroSaldoDto> totales = terneros.saldo().stream().filter(s -> "TOTAL".equals(s.nivel())).toList();
        assertThat(totales).extracting(TerneroSaldoDto::sexo, TerneroSaldoDto::saldo)
                .containsExactlyInAnyOrder(
                        org.assertj.core.groups.Tuple.tuple("M", 36L),
                        org.assertj.core.groups.Tuple.tuple("H", 25L),
                        org.assertj.core.groups.Tuple.tuple(null, 61L));

        // integración con el stock: una línea "sin identificar" por ciclo y sexo con saldo
        assertThat(contar("select coalesce(sum(cabezas), 0) from v_stock_unificado where tipo = 'SIN_IDENTIFICAR'"))
                .isEqualTo(61);
        assertThat(contar("select count(*) from v_stock_unificado where tipo = 'SIN_IDENTIFICAR'")).isEqualTo(3);
        assertThat(contar("select cabezas from v_rodeo_stock where rodeo = '(sin identificar · 2025-26)'"))
                .isEqualTo(53);
        assertThat(contar("select machos from v_rodeo_stock where rodeo = '(sin identificar · 2025-26)'"))
                .isEqualTo(28);
    }

    @Test
    void un_ciclo_terminado_con_terneros_pendientes_queda_en_las_alertas() {
        ciclos.crear(new GuardarCicloProductivoRequest("VAQ2024-25", "VAQ", LocalDate.of(2024, 7, 1),
                LocalDate.of(2025, 4, 1), LocalDate.of(2025, 7, 31), LocalDate.of(2025, 12, 31), null));
        nacimiento("VAQ", LocalDate.of(2025, 5, 1), "H", 4);

        assertThat(terneros.alertas().ciclosCerrados())
                .anySatisfy(a -> {
                    assertThat(a.ciclo()).isEqualTo("VAQ2024-25");
                    assertThat(a.sexo()).isEqualTo("H");
                    assertThat(a.saldo()).isEqualTo(4);
                });
    }

    // ------------------------------------------------------------ no negativo

    @Test
    void el_saldo_de_un_ciclo_no_queda_negativo_aunque_otro_ciclo_tenga_terneros() {
        nacimiento("VACA", AGO_2026, "M", 5);
        nacimiento("VAQ", MAY_2026, "M", 50);

        assertThatThrownBy(() -> terneros.registrarBaja(baja("MUERTE", "VACA", AGO_2026.plusDays(3), "M", 6)))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("2025-26")
                .hasMessageContaining("quedan 5 machos");
        assertThat(saldo("2025-26", "M")).isEqualTo(5);

        // la base es la red de seguridad: un INSERT directo tampoco pasa
        assertThatThrownBy(() -> jdbc.sql("""
                insert into ternero_sin_identificar_mov
                    (id_establecimiento, id_ciclo_productivo, fecha_evento, sexo, cantidad, tipo)
                values (10, :ciclo, '2026-08-05', 'M', 6, 'BAJA_OTRA')
                """).param("ciclo", idCiclo("2025-26")).update())
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("quedan 5 machos");
    }

    @Test
    void una_identificacion_que_excede_el_saldo_se_carga_solo_si_se_confirma_y_queda_marcada() {
        nacimiento("VACA", AGO_2026, "H", 3);
        CargarIdentificacionRequest pedido = identificacion(false,
                grupo("2025-26", "H", "E1", "E2", "E3", "E4"));

        assertThatThrownBy(() -> cargaIdentificacion.cargar(pedido))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("quedan 3 hembras");
        assertThat(contar("select count(*) from animal")).isZero();
        assertThat(contar("select count(*) from trabajo")).isZero();

        CargaIdentificacionResumen resumen = cargaIdentificacion.cargar(identificacion(true,
                grupo("2025-26", "H", "E1", "E2", "E3", "E4")));

        assertThat(resumen.animalesCreados()).isEqualTo(4);
        assertThat(resumen.descuentos()).singleElement()
                .satisfies(d -> assertThat(d.excedeSaldo()).isTrue());
        assertThat(saldo("2025-26", "H")).isEqualTo(-1);
        assertThat(contar("select count(*) from ternero_sin_identificar_mov where excede_saldo")).isEqualTo(1);
        // con el saldo negativo, una muerte en ese ciclo ya no entra
        assertThatThrownBy(() -> terneros.registrarBaja(baja("MUERTE", "VACA", SEP_2026, "H", 1)))
                .isInstanceOf(ReglaDeNegocioException.class);
    }

    // ------------------------------------------------------------- correcciones

    @Test
    void una_correccion_es_un_movimiento_contrario_y_nunca_una_edicion() {
        TerneroMovimientoDto equivocado = nacimiento("VACA", AGO_2026, "M", 10);

        TerneroMovimientoDto anulacion = terneros.anular(equivocado.idMov(), "eran 12, no 10");
        nacimiento("VACA", AGO_2026, "M", 12);

        assertThat(anulacion.tipo()).isEqualTo("ANULACION");
        assertThat(anulacion.delta()).isEqualTo(-10);
        assertThat(anulacion.idCicloProductivo()).isEqualTo(equivocado.idCicloProductivo());
        assertThat(saldo("2025-26", "M")).isEqualTo(12);
        assertThat(fila("2025-26", "M").nacidos()).isEqualTo(12); // el anulado no cuenta
        assertThat(contar("select count(*) from ternero_sin_identificar_mov")).isEqualTo(3); // no se borró nada

        assertThatThrownBy(() -> terneros.anular(equivocado.idMov(), null))
                .isInstanceOf(ReglaDeNegocioException.class).hasMessageContaining("ya fue anulado");
        assertThatThrownBy(() -> terneros.anular(anulacion.idMov(), null))
                .isInstanceOf(ReglaDeNegocioException.class).hasMessageContaining("ya es una anulación");

        // en la base, ni UPDATE ni DELETE
        assertThatThrownBy(() -> jdbc.sql("update ternero_sin_identificar_mov set cantidad = 1").update())
                .isInstanceOf(DataAccessException.class).hasMessageContaining("no se edita ni se borra");
        assertThatThrownBy(() -> jdbc.sql("delete from ternero_sin_identificar_mov").update())
                .isInstanceOf(DataAccessException.class).hasMessageContaining("no se edita ni se borra");
    }

    @Test
    void la_anulacion_va_al_mismo_ciclo_que_el_original() {
        TerneroMovimientoDto original = nacimiento("VACA", AGO_2026, "M", 4);

        assertThatThrownBy(() -> jdbc.sql("""
                insert into ternero_sin_identificar_mov
                    (id_establecimiento, id_ciclo_productivo, fecha_evento, sexo, cantidad, tipo, id_mov_anulado)
                values (10, :otroCiclo, '2026-08-01', 'M', 4, 'ANULACION', :idMov)
                """).param("otroCiclo", idCiclo("VAQ2025-26")).param("idMov", original.idMov()).update())
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("mismo ciclo, sexo y cantidad");
    }

    @Test
    void no_se_anula_un_nacimiento_si_esos_terneros_ya_salieron_del_saldo() {
        TerneroMovimientoDto nac = nacimiento("VACA", AGO_2026, "M", 5);
        terneros.registrarBaja(baja("MUERTE", "VACA", AGO_2026.plusDays(1), "M", 5));

        assertThatThrownBy(() -> terneros.anular(nac.idMov(), null))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("quedan 0 machos");
    }

    @Test
    void un_movimiento_en_el_ciclo_equivocado_se_reasigna_sin_perder_la_historia() {
        TerneroMovimientoDto nac = nacimiento("VACA", AGO_2026, "H", 7);

        TerneroMovimientoDto nuevo = terneros.reasignarCiclo(nac.idMov(), idCiclo("VAQ2025-26"), "era de vaquillona");

        assertThat(nuevo.ciclo()).isEqualTo("VAQ2025-26");
        assertThat(saldo("2025-26", "H")).isZero();
        assertThat(saldo("VAQ2025-26", "H")).isEqualTo(7);
        assertThat(contar("select count(*) from ternero_sin_identificar_mov")).isEqualTo(3);
    }

    // --------------------------------------------------------- identificación

    @Test
    void una_identificacion_con_terneros_de_dos_ciclos_descuenta_de_cada_uno() {
        nacimiento("VACA", AGO_2026, "M", 10);
        nacimiento("VAQ", MAY_2026, "H", 6);
        Integer idTorito = altaAnimales.crearCandidatoTorito(new CrearCandidatoToritoRequest("ESP-01",
                AGO_2026.plusDays(4), false, null, null, "Toro cabaña", null, null, null, null, null));

        CargaIdentificacionResumen resumen = cargaIdentificacion.cargar(new CargarIdentificacionRequest(SEP_2026,
                null,
                List.of(grupo("2025-26", "M", "A1", "A2", "A3"), grupo("VAQ2025-26", "H", "B1", "B2")),
                List.of(new CargarIdentificacionRequest.Torito(idTorito, "T1")),
                false, null));

        assertThat(resumen.animalesCreados()).isEqualTo(5);
        assertThat(resumen.toritosIdentificados()).isEqualTo(1);
        assertThat(resumen.descuentos()).noneMatch(CargaIdentificacionResumen.Descuento::excedeSaldo);

        // cada grupo descuenta de SU ciclo; el torito no toca la cantidad
        assertThat(saldo("2025-26", "M")).isEqualTo(7);
        assertThat(saldo("VAQ2025-26", "H")).isEqualTo(4);
        assertThat(contar("select count(*) from ternero_sin_identificar_mov where tipo = 'IDENTIFICACION' "
                + "and id_trabajo = " + resumen.idTrabajo())).isEqualTo(2);

        // los animales nuevos: año del ciclo, categoría por sexo, caravana visual
        assertThat(contar("select count(*) from animal where anio_nacimiento = 2026 and fecha_nacimiento is null"))
                .isEqualTo(5);
        assertThat(contar("""
                select count(*) from v_animal_lista
                 where caravana in ('A1', 'A2', 'A3') and categoria_codigo = 'TERNERO' and sexo = 'M'
                """)).isEqualTo(3);
        assertThat(contar("""
                select count(*) from v_animal_lista
                 where caravana in ('B1', 'B2') and categoria_codigo = 'TERNERA' and sexo = 'H'
                """)).isEqualTo(2);
        assertThat(contar("select count(*) from evento where id_trabajo = " + resumen.idTrabajo())).isEqualTo(6);
        assertThat(contar("select count(*) from trabajo where tipo_trabajo = 'IDENTIFICACION'")).isEqualTo(1);

        // el torito: categoría TORITO, caravana especial (ADICIONAL) y ahora también la visual
        assertThat(jdbc.sql("select identificaciones from v_animal_lista where id_animal = :id")
                .param("id", idTorito).query(String.class).single()).isEqualTo("T1 · ESP-01");
        assertThat(jdbc.sql("select categoria_codigo from v_animal_lista where id_animal = :id")
                .param("id", idTorito).query(String.class).single()).isEqualTo("TORITO");
    }

    @Test
    void si_falla_una_caravana_no_queda_nada_de_la_identificacion() {
        nacimiento("VACA", AGO_2026, "M", 10);
        nacimiento("VAQ", MAY_2026, "H", 6);
        cargaIdentificacion.cargar(identificacion(false, grupo("VAQ2025-26", "H", "B2")));
        long animales = contar("select count(*) from animal");
        long movimientos = contar("select count(*) from ternero_sin_identificar_mov");

        // el primer grupo entra entero; el segundo choca con B2, que ya existe
        CargarIdentificacionRequest pedido = identificacion(false,
                grupo("2025-26", "M", "A1", "A2"), grupo("VAQ2025-26", "H", "B2"));
        assertThatThrownBy(() -> cargaIdentificacion.cargar(pedido))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("B2");

        assertThat(contar("select count(*) from animal")).isEqualTo(animales);
        assertThat(contar("select count(*) from ternero_sin_identificar_mov")).isEqualTo(movimientos);
        assertThat(contar("select count(*) from trabajo")).isEqualTo(1);
        assertThat(saldo("2025-26", "M")).isEqualTo(10);
        assertThat(saldo("VAQ2025-26", "H")).isEqualTo(5);
    }

    // ------------------------------------------------------ asignación de ciclo

    @Test
    void el_ciclo_se_asigna_solo_por_fecha_y_linea_y_se_puede_cambiar_a_mano() {
        assertThat(nacimiento("VACA", AGO_2026, "M", 1).ciclo()).isEqualTo("2025-26");
        assertThat(nacimiento("VACA", LocalDate.of(2027, 3, 20), "M", 1).ciclo()).isEqualTo("2025-26");
        assertThat(nacimiento("VACA", LocalDate.of(2027, 8, 1), "M", 1).ciclo()).isEqualTo("2026-27");
        // la misma fecha, otra línea, otro ciclo
        assertThat(nacimiento("VAQ", AGO_2026, "M", 1).ciclo()).isEqualTo("VAQ2025-26");
        assertThat(nacimiento("VAQ", MAY_2026, "H", 1).ciclo()).isEqualTo("VAQ2025-26");

        TerneroMovimientoDto automatico = nacimiento("VACA", AGO_2026, "H", 1);
        assertThat(automatico.cicloManual()).isFalse();

        TerneroMovimientoDto aMano = terneros.registrarNacimiento(new RegistrarNacimientoRequest(AGO_2026, false,
                "H", 1, "VACA", idCiclo("2026-27"), "nació antes de tiempo"));
        assertThat(aMano.ciclo()).isEqualTo("2026-27");
        assertThat(aMano.cicloManual()).isTrue();

        // entre el fin de un ciclo y la parición del siguiente no hay ciclo sugerido
        assertThat(ciclos.sugerido("VAQ", LocalDate.of(2027, 1, 15))).isEmpty();
        assertThatThrownBy(() -> nacimiento("VACA", LocalDate.of(2026, 6, 1), "M", 1))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("no cae en ningún ciclo");
    }

    @Test
    void los_ciclos_se_editan_pero_no_se_superponen_dentro_de_una_linea() {
        assertThatThrownBy(() -> ciclos.crear(new GuardarCicloProductivoRequest("2026-27b", "VACA",
                LocalDate.of(2026, 11, 1), LocalDate.of(2027, 8, 1), LocalDate.of(2027, 9, 30),
                LocalDate.of(2028, 1, 31), null)))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("se superpone con 2026-27");

        // editar las fechas no mueve lo cargado: queda en su ciclo y aparece en la alerta
        Integer idViejo = ciclos.crear(new GuardarCicloProductivoRequest("VAQ2024-25", "VAQ",
                LocalDate.of(2024, 7, 1), LocalDate.of(2025, 4, 1), LocalDate.of(2025, 7, 31),
                LocalDate.of(2025, 12, 31), null)).idCicloProductivo();
        TerneroMovimientoDto nac = nacimiento("VAQ", LocalDate.of(2025, 5, 1), "M", 2);
        assertThat(nac.idCicloProductivo()).isEqualTo(idViejo);

        ciclos.editar(idViejo, new GuardarCicloProductivoRequest("VAQ2024-25", "VAQ", LocalDate.of(2025, 6, 1),
                LocalDate.of(2025, 6, 1), LocalDate.of(2025, 7, 31), LocalDate.of(2025, 12, 31), null));

        assertThat(terneros.movimientos(idViejo)).singleElement()
                .satisfies(m -> assertThat(m.idMov()).isEqualTo(nac.idMov()));
        assertThat(terneros.alertas().fueraDeCiclo()).singleElement()
                .satisfies(a -> assertThat(a.idMov()).isEqualTo(nac.idMov()));
    }

    // ---------------------------------------------------------------- ayudas

    private TerneroMovimientoDto nacimiento(String linea, LocalDate fecha, String sexo, int cantidad) {
        return terneros.registrarNacimiento(
                new RegistrarNacimientoRequest(fecha, false, sexo, cantidad, linea, null, null));
    }

    private static RegistrarBajaTernerosRequest baja(String tipo, String linea, LocalDate fecha, String sexo,
            int cantidad) {
        return new RegistrarBajaTernerosRequest(tipo, fecha, false, sexo, cantidad, linea, null, null);
    }

    private CargarIdentificacionRequest.Grupo grupo(String ciclo, String sexo, String... caravanas) {
        return new CargarIdentificacionRequest.Grupo(idCiclo(ciclo), sexo, List.of(caravanas));
    }

    private static CargarIdentificacionRequest identificacion(boolean confirmarExceso,
            CargarIdentificacionRequest.Grupo... grupos) {
        return new CargarIdentificacionRequest(SEP_2026, null, List.of(grupos), List.of(), confirmarExceso, null);
    }

    private TerneroSaldoDto fila(String ciclo, String sexo) {
        return terneros.saldo().stream()
                .filter(s -> "CICLO".equals(s.nivel()) && ciclo.equals(s.ciclo()) && sexo.equals(s.sexo()))
                .findFirst()
                .orElseThrow();
    }

    private long saldo(String ciclo, String sexo) {
        return fila(ciclo, sexo).saldo();
    }
}

package com.anpael.planillas;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.anpael.BaseIntegracion;
import com.anpael.planillas.api.dto.CargaResultadosResumen;
import com.anpael.planillas.api.dto.CargarInseminacionRequest;
import com.anpael.planillas.service.CargaResultadosService;
import com.anpael.shared.exception.ReglaDeNegocioException;

/**
 * Inseminación desde la ficha del animal: toro / estado / comentario, guardado
 * igual que las inseminaciones que vinieron del Excel ("Toro: Minihué", la
 * condición corporal y un evento reproductivo INSEMINACION).
 */
class CargaInseminacionIT extends BaseIntegracion {

    @Autowired
    private CargaResultadosService cargaResultados;

    @Test
    void guarda_toro_estado_y_comentario_como_la_migracion() {
        Integer idRodeo = rodeoDePrueba();
        Integer idVaca = animal("H");

        CargaResultadosResumen resumen = cargaResultados.cargarInseminacion(new CargarInseminacionRequest(idRodeo,
                LocalDate.of(2022, 11, 11),
                List.of(new CargarInseminacionRequest.Linea(idVaca, "Minihue", new BigDecimal("4"), "GNRH"))));

        Map<String, Object> ev = jdbc.sql("""
                select tipo_trabajo, fecha, comentario, condicion_corporal, clase from v_animal_evento
                 where id_animal = :id
                """).param("id", idVaca).query().singleRow();
        assertThat(ev.get("tipo_trabajo")).isEqualTo("INSEMINACION");
        assertThat(ev.get("fecha").toString()).isEqualTo("2022-11-11");
        assertThat(ev.get("comentario")).isEqualTo("Toro: Minihue | GNRH");
        assertThat((BigDecimal) ev.get("condicion_corporal")).isEqualByComparingTo("4");
        assertThat(ev.get("clase")).isEqualTo("REPRODUCCION");
        assertThat(contar("select count(*) from evento_reproductivo where tipo = 'INSEMINACION'")).isEqualTo(1);
        assertThat(resumen.idTrabajo()).isNotNull();
    }

    @Test
    void sin_estado_ni_comentario_guarda_solo_el_toro() {
        Integer idRodeo = rodeoDePrueba();
        Integer idVaca = animal("H");

        cargaResultados.cargarInseminacion(new CargarInseminacionRequest(idRodeo, null,
                List.of(new CargarInseminacionRequest.Linea(idVaca, "Lautaro", null, " "))));

        assertThat(jdbc.sql("select comentario from v_animal_evento where id_animal = :id")
                .param("id", idVaca).query(String.class).single()).isEqualTo("Toro: Lautaro");
        assertThat(contar("select count(*) from medicion_corporal")).isZero();
    }

    @Test
    void no_se_insemina_un_macho_y_no_queda_nada_a_medias() {
        Integer idRodeo = rodeoDePrueba();
        Integer idVaca = animal("H");
        Integer idToro = animal("M");

        assertThatThrownBy(() -> cargaResultados.cargarInseminacion(new CargarInseminacionRequest(idRodeo, null,
                List.of(new CargarInseminacionRequest.Linea(idVaca, "Minihue", null, null),
                        new CargarInseminacionRequest.Linea(idToro, "Minihue", null, null)))))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("Solo se insemina una hembra");

        assertThat(contar("select count(*) from trabajo")).isZero();
        assertThat(contar("select count(*) from evento")).isZero();
    }

    private Integer rodeoDePrueba() {
        jdbc.sql("""
                insert into rodeo (id_establecimiento, nombre, orden) values (10, 'Rodeo de prueba', 1)
                on conflict (id_establecimiento, nombre) do nothing
                """).update();
        return jdbc.sql("select id_rodeo from rodeo where nombre = 'Rodeo de prueba'").query(Integer.class).single();
    }

    private Integer animal(String sexo) {
        return jdbc.sql("insert into animal (sexo, origen) values (:sexo, 'NACIDO') returning id_animal")
                .param("sexo", sexo).query(Integer.class).single();
    }
}

package com.anpael.trazabilidad;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.anpael.BaseIntegracion;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.api.dto.CorregirAnimalRequest;
import com.anpael.trazabilidad.api.dto.CrearAnimalRequest;
import com.anpael.trazabilidad.service.AnimalAltaService;
import com.anpael.trazabilidad.service.AnimalCorreccionService;

/**
 * Marca a fuego desde "Corregir / completar datos": se agrega si no tenía, y
 * si tenía, la anterior queda dada de baja (no se pisa).
 */
class AnimalCorreccionIT extends BaseIntegracion {

    @Autowired
    private AnimalAltaService alta;

    @Autowired
    private AnimalCorreccionService correccion;

    @Test
    void a_un_macho_sin_marca_se_le_agrega_la_marca_a_fuego() {
        Integer id = alta.crear(nuevo("T500", null, "M"));

        correccion.corregir(id, marca("930"));

        assertThat(identificaciones(id)).isEqualTo("T500 · 930");
    }

    @Test
    void corregir_la_marca_da_de_baja_la_anterior_y_conserva_su_historia() {
        Integer id = alta.crear(nuevo("T501", "931", "M"));

        correccion.corregir(id, marca("913"));

        assertThat(identificaciones(id)).isEqualTo("T501 · 913");
        List<Map<String, Object>> fuego = jdbc.sql("""
                select caravana, fecha_baja is not null as de_baja, motivo_baja from identificacion
                 where id_animal = :id and id_tipo_ident = 3 order by id_identificacion
                """).param("id", id).query().listOfRows();
        assertThat(fuego).hasSize(2);
        assertThat(fuego.get(0)).containsEntry("caravana", "931").containsEntry("de_baja", true)
                .containsEntry("motivo_baja", "Corregida desde la ficha del animal");
        assertThat(fuego.get(1)).containsEntry("caravana", "913").containsEntry("de_baja", false);
    }

    @Test
    void la_misma_marca_no_cambia_nada() {
        Integer id = alta.crear(nuevo("T502", "932", "M"));

        correccion.corregir(id, marca("932"));

        assertThat(contar("select count(*) from identificacion where id_tipo_ident = 3")).isEqualTo(1);
    }

    @Test
    void no_se_le_pone_marca_a_una_hembra_ni_se_repite_la_de_otro_animal() {
        Integer vaca = alta.crear(nuevo("H500", null, "H"));
        Integer toro = alta.crear(nuevo("T503", null, "M"));
        alta.crear(nuevo("T504", "933", "M"));

        assertThatThrownBy(() -> correccion.corregir(vaca, marca("934")))
                .isInstanceOf(ReglaDeNegocioException.class).hasMessageContaining("solo para machos");
        assertThatThrownBy(() -> correccion.corregir(toro, marca("933")))
                .isInstanceOf(ReglaDeNegocioException.class).hasMessageContaining("Ya existe otro animal");
    }

    @Test
    void a_una_hembra_se_le_agrega_y_se_le_corrige_el_numero_adicional() {
        Integer vaca = alta.crear(nuevo("H700", null, "H"));

        correccion.corregir(vaca, adicional("RP-20"));
        assertThat(identificaciones(vaca)).isEqualTo("H700 · RP-20");

        correccion.corregir(vaca, adicional("RP-21"));
        assertThat(identificaciones(vaca)).isEqualTo("H700 · RP-21");
        assertThat(contar("select count(*) from identificacion where id_tipo_ident = 5 and fecha_baja is not null"))
                .isEqualTo(1);
    }

    @Test
    void el_numero_adicional_de_otro_animal_no_se_repite() {
        Integer una = alta.crear(nuevo("H701", null, "H"));
        Integer otra = alta.crear(nuevo("H702", null, "H"));
        correccion.corregir(otra, adicional("RP-22"));

        assertThatThrownBy(() -> correccion.corregir(una, adicional("RP-22")))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("Ya existe otro animal con el número adicional RP-22");
    }

    private static CrearAnimalRequest nuevo(String caravana, String marcaFuego, String sexo) {
        return new CrearAnimalRequest(caravana, marcaFuego, null, sexo, "NACIDO", null, null, null, null, null,
                null, null, null, null, null, null, null, null, null, null, null, null);
    }

    private static CorregirAnimalRequest marca(String marcaFuego) {
        return new CorregirAnimalRequest(null, null, null, null, null, null, null, null, null, null, marcaFuego, null);
    }

    private static CorregirAnimalRequest adicional(String numeroAdicional) {
        return new CorregirAnimalRequest(null, null, null, null, null, null, null, null, null, null, null,
                numeroAdicional);
    }

    private String identificaciones(Integer idAnimal) {
        return jdbc.sql("select identificaciones from v_animal_lista where id_animal = :id")
                .param("id", idAnimal).query(String.class).single();
    }
}

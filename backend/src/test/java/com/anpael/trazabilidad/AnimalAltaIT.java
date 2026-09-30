package com.anpael.trazabilidad;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.anpael.BaseIntegracion;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.api.dto.CrearAnimalRequest;
import com.anpael.trazabilidad.service.AnimalAltaService;

/**
 * Alta de un animal con su identificación: caravana visual y, en los machos,
 * marca a fuego. En un macho alcanza con una de las dos.
 */
class AnimalAltaIT extends BaseIntegracion {

    @Autowired
    private AnimalAltaService alta;

    @Test
    void un_macho_se_da_de_alta_con_caravana_y_marca_a_fuego() {
        Integer id = alta.crear(pedido("T100", "924", "M"));

        assertThat(identificaciones(id)).isEqualTo("T100 · 924");
    }

    @Test
    void un_macho_se_puede_dar_de_alta_solo_con_la_marca_a_fuego() {
        Integer id = alta.crear(pedido(null, "925", "M"));

        assertThat(identificaciones(id)).isEqualTo("925");
        assertThat(jdbc.sql("select caravana from v_animal_lista where id_animal = :id")
                .param("id", id).query(String.class).single()).isEqualTo("925");
    }

    @Test
    void una_hembra_no_lleva_marca_a_fuego_y_necesita_caravana() {
        assertThatThrownBy(() -> alta.crear(pedido("H200", "926", "H")))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("solo para machos");
        assertThatThrownBy(() -> alta.crear(pedido(" ", null, "H")))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("cargá la caravana.");
        assertThat(contar("select count(*) from animal")).isZero();
    }

    @Test
    void un_macho_sin_caravana_ni_marca_no_se_da_de_alta() {
        assertThatThrownBy(() -> alta.crear(pedido(null, " ", "M")))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("cargá la caravana o la marca a fuego");
    }

    @Test
    void la_marca_a_fuego_no_se_repite_en_el_establecimiento() {
        alta.crear(pedido(null, "927", "M"));

        assertThatThrownBy(() -> alta.crear(pedido("T300", "927", "M")))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("Ya existe un animal con la marca a fuego 927");
        assertThat(contar("select count(*) from animal")).isEqualTo(1);
    }

    @Test
    void machos_y_hembras_pueden_llevar_numero_adicional_que_no_se_repite() {
        Integer vaca = alta.crear(pedido("H600", null, "H", "RP-12"));
        Integer toro = alta.crear(pedido("T600", "940", "M", "RP-13"));

        assertThat(identificaciones(vaca)).isEqualTo("H600 · RP-12");
        assertThat(identificaciones(toro)).isEqualTo("T600 · 940 · RP-13");
        assertThatThrownBy(() -> alta.crear(pedido("H601", null, "H", "rp-12")))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("Ya existe un animal con el número adicional rp-12");
    }

    @Test
    void el_numero_adicional_solo_no_alcanza_como_identificacion() {
        assertThatThrownBy(() -> alta.crear(pedido(null, null, "H", "RP-14")))
                .isInstanceOf(ReglaDeNegocioException.class)
                .hasMessageContaining("Falta la identificación");
    }

    private static CrearAnimalRequest pedido(String caravana, String marcaFuego, String sexo) {
        return pedido(caravana, marcaFuego, sexo, null);
    }

    private static CrearAnimalRequest pedido(String caravana, String marcaFuego, String sexo, String numeroAdicional) {
        return new CrearAnimalRequest(caravana, marcaFuego, numeroAdicional, sexo, "NACIDO", null, null, null, null,
                null, null, null, null, null, null, null, null, null, null, null, null, null);
    }

    private String identificaciones(Integer idAnimal) {
        return jdbc.sql("select identificaciones from v_animal_lista where id_animal = :id")
                .param("id", idAnimal).query(String.class).single();
    }
}

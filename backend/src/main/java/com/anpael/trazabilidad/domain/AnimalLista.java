package com.anpael.trazabilidad.domain;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import org.hibernate.annotations.Immutable;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

/**
 * El padron listo para mostrar (docs/modelo-datos.md). Mapea la vista
 * v_animal_lista, que ya resuelve la identificacion vigente de cada animal
 * sin duplicar filas -algo que un JOIN directo contra `identificacion` NO
 * garantiza- y trae categoria, rodeo y los flags de saneamiento
 * (sin_categoria, tiene_baja) en una sola consulta.
 *
 * @Immutable porque es una vista: nunca se escribe a traves de esta entidad.
 * Asignar categoria o rodeo se hace contra las tablas de abajo
 * (animal_categoria, animal_rodeo / mover_a_rodeo()), no aca.
 */
@Entity
@Immutable
@Table(name = "v_animal_lista")
@Getter
public class AnimalLista {

    @Id
    @Column(name = "id_animal")
    private Integer idAnimal;

    @Column(name = "caravana")
    private String caravana;

    @Column(name = "tipo_ident")
    private String tipoIdent;

    @Column(name = "sexo")
    private String sexo;

    @Column(name = "raza")
    private String raza;

    @Column(name = "categoria_codigo")
    private String categoriaCodigo;

    @Column(name = "categoria")
    private String categoria;

    @Column(name = "fecha_nacimiento")
    private LocalDate fechaNacimiento;

    @Column(name = "fecha_nac_es_estimada")
    private Boolean fechaNacEsEstimada;

    @Column(name = "fecha_ident")
    private LocalDate fechaIdent;

    @Column(name = "fecha_ident_es_estimada")
    private Boolean fechaIdentEsEstimada;

    @Column(name = "cuig")
    private String cuig;

    @Column(name = "activo")
    private Boolean activo;

    @Column(name = "tiene_baja")
    private Boolean tieneBaja;

    @Column(name = "validacion")
    private String validacion;

    @Column(name = "validacion_obs")
    private String validacionObs;

    @Column(name = "revisado_en")
    private OffsetDateTime revisadoEn;

    @Column(name = "revisado_por")
    private String revisadoPor;

    @Column(name = "eventos")
    private Long eventos;

    @Column(name = "sin_fecha_nac")
    private Boolean sinFechaNac;

    @Column(name = "con_fecha_estimada")
    private Boolean conFechaEstimada;

    @Column(name = "sin_categoria")
    private Boolean sinCategoria;

    @Column(name = "rodeo")
    private String rodeo;

    @Column(name = "en_rodeo_desde")
    private LocalDate enRodeoDesde;

    @Column(name = "id_rodeo")
    private Integer idRodeo;

    @Column(name = "id_categoria")
    private Integer idCategoria;
}

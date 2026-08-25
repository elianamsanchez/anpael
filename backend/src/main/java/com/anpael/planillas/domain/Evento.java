package com.anpael.planillas.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * Un animal dentro de un trabajo (docs/modelo-datos.md). origenDato y
 * validado se setean explicitos en Java aunque la base tenga default: JPA
 * manda todas las columnas mapeadas en el INSERT, el default de la
 * columna no se usa. id_persona_registro tambien: el trigger
 * forzar_autoria() solo actua si auth.uid() no es null (ADR-001), y el
 * backend se conecta con un solo rol de base -entra siempre en null.
 */
@Entity
@Table(name = "evento")
@Getter
@Setter
public class Evento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_evento")
    private Integer idEvento;

    @Column(name = "id_trabajo", nullable = false)
    private Integer idTrabajo;

    @Column(name = "id_animal", nullable = false)
    private Integer idAnimal;

    @Column(name = "comentario")
    private String comentario;

    @Column(name = "origen_dato", nullable = false)
    private String origenDato = "MANUAL";

    @Column(name = "validado", nullable = false)
    private Boolean validado = true;

    @Column(name = "id_persona_registro")
    private Integer idPersonaRegistro;
}

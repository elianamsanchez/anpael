package com.anpael.planillas.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * Inseminación, celo, monta o sincronización de un evento (docs/modelo-datos.md).
 * La app carga solo INSEMINACION, igual que la migración desde Excel: el
 * toro va como texto en evento.comentario ("Toro: Minihué") porque casi
 * ningún toro de inseminación está cargado como animal -idPadreAsignado
 * queda para cuando lo esté-.
 */
@Entity
@Table(name = "evento_reproductivo")
@Getter
@Setter
public class EventoReproductivo {

    @Id
    @Column(name = "id_evento")
    private Integer idEvento;

    /** INSEMINACION, CELO, MONTA o SINCRONIZACION (CHECK en la base). */
    @Column(name = "tipo", nullable = false)
    private String tipo;

    @Column(name = "id_servicio")
    private Integer idServicio;

    @Column(name = "id_padre_asignado")
    private Integer idPadreAsignado;

    @Column(name = "partida_semen")
    private String partidaSemen;

    @Column(name = "nro_tubo")
    private String nroTubo;

    @Column(name = "protocolo")
    private String protocolo;

    @Column(name = "id_inseminador")
    private Integer idInseminador;
}

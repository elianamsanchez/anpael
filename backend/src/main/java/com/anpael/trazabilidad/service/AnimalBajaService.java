package com.anpael.trazabilidad.service;

import java.math.BigDecimal;
import java.time.LocalDate;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.shared.security.ContextoAutenticacion;
import com.anpael.trazabilidad.domain.Baja;
import com.anpael.trazabilidad.domain.CausaBaja;
import com.anpael.trazabilidad.infrastructure.BajaRepository;
import com.anpael.trazabilidad.infrastructure.CausaBajaRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

/**
 * Dar de baja a un animal (v0.2a, docs/etapas.md). A diferencia de
 * categoria/rodeo, esto no se mueve ni se corrige: baja_id_animal_key es
 * UNIQUE, asi que solo hay una oportunidad de registrarla bien.
 *
 * El animal NO se borra ni se toca animal_categoria/animal_rodeo -esos
 * quedan como historial de donde estaba al momento de salir-, pero
 * `animal.activo` pasa a false: es la señal de "ya no esta vigente" que
 * usan las pantallas de stock. No hay trigger que lo haga solo.
 */
@Service
public class AnimalBajaService {

    private final BajaRepository bajas;
    private final CausaBajaRepository causasBaja;

    @PersistenceContext
    private EntityManager entityManager;

    public AnimalBajaService(BajaRepository bajas, CausaBajaRepository causasBaja) {
        this.bajas = bajas;
        this.causasBaja = causasBaja;
    }

    @Transactional
    public String darDeBaja(Integer idAnimal, Integer idCausaBaja, LocalDate fecha, Boolean fechaEsEstimada,
            BigDecimal pesoSalidaKg, String destino, String observaciones) {

        if (bajas.existsByIdAnimal(idAnimal)) {
            throw new ReglaDeNegocioException("Este animal ya tiene una baja registrada. No se puede cargar otra.");
        }

        CausaBaja causa = causasBaja.findById(idCausaBaja)
                .orElseThrow(() -> new ReglaDeNegocioException("La causa de baja " + idCausaBaja + " no existe."));

        Baja baja = new Baja();
        baja.setIdAnimal(idAnimal);
        baja.setIdCausaBaja(idCausaBaja);
        baja.setFecha(fecha);
        baja.setPesoSalidaKg(pesoSalidaKg);
        baja.setDestino(destino);
        baja.setObservaciones(observaciones);
        baja.setFechaEsEstimada(Boolean.TRUE.equals(fechaEsEstimada));
        baja.setIdPersonaRegistro(ContextoAutenticacion.idPersonaActual());
        bajas.save(baja);

        entityManager.createNativeQuery("update animal set activo = false where id_animal = :idAnimal")
                .setParameter("idAnimal", idAnimal)
                .executeUpdate();

        return "Baja registrada (" + causa.getTipoBaja() + ": " + causa.getDescripcion() + ") el " + fecha + ".";
    }
}

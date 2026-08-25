package com.anpael.trazabilidad.service;

import java.time.LocalDate;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.ReglaDeNegocioException;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

/**
 * Mover un animal de rodeo llama a mover_a_rodeo() (docs/modelo-datos.md):
 * "no hay que hacer INSERT a mano". La funcion ya valida que el rodeo
 * exista y este activo, que la fecha sea posterior al ingreso actual, y
 * cierra/abre las filas de animal_rodeo en un solo paso. Si devuelve un
 * mensaje que arranca con "ERROR", se traduce a una regla de negocio
 * violada (409) en vez de dejarlo pasar como si hubiera funcionado.
 */
@Service
public class AnimalRodeoService {

    @PersistenceContext
    private EntityManager entityManager;

    @Transactional
    public String asignar(Integer idAnimal, Integer idRodeo, LocalDate fecha) {
        String resultado = (String) entityManager
                .createNativeQuery("select mover_a_rodeo(:idAnimal, :idRodeo, :fecha)")
                .setParameter("idAnimal", idAnimal)
                .setParameter("idRodeo", idRodeo)
                .setParameter("fecha", fecha)
                .getSingleResult();

        if (resultado != null && resultado.startsWith("ERROR")) {
            throw new ReglaDeNegocioException(resultado);
        }
        return resultado;
    }
}

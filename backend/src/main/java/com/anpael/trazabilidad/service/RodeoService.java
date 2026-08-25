package com.anpael.trazabilidad.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.NoEncontradoException;
import com.anpael.trazabilidad.domain.Rodeo;
import com.anpael.trazabilidad.infrastructure.RodeoRepository;

@Service
@Transactional(readOnly = true)
public class RodeoService {

    private final RodeoRepository rodeos;

    public RodeoService(RodeoRepository rodeos) {
        this.rodeos = rodeos;
    }

    public Rodeo obtener(Integer idRodeo) {
        return rodeos.findById(idRodeo)
                .orElseThrow(() -> new NoEncontradoException("No existe el rodeo " + idRodeo));
    }
}

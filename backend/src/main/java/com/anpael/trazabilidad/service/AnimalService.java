package com.anpael.trazabilidad.service;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.NoEncontradoException;
import com.anpael.trazabilidad.domain.AnimalEvento;
import com.anpael.trazabilidad.domain.AnimalLista;
import com.anpael.trazabilidad.infrastructure.AnimalEventoRepository;
import com.anpael.trazabilidad.infrastructure.AnimalListaRepository;

@Service
@Transactional(readOnly = true)
public class AnimalService {

    private final AnimalListaRepository animales;
    private final AnimalEventoRepository eventos;

    public AnimalService(AnimalListaRepository animales, AnimalEventoRepository eventos) {
        this.animales = animales;
        this.eventos = eventos;
    }

    public Page<AnimalLista> buscar(String caravana, Boolean sinCategoria, Boolean sinRodeo, Pageable pageable) {
        Specification<AnimalLista> spec = Specification.where(null);

        if (caravana != null && !caravana.isBlank()) {
            String patron = "%" + caravana.trim().toLowerCase() + "%";
            spec = spec.and((raiz, consulta, cb) -> cb.like(cb.lower(raiz.get("caravana")), patron));
        }
        if (Boolean.TRUE.equals(sinCategoria)) {
            spec = spec.and((raiz, consulta, cb) -> cb.isTrue(raiz.get("sinCategoria")));
        }
        if (Boolean.TRUE.equals(sinRodeo)) {
            spec = spec.and((raiz, consulta, cb) -> cb.isNull(raiz.get("rodeo")));
        }

        return animales.findAll(spec, pageable);
    }

    public AnimalLista obtener(Integer idAnimal) {
        return animales.findById(idAnimal)
                .orElseThrow(() -> new NoEncontradoException("No existe el animal " + idAnimal));
    }

    /** Los animales vigentes de un rodeo, ordenados por caravana. Lo usa el módulo planillas. */
    public List<AnimalLista> buscarPorRodeo(Integer idRodeo) {
        return animales.buscarPorRodeo(idRodeo);
    }

    /** La historia del animal: un evento por trabajo, el más reciente primero. */
    public List<AnimalEvento> historial(Integer idAnimal) {
        obtener(idAnimal); // 404 si no existe, antes de devolver una lista vacia enganosa
        return eventos.findByIdAnimalOrderByFechaDesc(idAnimal);
    }
}

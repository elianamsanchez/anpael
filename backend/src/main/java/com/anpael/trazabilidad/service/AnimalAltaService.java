package com.anpael.trazabilidad.service;

import java.time.LocalDate;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.domain.Animal;
import com.anpael.trazabilidad.domain.Establecimiento;
import com.anpael.trazabilidad.domain.Identificacion;
import com.anpael.trazabilidad.domain.TipoIdentificacion;
import com.anpael.trazabilidad.api.dto.CrearAnimalRequest;
import com.anpael.trazabilidad.infrastructure.AnimalRepository;
import com.anpael.trazabilidad.infrastructure.CabanaRepository;
import com.anpael.trazabilidad.infrastructure.EstablecimientoRepository;
import com.anpael.trazabilidad.infrastructure.IdentificacionRepository;
import com.anpael.trazabilidad.infrastructure.PelajeRepository;
import com.anpael.trazabilidad.infrastructure.RazaRepository;
import com.anpael.trazabilidad.infrastructure.TipoIdentificacionRepository;

/**
 * Alta de un animal nuevo (v0.2a, docs/etapas.md): hasta ahora la migracion
 * traia los animales completos y el backend solo corregia -AnimalCorreccionService-.
 * Un ternero que nace o un animal que se compra necesita entrar por primera
 * vez, con su identificacion visual. La caravana se guarda siempre como
 * VISUAL en el establecimiento propio activo (Santa Ana): es el mismo
 * supuesto de un unico campo de trabajo que ya usa CargaResultadosService al
 * tomar el establecimiento del rodeo.
 */
@Service
public class AnimalAltaService {

    private static final String CODIGO_VISUAL = "VISUAL";

    private final AnimalRepository animales;
    private final RazaRepository razas;
    private final PelajeRepository pelajes;
    private final CabanaRepository cabanas;
    private final EstablecimientoRepository establecimientos;
    private final TipoIdentificacionRepository tiposIdent;
    private final IdentificacionRepository identificaciones;
    private final AnimalCategoriaService animalCategoriaService;
    private final AnimalRodeoService animalRodeoService;

    public AnimalAltaService(AnimalRepository animales, RazaRepository razas, PelajeRepository pelajes,
            CabanaRepository cabanas, EstablecimientoRepository establecimientos,
            TipoIdentificacionRepository tiposIdent, IdentificacionRepository identificaciones,
            AnimalCategoriaService animalCategoriaService, AnimalRodeoService animalRodeoService) {
        this.animales = animales;
        this.razas = razas;
        this.pelajes = pelajes;
        this.cabanas = cabanas;
        this.establecimientos = establecimientos;
        this.tiposIdent = tiposIdent;
        this.identificaciones = identificaciones;
        this.animalCategoriaService = animalCategoriaService;
        this.animalRodeoService = animalRodeoService;
    }

    @Transactional
    public Integer crear(CrearAnimalRequest pedido) {
        if (pedido.idRaza() != null && !razas.existsById(pedido.idRaza())) {
            throw new ReglaDeNegocioException("La raza " + pedido.idRaza() + " no existe.");
        }
        if (pedido.idPelaje() != null && !pelajes.existsById(pedido.idPelaje())) {
            throw new ReglaDeNegocioException("El pelaje " + pedido.idPelaje() + " no existe.");
        }
        if (pedido.idCabana() != null && !cabanas.existsById(pedido.idCabana())) {
            throw new ReglaDeNegocioException("La cabaña " + pedido.idCabana() + " no existe.");
        }
        if (pedido.idEstabOrigen() != null && !establecimientos.existsById(pedido.idEstabOrigen())) {
            throw new ReglaDeNegocioException("El establecimiento de origen " + pedido.idEstabOrigen() + " no existe.");
        }
        if (pedido.idMadre() != null && !animales.existsById(pedido.idMadre())) {
            throw new ReglaDeNegocioException("La madre " + pedido.idMadre() + " no existe.");
        }
        if (pedido.idPadre() != null && !animales.existsById(pedido.idPadre())) {
            throw new ReglaDeNegocioException("El padre " + pedido.idPadre() + " no existe.");
        }

        Establecimiento estabPropio = establecimientoDeTrabajo();
        TipoIdentificacion visual = tiposIdent.findByCodigo(CODIGO_VISUAL)
                .orElseThrow(() -> new ReglaDeNegocioException("Falta el tipo de identificación VISUAL en el catálogo."));

        String caravana = pedido.caravana().trim();
        if (identificaciones.existsByIdTipoIdentAndIdEstablecimientoAndCaravanaIgnoreCase(
                visual.getIdTipoIdent(), estabPropio.getIdEstablecimiento(), caravana)) {
            throw new ReglaDeNegocioException(
                    "Ya existe un animal con la caravana " + caravana + " en " + estabPropio.getNombre() + ".");
        }

        Animal animal = new Animal();
        animal.setIdEstabOrigen(pedido.idEstabOrigen());
        animal.setIdRaza(pedido.idRaza());
        animal.setIdPelaje(pedido.idPelaje());
        animal.setIdCabana(pedido.idCabana());
        animal.setIdMadre(pedido.idMadre());
        animal.setIdPadre(pedido.idPadre());
        animal.setSexo(pedido.sexo());
        animal.setFechaNacimiento(pedido.fechaNacimiento());
        animal.setFechaNacEsEstimada(Boolean.TRUE.equals(pedido.fechaNacEsEstimada()));
        animal.setPesoNacerKg(pedido.pesoNacerKg());
        animal.setOrigen(pedido.origen());
        animal.setFechaIngreso(pedido.fechaIngreso());
        animal.setActivo(true);
        animal = animales.save(animal);

        Identificacion ident = new Identificacion();
        ident.setIdAnimal(animal.getIdAnimal());
        ident.setIdTipoIdent(visual.getIdTipoIdent());
        ident.setIdEstablecimiento(estabPropio.getIdEstablecimiento());
        ident.setCaravana(caravana);
        ident.setFechaAlta(pedido.fechaIngreso() != null ? pedido.fechaIngreso() : LocalDate.now());
        ident.setFechaAltaEsEstimada(false);
        identificaciones.save(ident);

        LocalDate fechaAsignacion = pedido.fechaIngreso() != null ? pedido.fechaIngreso() : LocalDate.now();
        if (pedido.idCategoria() != null) {
            animalCategoriaService.asignar(animal.getIdAnimal(), pedido.idCategoria(), fechaAsignacion);
        }
        if (pedido.idRodeo() != null) {
            animalRodeoService.asignar(animal.getIdAnimal(), pedido.idRodeo(), fechaAsignacion);
        }

        return animal.getIdAnimal();
    }

    private Establecimiento establecimientoDeTrabajo() {
        List<Establecimiento> propios = establecimientos.findByEsPropioTrueAndActivoTrue();
        if (propios.size() != 1) {
            throw new ReglaDeNegocioException(
                    "No se pudo determinar el establecimiento propio activo (hay " + propios.size() + "). "
                            + "Revisar la tabla establecimiento.");
        }
        return propios.get(0);
    }
}

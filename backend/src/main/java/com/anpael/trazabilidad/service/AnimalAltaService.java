package com.anpael.trazabilidad.service;

import java.time.LocalDate;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.anpael.shared.exception.NoEncontradoException;
import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.domain.Animal;
import com.anpael.trazabilidad.domain.Categoria;
import com.anpael.trazabilidad.domain.Establecimiento;
import com.anpael.trazabilidad.domain.Identificacion;
import com.anpael.trazabilidad.domain.TipoIdentificacion;
import com.anpael.trazabilidad.api.dto.CrearAnimalRequest;
import com.anpael.trazabilidad.api.dto.CrearCandidatoToritoRequest;
import com.anpael.trazabilidad.infrastructure.AnimalRepository;
import com.anpael.trazabilidad.infrastructure.CabanaRepository;
import com.anpael.trazabilidad.infrastructure.CategoriaRepository;
import com.anpael.trazabilidad.infrastructure.EstablecimientoRepository;
import com.anpael.trazabilidad.infrastructure.IdentificacionRepository;
import com.anpael.trazabilidad.infrastructure.PelajeRepository;
import com.anpael.trazabilidad.infrastructure.RazaRepository;
import com.anpael.trazabilidad.infrastructure.TipoIdentificacionRepository;

/**
 * Alta de un animal nuevo (v0.2a, docs/etapas.md): hasta ahora la migracion
 * traia los animales completos y el backend solo corregia -AnimalCorreccionService-.
 * Un ternero que nace o un animal que se compra necesita entrar por primera
 * vez, con su identificacion: la caravana VISUAL y, en los machos, la marca
 * a fuego (FUEGO) -alcanza con una de las dos: hay toros que solo tienen
 * marca a fuego-. Se guardan en el establecimiento propio activo (Santa Ana): es el mismo
 * supuesto de un unico campo de trabajo que ya usa CargaResultadosService al
 * tomar el establecimiento del rodeo.
 *
 * Terneros sin caravana (migración 20260929120000):
 *   - un candidato a torito es animal desde que nace, con categoría TORITO y
 *     una identificación ADICIONAL (la caravana especial), todavía sin VISUAL
 *     -crearCandidatoTorito-. En el trabajo de identificación se le agrega la
 *     VISUAL -agregarIdentificacionVisual-, sin tocar la cantidad pendiente.
 *   - el resto se lleva como cantidad (TerneroSinIdentificarService) y pasa a
 *     ser animal recién en la identificación -crearTerneroIdentificado-.
 */
@Service
public class AnimalAltaService {

    private static final String CODIGO_VISUAL = "VISUAL";
    private static final String CODIGO_ADICIONAL = "ADICIONAL";
    private static final String CODIGO_FUEGO = "FUEGO";
    private static final String CATEGORIA_TORITO = "TORITO";

    private final AnimalRepository animales;
    private final RazaRepository razas;
    private final PelajeRepository pelajes;
    private final CabanaRepository cabanas;
    private final EstablecimientoRepository establecimientos;
    private final TipoIdentificacionRepository tiposIdent;
    private final IdentificacionRepository identificaciones;
    private final CategoriaRepository categorias;
    private final AnimalCategoriaService animalCategoriaService;
    private final AnimalRodeoService animalRodeoService;
    private final EstablecimientoPropioService establecimientoPropio;

    public AnimalAltaService(AnimalRepository animales, RazaRepository razas, PelajeRepository pelajes,
            CabanaRepository cabanas, EstablecimientoRepository establecimientos,
            TipoIdentificacionRepository tiposIdent, IdentificacionRepository identificaciones,
            CategoriaRepository categorias, AnimalCategoriaService animalCategoriaService,
            AnimalRodeoService animalRodeoService, EstablecimientoPropioService establecimientoPropio) {
        this.animales = animales;
        this.razas = razas;
        this.pelajes = pelajes;
        this.cabanas = cabanas;
        this.establecimientos = establecimientos;
        this.tiposIdent = tiposIdent;
        this.identificaciones = identificaciones;
        this.categorias = categorias;
        this.animalCategoriaService = animalCategoriaService;
        this.animalRodeoService = animalRodeoService;
        this.establecimientoPropio = establecimientoPropio;
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
        validarPadres(pedido.idMadre(), pedido.idPadre());

        // La identificación: la caravana, o en un macho la marca a fuego (hay
        // toros que solo tienen marca a fuego). La marca a fuego es de machos.
        String caravana = textoOVacio(pedido.caravana());
        String marcaFuego = textoOVacio(pedido.marcaFuego());
        if (marcaFuego != null && !"M".equals(pedido.sexo())) {
            throw new ReglaDeNegocioException("La marca a fuego es solo para machos.");
        }
        if (caravana == null && marcaFuego == null) {
            throw new ReglaDeNegocioException("Falta la identificación: cargá la caravana"
                    + ("M".equals(pedido.sexo()) ? " o la marca a fuego." : "."));
        }
        if (caravana != null) {
            exigirCaravanaLibre(CODIGO_VISUAL, caravana);
        }
        if (marcaFuego != null) {
            exigirCaravanaLibre(CODIGO_FUEGO, marcaFuego);
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
        if (pedido.fechaNacimiento() != null) {
            // la fecha completa manda: si se carga, el año se recalcula de
            // ella y pisa cualquier año cargado a mano en el mismo pedido.
            animal.setAnioNacimiento(pedido.fechaNacimiento().getYear());
        } else if (pedido.anioNacimiento() != null) {
            animal.setAnioNacimiento(pedido.anioNacimiento());
        }
        animal.setPesoNacerKg(pedido.pesoNacerKg());
        animal.setOrigen(pedido.origen());
        animal.setFechaIngreso(pedido.fechaIngreso());
        animal.setAnioIngreso(pedido.anioIngreso());
        animal.setAnioPrimerServicio(pedido.anioPrimerServicio());
        animal.setPadreNombre(pedido.padreNombre());
        animal.setObservaciones(pedido.observaciones());
        animal.setActivo(true);
        animal = animales.save(animal);

        LocalDate fechaAsignacion = pedido.fechaIngreso() != null ? pedido.fechaIngreso() : LocalDate.now();
        if (caravana != null) {
            guardarIdentificacion(animal.getIdAnimal(), CODIGO_VISUAL, caravana, fechaAsignacion);
        }
        if (marcaFuego != null) {
            guardarIdentificacion(animal.getIdAnimal(), CODIGO_FUEGO, marcaFuego, fechaAsignacion);
        }

        if (pedido.idCategoria() != null) {
            animalCategoriaService.asignar(animal.getIdAnimal(), pedido.idCategoria(), fechaAsignacion, false);
        }
        if (pedido.idRodeo() != null) {
            animalRodeoService.asignar(animal.getIdAnimal(), pedido.idRodeo(), fechaAsignacion, false);
        }

        return animal.getIdAnimal();
    }

    /**
     * Candidato a torito: macho, nacido en el campo, con categoría TORITO desde
     * que nace y la caravana especial como identificación ADICIONAL. Todavía
     * no tiene VISUAL; no cuenta en la cantidad de terneros sin identificar.
     */
    @Transactional
    public Integer crearCandidatoTorito(CrearCandidatoToritoRequest pedido) {
        if (pedido.idRaza() != null && !razas.existsById(pedido.idRaza())) {
            throw new ReglaDeNegocioException("La raza " + pedido.idRaza() + " no existe.");
        }
        if (pedido.idPelaje() != null && !pelajes.existsById(pedido.idPelaje())) {
            throw new ReglaDeNegocioException("El pelaje " + pedido.idPelaje() + " no existe.");
        }
        validarPadres(pedido.idMadre(), pedido.idPadre());

        String caravana = pedido.caravanaAdicional().trim();
        exigirCaravanaLibre(CODIGO_ADICIONAL, caravana);
        Categoria torito = categoriaPorCodigo(CATEGORIA_TORITO);

        Animal animal = new Animal();
        animal.setIdRaza(pedido.idRaza());
        animal.setIdPelaje(pedido.idPelaje());
        animal.setIdMadre(pedido.idMadre());
        animal.setIdPadre(pedido.idPadre());
        animal.setPadreNombre(pedido.padreNombre());
        animal.setSexo("M");
        animal.setOrigen("NACIDO");
        animal.setFechaNacimiento(pedido.fechaNacimiento());
        animal.setFechaNacEsEstimada(Boolean.TRUE.equals(pedido.fechaNacEsEstimada()));
        animal.setAnioNacimiento(pedido.fechaNacimiento().getYear());
        animal.setPesoNacerKg(pedido.pesoNacerKg());
        animal.setObservaciones(pedido.observaciones());
        animal.setActivo(true);
        animal = animales.save(animal);

        guardarIdentificacion(animal.getIdAnimal(), CODIGO_ADICIONAL, caravana, pedido.fechaNacimiento());
        animalCategoriaService.asignar(animal.getIdAnimal(), torito.getIdCategoria(), pedido.fechaNacimiento(),
                pedido.fechaNacEsEstimada());
        if (pedido.idRodeo() != null) {
            animalRodeoService.asignar(animal.getIdAnimal(), pedido.idRodeo(), pedido.fechaNacimiento(),
                    pedido.fechaNacEsEstimada());
        }
        return animal.getIdAnimal();
    }

    /**
     * Un ternero que se llevaba como cantidad y en la identificación pasa a
     * ser animal: sin fecha de nacimiento (no se sabe), con el año del ciclo,
     * categoría TERNERO/TERNERA según el sexo y su caravana VISUAL. Lo usa el
     * módulo planillas; el descuento de la cantidad lo hace quien llama.
     */
    @Transactional
    public Integer crearTerneroIdentificado(String caravana, String sexo, int anioNacimiento, Integer idRodeo,
            LocalDate fechaIdentificacion) {
        String limpia = caravana.trim();
        exigirCaravanaLibre(CODIGO_VISUAL, limpia);
        Categoria categoria = categoriaPorCodigo("M".equals(sexo) ? "TERNERO" : "TERNERA");

        Animal animal = new Animal();
        animal.setSexo(sexo);
        animal.setOrigen("NACIDO");
        animal.setFechaNacEsEstimada(false);
        animal.setAnioNacimiento(anioNacimiento);
        animal.setActivo(true);
        animal = animales.save(animal);

        guardarIdentificacion(animal.getIdAnimal(), CODIGO_VISUAL, limpia, fechaIdentificacion);
        animalCategoriaService.asignar(animal.getIdAnimal(), categoria.getIdCategoria(), fechaIdentificacion, false);
        if (idRodeo != null) {
            animalRodeoService.asignar(animal.getIdAnimal(), idRodeo, fechaIdentificacion, false);
        }
        return animal.getIdAnimal();
    }

    /** Agrega la caravana VISUAL a un animal que ya existe (un candidato a torito en la identificación). */
    @Transactional
    public void agregarIdentificacionVisual(Integer idAnimal, String caravana, LocalDate fecha) {
        if (!animales.existsById(idAnimal)) {
            throw new NoEncontradoException("No existe el animal " + idAnimal);
        }
        TipoIdentificacion visual = tipo(CODIGO_VISUAL);
        boolean yaTiene = identificaciones.findByIdAnimalAndFechaBajaIsNull(idAnimal).stream()
                .anyMatch(i -> i.getIdTipoIdent().equals(visual.getIdTipoIdent()));
        if (yaTiene) {
            throw new ReglaDeNegocioException("El animal " + idAnimal + " ya tiene caravana visual.");
        }
        String limpia = caravana.trim();
        exigirCaravanaLibre(CODIGO_VISUAL, limpia);
        guardarIdentificacion(idAnimal, CODIGO_VISUAL, limpia, fecha);
    }

    // ------------------------------------------------------------------

    private static String textoOVacio(String valor) {
        return valor != null && !valor.isBlank() ? valor.trim() : null;
    }

    private void validarPadres(Integer idMadre, Integer idPadre) {
        if (idMadre != null && !animales.existsById(idMadre)) {
            throw new ReglaDeNegocioException("La madre " + idMadre + " no existe.");
        }
        if (idPadre != null && !animales.existsById(idPadre)) {
            throw new ReglaDeNegocioException("El padre " + idPadre + " no existe.");
        }
    }

    private void exigirCaravanaLibre(String codigoTipo, String caravana) {
        Establecimiento estabPropio = establecimientoPropio.obtener();
        if (identificaciones.existsByIdTipoIdentAndIdEstablecimientoAndCaravanaIgnoreCase(
                tipo(codigoTipo).getIdTipoIdent(), estabPropio.getIdEstablecimiento(), caravana)) {
            String que = switch (codigoTipo) {
                case CODIGO_FUEGO -> "la marca a fuego ";
                case CODIGO_ADICIONAL -> "la caravana adicional ";
                default -> "la caravana ";
            };
            throw new ReglaDeNegocioException("Ya existe un animal con " + que + caravana
                    + " en " + estabPropio.getNombre() + ".");
        }
    }

    private void guardarIdentificacion(Integer idAnimal, String codigoTipo, String caravana, LocalDate fechaAlta) {
        Identificacion ident = new Identificacion();
        ident.setIdAnimal(idAnimal);
        ident.setIdTipoIdent(tipo(codigoTipo).getIdTipoIdent());
        ident.setIdEstablecimiento(establecimientoPropio.obtenerId());
        ident.setCaravana(caravana);
        ident.setFechaAlta(fechaAlta);
        ident.setFechaAltaEsEstimada(false);
        identificaciones.save(ident);
    }

    private TipoIdentificacion tipo(String codigo) {
        return tiposIdent.findByCodigo(codigo)
                .orElseThrow(() -> new ReglaDeNegocioException(
                        "Falta el tipo de identificación " + codigo + " en el catálogo."));
    }

    private Categoria categoriaPorCodigo(String codigo) {
        return categorias.findByCodigo(codigo)
                .orElseThrow(() -> new ReglaDeNegocioException("Falta la categoría " + codigo + " en el catálogo."));
    }
}

package com.anpael.planillas.service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.thymeleaf.ITemplateEngine;
import org.thymeleaf.context.Context;

import com.anpael.shared.exception.ReglaDeNegocioException;
import com.anpael.trazabilidad.domain.AnimalLista;
import com.anpael.trazabilidad.domain.Rodeo;
import com.anpael.trazabilidad.service.AnimalService;
import com.anpael.trazabilidad.service.RodeoService;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;

/**
 * Genera el PDF imprimible de un rodeo para un trabajo (v0.2b,
 * docs/etapas.md): "el entregable que mas se va a usar". Filas ordenadas
 * por caravana -ya viene asi de AnimalService.buscarPorRodeo()-, con
 * renglones en blanco al final para los animales que aparecen y no
 * estaban en la lista.
 *
 * Solo se pide por el servicio publico de trazabilidad (AnimalService,
 * RodeoService), nunca por sus repositorios: la regla del monolito
 * modular es que un modulo no importa las clases internas de otro.
 *
 * DESTETE queda afuera a proposito: es caravana de madre + caravana de
 * cria en la misma fila, una forma distinta a las otras cuatro que
 * simplemente listan un animal por fila. Se resuelve aparte.
 */
@Service
public class PlanillaService {

    private static final int FILAS_EN_BLANCO = 8;

    private static final Map<String, List<String>> COLUMNAS = Map.of(
            "TACTO", List.of("Caravana", "Resultado", "Tamaño de preñez", "Observaciones"),
            "PESADA", List.of("Caravana", "Kilos"),
            "REVISION_TOROS", List.of("Caravana", "Marca a fuego", "Circunferencia escrotal",
                    "Condición corporal", "Apto S/N"),
            "SANIDAD", List.of("Caravana", "Producto", "Dosis"));

    private static final Map<String, String> TITULOS = Map.of(
            "TACTO", "Tacto",
            "PESADA", "Pesada",
            "REVISION_TOROS", "Revisión de toros",
            "SANIDAD", "Sanidad");

    private final AnimalService animalService;
    private final RodeoService rodeoService;
    private final ITemplateEngine templateEngine;

    public PlanillaService(AnimalService animalService, RodeoService rodeoService, ITemplateEngine templateEngine) {
        this.animalService = animalService;
        this.rodeoService = rodeoService;
        this.templateEngine = templateEngine;
    }

    public byte[] generar(Integer idRodeo, String tipoTrabajo) {
        List<String> columnas = COLUMNAS.get(tipoTrabajo);
        if (columnas == null) {
            throw new ReglaDeNegocioException(
                    "Todavía no hay planilla para \"" + tipoTrabajo + "\". Los trabajos con planilla son: "
                            + String.join(", ", COLUMNAS.keySet()) + ".");
        }

        Rodeo rodeo = rodeoService.obtener(idRodeo);
        List<AnimalLista> animalesDelRodeo = animalService.buscarPorRodeo(idRodeo);

        List<List<String>> filas = new ArrayList<>();
        for (AnimalLista animal : animalesDelRodeo) {
            List<String> fila = new ArrayList<>();
            fila.add(animal.getCaravana() != null ? animal.getCaravana() : "(sin identificación)");
            for (int i = 1; i < columnas.size(); i++) {
                fila.add("");
            }
            filas.add(fila);
        }
        for (int i = 0; i < FILAS_EN_BLANCO; i++) {
            filas.add(new ArrayList<>(Collections.nCopies(columnas.size(), "")));
        }

        Context contexto = new Context();
        contexto.setVariable("titulo", TITULOS.get(tipoTrabajo) + " · " + rodeo.getNombre());
        contexto.setVariable("fecha", LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")));
        contexto.setVariable("columnas", columnas);
        contexto.setVariable("filas", filas);

        String html = templateEngine.process("planillas/planilla", contexto);

        ByteArrayOutputStream salida = new ByteArrayOutputStream();
        PdfRendererBuilder builder = new PdfRendererBuilder();
        builder.useFastMode();
        builder.withHtmlContent(html, null);
        builder.toStream(salida);
        try {
            builder.run();
        } catch (IOException e) {
            throw new RuntimeException("No se pudo generar el PDF de la planilla", e);
        }
        return salida.toByteArray();
    }
}

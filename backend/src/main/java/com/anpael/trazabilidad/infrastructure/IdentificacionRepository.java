package com.anpael.trazabilidad.infrastructure;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Identificacion;

public interface IdentificacionRepository extends JpaRepository<Identificacion, Integer> {

    boolean existsByIdTipoIdentAndIdEstablecimientoAndCaravanaIgnoreCase(Integer idTipoIdent, Integer idEstablecimiento,
            String caravana);

    /** Las identificaciones vigentes de un animal (v_animal_lista las junta igual: fecha_baja is null). */
    List<Identificacion> findByIdAnimalAndFechaBajaIsNull(Integer idAnimal);
}

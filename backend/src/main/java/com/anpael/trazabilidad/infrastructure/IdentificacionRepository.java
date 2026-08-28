package com.anpael.trazabilidad.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.trazabilidad.domain.Identificacion;

public interface IdentificacionRepository extends JpaRepository<Identificacion, Integer> {

    boolean existsByIdTipoIdentAndIdEstablecimientoAndCaravanaIgnoreCase(Integer idTipoIdent, Integer idEstablecimiento,
            String caravana);
}
